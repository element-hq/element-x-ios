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
}
