import Foundation

private extension URL {
    var isRoot: Bool {
        // Make sure the URL is a file URL
        guard isFileURL else {
            return false
        }

        // Resolve symbolic links to get the real path
        let standardizedURL = standardizedFileURL

        // Check if the path is "/"
        return standardizedURL.path == "/"
    }
}

/// Helper for loading environment variables from .env file for integration tests
enum Environment {
    private static let envFilePath: URL? = {
        let fileManager = FileManager.default
        let currentPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

        var searchPath = currentPath

        // Search parent directories including root
        while true {
            let envPath = searchPath.appendingPathComponent(".env")

            if fileManager.fileExists(atPath: envPath.path) {
                return envPath
            }

            // Check if we've reached the root
            if searchPath.isRoot {
                return nil
            }

            searchPath = searchPath.deletingLastPathComponent()
        }
    }()

    private static var loadedVars: [String: String] = {
        var output: [String: String] = [:]

        guard let envPath = envFilePath else {
            return output
        }

        guard let contents = try? String(contentsOf: envPath, encoding: .utf8) else {
            return output
        }

        let lines = contents.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse KEY=VALUE
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                output[key] = value
            }
        }

        return output
    }()

    static func get(_ key: String) -> String? {
        self.loadedVars[key] ?? ProcessInfo.processInfo.environment[key]
    }

    /// Set an environment variable and persist it to the .env file
    /// - Parameters:
    ///   - key: The environment variable key
    ///   - value: The value to set
    /// - Throws: Error if writing to .env file fails
    static func set(_ key: String, value: String) throws {
        // Update in-memory cache
        loadedVars[key] = value

        // Get or create .env file path
        guard let envPath = envFilePath else {
            throw EnvironmentError.cannotFindEnvFile
        }

        // Read existing content
        var lines: [String] = []
        if let contents = try? String(contentsOf: envPath, encoding: .utf8) {
            lines = contents.components(separatedBy: .newlines)
        }

        // Update or add the key-value pair
        var found = false
        for i in 0 ..< lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Check if this line has our key
            if let equalsIndex = trimmed.firstIndex(of: "=") {
                let lineKey = String(trimmed[..<equalsIndex]).trimmingCharacters(in: .whitespaces)
                if lineKey == key {
                    lines[i] = "\(key)=\(value)"
                    found = true
                    break
                }
            }
        }

        // If key wasn't found, append it
        if !found {
            lines.append("\(key)=\(value)")
        }

        // Write back to file
        let newContents = lines.joined(separator: "\n")
        try newContents.write(to: envPath, atomically: true, encoding: .utf8)
    }
}

enum EnvironmentError: Error {
    case cannotFindEnvFile
}
