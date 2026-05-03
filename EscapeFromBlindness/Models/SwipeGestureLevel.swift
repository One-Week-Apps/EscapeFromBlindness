//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation

enum SwipeDirection: Equatable {
    case vertical
    case horizontal
}

class SwipeGestureLevel: Level {
    let instruction: String
    let swipeDirections: [SwipeDirection]
    // pages[i] = sections verticales du parchemin i
    // count == 1 si uniquement .vertical ; count > 1 si .horizontal inclus
    let pages: [[String]]
    let validAnswer: String

    init(
        instruction: String,
        swipeDirections: [SwipeDirection],
        pages: [[String]],
        validAnswer: String,
        hints: [String] = []
    ) {
        self.instruction = instruction
        self.swipeDirections = swipeDirections
        self.pages = pages
        self.validAnswer = validAnswer
        super.init(answers: [], validAnswers: [validAnswer], hints: hints)
    }
}
