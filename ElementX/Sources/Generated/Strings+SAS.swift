import Foundation

enum SASL10n {
    /// The description of the emoji with this index in the spec's SAS emoji table, or `nil` if there isn't one.
    static func localizedDescription(for index: Int) -> String? {
        tr("SAS", String(index))
    }
    
    private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String? {
        // Use preferredLocalizations to get a language that is in the bundle and the user's preferred list of languages.
        let languages = Bundle.overrideLocalizations ?? Bundle.app.preferredLocalizations
        
        for language in languages {
            if let translation = trIn(language, table, key, args) {
                return translation
            }
        }
        return Bundle.app.developmentLocalization.flatMap { trIn($0, table, key, args) }
    }
    
    private static func trIn(_ language: String, _ table: String, _ key: String, _ args: CVarArg...) -> String? {
        guard let bundle = Bundle.lprojBundle(for: language) else { return nil }
        let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
        let translation = String(format: format, locale: Locale(identifier: language), arguments: args)
        // Handle double pseudo for tests
        guard translation != key, translation != "\(key) \(key)" else { return nil }
        return translation
    }
}
