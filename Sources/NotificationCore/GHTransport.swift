import Foundation

public struct GHTransport: GitHubTransport {
    public init() {}

    public func get(_ path: String) async throws -> APIResponse {
        guard path.hasPrefix("/"), !path.hasPrefix("//"), !path.contains("\n"), !path.contains("\r") else {
            throw SignalError.message("APIの参照先が不正")
        }
        return try await Task.detached(priority: .utility) {
            let candidates = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh"]
            guard let binary = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                throw SignalError.message("GitHub CLIが必要。ターミナルで brew install gh を実行する")
            }
            let attributes = try FileManager.default.attributesOfItem(atPath: URL(fileURLWithPath: binary).resolvingSymlinksInPath().path)
            if let mode = attributes[.posixPermissions] as? NSNumber, mode.intValue & 0o022 != 0 {
                throw SignalError.message("GitHub CLIが他のユーザーから書き換え可能になっている")
            }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary)
            process.arguments = ["api", "--hostname", "github.com", "--method", "GET", "--include",
                                 "-H", "Accept: application/vnd.github+json", "-H", "X-GitHub-Api-Version: 2022-11-28", path]
            process.environment = [
                "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin",
                "GH_HOST": "github.com", "GH_PROMPT_DISABLED": "1", "GH_PAGER": "cat", "NO_COLOR": "1"
            ]
            process.standardInput = FileHandle.nullDevice
            let pipe = Pipe()
            process.standardOutput = pipe
            // Do not mix diagnostics into JSON/HTTP headers or retain potentially sensitive errors.
            process.standardError = FileHandle.nullDevice
            try process.run()
            let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 30, execute: timeout)
            let forceStop = DispatchWorkItem { if process.isRunning { kill(process.processIdentifier, SIGKILL) } }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 32, execute: forceStop)
            defer { timeout.cancel(); forceStop.cancel() }
            var output = Data()
            while true {
                let chunk = pipe.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                output.append(chunk)
                if output.count > 32 * 1_024 * 1_024 {
                    kill(process.processIdentifier, SIGKILL)
                    process.waitUntilExit()
                    throw SignalError.message("GitHubの応答が大きすぎるため中断した")
                }
            }
            process.waitUntilExit()
            if process.terminationReason == .uncaughtSignal {
                throw SignalError.message("GitHubとの通信がタイムアウトした。次回の同期で再試行する")
            }
            return try Self.parse(output, exitCode: process.terminationStatus)
        }.value
    }

    public static func parse(_ data: Data, exitCode: Int32) throws -> APIResponse {
        guard let text = String(data: data, encoding: .utf8) else { throw SignalError.message("GitHubの応答を読み取れない") }
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard let boundary = normalized.range(of: "\n\n") else {
            throw SignalError.message("GitHubに接続できない。ターミナルで gh auth status --hostname github.com を確認する")
        }
        let lines = normalized[..<boundary.lowerBound].split(separator: "\n")
        let status = lines.first?.split(separator: " ").dropFirst().first.flatMap { Int($0) } ?? 0
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            headers[String(line[..<colon]).lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        guard exitCode == 0, (200..<300).contains(status) else {
            switch status {
            case 401: throw SignalError.message("GitHubの認証が切れている。gh auth login --hostname github.com で再認証する")
            case 403, 429: throw SignalError.message("GitHubの権限不足またはAPI利用制限。ghの認証権限・SSOを確認する。5分後に再試行する")
            case 404: throw SignalError.message("対象が削除されたか、読み取り権限がない")
            default: throw SignalError.message("GitHubとの通信に失敗した（HTTP \(status)）。次回の同期で再試行する")
            }
        }
        let body = Data(normalized[boundary.upperBound...].utf8)
        guard headers["content-type"]?.contains("json") == true else { throw SignalError.message("GitHubからJSON以外の応答が返された") }
        return APIResponse(data: body, headers: headers)
    }
}
