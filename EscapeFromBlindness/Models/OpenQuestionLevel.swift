//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation
import os

class OpenQuestionLevel: Level {
    typealias Question = String
    var question: Question

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReponseOuverte")

    init(question: Question, validAnswers: [Answer], hints: [String] = []) {
        self.question = question
        super.init(answers: [], validAnswers: validAnswers, hints: hints)
    }

    /// Spaces or new lines typed by mistake before or after an open answer do not make it wrong.
    /// Case, accents and inner spaces are still compared as they are.
    override func isSolved(by answers: [Answer]) -> Bool {
        let isSolved = super.isSolved(by: answers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        logger.debug("Open answer \(answers, privacy: .private) \(isSolved ? "accepted" : "refused", privacy: .public)")
        return isSolved
    }
}
