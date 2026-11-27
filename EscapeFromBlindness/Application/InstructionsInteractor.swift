//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation

protocol InstructionsInteractorProtocol {
    func fetchIntroInstructions() -> [String]
    func fetchGameEndTitle() -> String
    func fetchGameEndInstructions() -> [String]
    /// Délai entre deux consignes qui défilent.
    var instructionInterval: TimeInterval { get }
    /// Duration of each half of the fade between two instructions.
    var transitionDuration: TimeInterval { get }
}

class InstructionsInteractor: InstructionsInteractorProtocol {

    static let productionInstructionInterval: TimeInterval = 5.0
    /// Tests UI : quelques millisecondes entre deux consignes, au lieu d'attendre le défilement complet.
    static let uiTestInstructionInterval: TimeInterval = 0.05

    private let supportUrl = "one-week-apps.com"
    let instructionInterval: TimeInterval

    /// Half a second at the production cadence; never more than a quarter of the cadence,
    /// so that a fade always ends before the next instruction starts and they show up in order.
    var transitionDuration: TimeInterval {
        min(InstructionsInteractor.productionTransitionDuration, instructionInterval / 4)
    }
    private static let productionTransitionDuration: TimeInterval = 0.5

    init(instructionInterval: TimeInterval = InstructionsInteractor.launchInstructionInterval) {
        self.instructionInterval = instructionInterval
    }

    /// Cadence par défaut : réduite uniquement sous `-UITestGameEnd`, en build DEBUG.
    private static var launchInstructionInterval: TimeInterval {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestGameEnd") {
            return uiTestInstructionInterval
        }
        #endif
        return productionInstructionInterval
    }

    func fetchIntroInstructions() -> [String] {
        return [
            L10n._1,
            L10n._2,
            L10n._3,
            L10n._4,
            L10n._5,
            L10n._6,
            L10n._7,
            L10n._8
        ]
    }
    
    /// Le titre de fin de jeu ; les consignes qui défilent ensuite commencent à la suivante.
    func fetchGameEndTitle() -> String {
        return L10n.a
    }

    func fetchGameEndInstructions() -> [String] {
        return [
            L10n.b,
            L10n.c,
            L10n.d,
            L10n.e + "\(supportUrl)",
            L10n.f
        ]
    }
    
}
