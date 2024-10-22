import Foundation

extension String {
    public func toMatrixUserIdFormat(_ homeServerPostFix: String) -> String? {
        if stringMatchesUserIdFormatRegex() {
            return "@\(self):\(homeServerPostFix)"
        } else {
            // print("Not a proper matrix user-id format")
            return nil
        }
    }
    
    func stringMatchesUserIdFormatRegex() -> Bool {
        let regex = #"^[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+$"#
        let isMatch = range(of: regex, options: .regularExpression) != nil
        return isMatch
    }
    
    public func matrixIdToCleanHex() -> String {
        if self.contains("@"), self.contains(":") {
            let startIndex = self.firstIndex(of: "@")!
            let endIndex = self.firstIndex(of: ":")!
            return self
                .substring(to: endIndex)
                .substring(from: self.index(after: startIndex))
        } else {
            return self
        }
    }
}
