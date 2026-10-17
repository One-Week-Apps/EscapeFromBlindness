//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import Foundation

/// Version de l'app telle qu'affichée à l'utilisateur, par exemple « Version 1.4.2 (87) ».
struct AppVersion: Equatable {
    static let marketingKey = "CFBundleShortVersionString"
    static let buildKey = "CFBundleVersion"

    let marketing: String
    let build: String?

    init(marketing: String, build: String?) {
        self.marketing = marketing
        // Un build identique à la version n'apporte rien : on ne l'affiche pas.
        self.build = build == marketing ? nil : build
    }

    /// Affiché quand `CFBundleShortVersionString` est introuvable.
    static var fallbackText: String {
        return "\(L10n.appVersion) –"
    }

    /// `nil` quand `CFBundleShortVersionString` est absent ou vide.
    static func from(infoDictionary: [String: Any]?) -> AppVersion? {
        guard let marketing = value(for: marketingKey, in: infoDictionary) else { return nil }
        return AppVersion(marketing: marketing, build: value(for: buildKey, in: infoDictionary))
    }

    /// Clés de version absentes ou vides dans l'Info.plist, à journaliser.
    static func missingKeys(in infoDictionary: [String: Any]?) -> [String] {
        return [marketingKey, buildKey].filter { value(for: $0, in: infoDictionary) == nil }
    }

    var displayText: String {
        guard let build = build else { return "\(L10n.appVersion) \(marketing)" }
        return "\(L10n.appVersion) \(marketing) (\(build))"
    }

    /// Lu par VoiceOver « Version 1.4.2, build 87 » plutôt que « 1.4.2 parenthèse 87 ».
    var accessibilityText: String {
        guard let build = build else { return "\(L10n.appVersion) \(marketing)" }
        return "\(L10n.appVersion) \(marketing), \(L10n.appVersionBuild) \(build)"
    }

    private static func value(for key: String, in infoDictionary: [String: Any]?) -> String? {
        guard let value = (infoDictionary?[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }
}
