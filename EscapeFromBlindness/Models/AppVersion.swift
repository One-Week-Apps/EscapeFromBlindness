//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import Foundation

/// Version de l'app telle qu'affichée à l'utilisateur, par exemple « Version 1.4.2 (87) ».
struct AppVersion: Equatable {
    let version: String
    let build: String?

    var displayText: String {
        guard let build = build else { return "\(L10n.appVersion) \(version)" }
        return "\(L10n.appVersion) \(version) (\(build))"
    }

    /// Lu par VoiceOver « Version 1.4.2, build 87 » plutôt que « 1.4.2 parenthèse 87 ».
    var accessibilityText: String {
        guard let build = build else { return "\(L10n.appVersion) \(version)" }
        return "\(L10n.appVersion) \(version), \(L10n.appVersionBuild) \(build)"
    }
}

protocol AppVersionProviding {
    /// `nil` quand `CFBundleShortVersionString` est absent ou vide.
    var appVersion: AppVersion? { get }
}

struct BundleAppVersionProvider: AppVersionProviding {
    static let versionKey = "CFBundleShortVersionString"
    static let buildKey = "CFBundleVersion"

    private let infoDictionary: [String: Any]?

    init(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) {
        self.infoDictionary = infoDictionary
    }

    var appVersion: AppVersion? {
        guard let version = value(for: BundleAppVersionProvider.versionKey) else { return nil }
        return AppVersion(version: version, build: value(for: BundleAppVersionProvider.buildKey))
    }

    private func value(for key: String) -> String? {
        guard let value = (infoDictionary?[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }
}
