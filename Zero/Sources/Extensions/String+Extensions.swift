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
}
