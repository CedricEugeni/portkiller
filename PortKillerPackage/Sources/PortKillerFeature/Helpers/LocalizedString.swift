import Foundation

extension String {
    /// Localized string using the module's bundle
    init(moduleLocalized key: String.LocalizationValue) {
        self.init(localized: key, bundle: .module)
    }
}
