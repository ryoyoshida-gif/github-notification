import Foundation

/// A display-only excerpt. The stored source remains available in the detail view.
public enum SignalPreview {
    public static func text(_ source: String) -> String {
        var text = source
        let replacements: [(String, String)] = [
            (#"<!--[\s\S]*?(?:-->|$)"#, ""),
            (#"(?m)^\s*\[[^\]\n]+\]:[^\n]*"#, ""),
            (#"!\[([^\]]*)\]\([^\n)]*\)"#, "$1"),
            (#"\[([^\]]+)\]\([^\n)]*\)"#, "$1"),
            (#"</?[A-Za-z][^>]*(?:>|$)"#, ""),
            (#"(?m)^\s{0,3}#{1,6}\s+"#, ""),
            (#"(?m)^\s*\|?[\s:|\-]+\|\s*$"#, ""),
            (#"(?m)^\s*```[^\n]*"#, ""),
            (#"\*\*|__|`"#, ""),
            (#"(?m)^[ \t]*\|[ \t]*|[ \t]*\|[ \t]*$"#, ""),
            (#"[ \t]*\|[ \t]*"#, " · ")
        ]
        for (pattern, replacement) in replacements {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        text = text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
