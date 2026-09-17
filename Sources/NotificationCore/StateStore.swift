import Foundation

public struct StateStore {
    public let url: URL
    public init(url: URL) { self.url = url }

    public func load() throws -> InboxState {
        guard FileManager.default.fileExists(atPath: url.path) else { return InboxState() }
        // Corrupt data must be surfaced, never silently replaced with an empty inbox.
        return try JSONDecoder().decode(InboxState.self, from: Data(contentsOf: url))
    }

    public func save(_ state: InboxState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                                              attributes: [.posixPermissions: 0o700])
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
