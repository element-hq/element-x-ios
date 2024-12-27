import Foundation

public extension String {
    func toMatrixUserIdFormat(_ homeServerPostFix: String) -> String? {
        if stringMatchesUserIdFormatRegex() {
            return "@\(self):\(homeServerPostFix)"
        } else {
            // print("Not a proper matrix user-id format")
            return nil
        }
    }
    
    internal func stringMatchesUserIdFormatRegex() -> Bool {
        let regex = #"^[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+$"#
        let isMatch = range(of: regex, options: .regularExpression) != nil
        return isMatch
    }
    
    func matrixIdToCleanHex() -> String {
        if contains("@"), contains(":") {
            let startIndex = firstIndex(of: "@")!
            let endIndex = firstIndex(of: ":")!
            return substring(to: endIndex)
                .substring(from: index(after: startIndex))
        } else {
            return self
        }
    }
    
    /// Conveniently create a substring to more easily match JavaScript APIs
    ///
    /// - Parameters:
    ///   - offset: Starting index fo substring
    ///   - length: Length of desired substring
    /// - Returns: String representing the substring if passed indexes are in bounds
    func substr(_ offset: Int, _ length: Int) -> String? {
        guard offset + length <= count else { return nil }
        let start = index(startIndex, offsetBy: offset)
        let end = index(start, offsetBy: length)
        return String(self[start..<end])
    }
}
