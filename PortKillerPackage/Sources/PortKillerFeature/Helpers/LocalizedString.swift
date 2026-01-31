import Foundation

extension String {
    /// Returns a localized string from the module bundle using system preferred language
    static func moduleLocalized(_ key: String) -> String {
        // Get preferred language (e.g., "fr-FR", "en-US")
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        // Extract base language (e.g., "fr" from "fr-FR")
        let languageCode = String(preferredLanguage.prefix(2))
        
        // Try to find the localized string in the preferred language
        if let bundlePath = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
            // If we got a translation (not the key itself), return it
            if localizedString != key {
                return localizedString
            }
        }
        
        // Fallback to default bundle localization
        return Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }
}
