//
//  AITaskerCapture.swift
//  Fourni et tenu à jour par One Week Apps Runner : ne pas modifier, il sera remplacé.
//

import XCTest

enum AITaskerCapture {

    /// Joint une capture de l'écran au test en cours, nommée `nodeId` et conservée même si le test réussit,
    /// avec l'ordre de lecture VoiceOver de l'écran (pièce jointe `<nodeId>-voiceover`).
    /// Appelable depuis n'importe quel test : les tests UI tournent sur le thread principal.
    static func captureScreen(nodeId: String, action: String) {
        MainActor.assumeIsolated { capture(nodeId: nodeId, action: action) }
    }

    @MainActor
    private static func capture(nodeId: String, action: String) {
        let app = XCUIApplication()
        XCTContext.runActivity(named: action) { activity in
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = nodeId
            attachment.lifetime = .keepAlways
            activity.add(attachment)

            let reading = XCTAttachment(string: voiceOverOrder(of: app).joined(separator: "\n"))
            reading.name = "\(nodeId)-voiceover"
            reading.lifetime = .keepAlways
            activity.add(reading)
        }
    }

    private static let roles: [XCUIElement.ElementType: String] = [
        .staticText: "", .button: "bouton", .link: "lien", .image: "image", .switch: "interrupteur",
        .slider: "réglable", .textField: "champ de texte", .secureTextField: "champ sécurisé",
        .searchField: "recherche", .tab: "onglet", .segmentedControl: "sélecteur",
    ]

    /// L'ordre de VoiceOver, approché comme l'Accessibility Inspector : chaque élément lu, de haut en bas puis de gauche à droite.
    @MainActor
    static func voiceOverOrder(of app: XCUIApplication) -> [String] {
        guard let root = try? app.snapshot() else { return [] }
        var read: [(frame: CGRect, text: String)] = []
        func visit(_ node: XCUIElementSnapshot) {
            let label = node.label.trimmingCharacters(in: .whitespacesAndNewlines)
            if let role = roles[node.elementType], !label.isEmpty, !node.frame.isEmpty, node.frame.intersects(root.frame) {
                read.append((node.frame, role.isEmpty ? label : "\(label), \(role)"))
                return
            }
            node.children.forEach(visit)
        }
        visit(root)
        return read
            .sorted { abs($0.frame.minY - $1.frame.minY) > 8 ? $0.frame.minY < $1.frame.minY : $0.frame.minX < $1.frame.minX }
            .map(\.text)
    }
}
