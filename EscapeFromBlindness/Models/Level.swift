//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation

class Level: CustomStringConvertible {
    typealias Answer = String
    public let answers: [Answer]
    public let validAnswers: [Answer]
    var hints: [String]
    
    init(answers: [Answer], validAnswers: [Answer], hints: [String] = []) {
        self.answers = answers
        self.validAnswers = validAnswers
        self.hints = hints
    }
    
    func isSolved(by answers: [Answer]) -> Bool {
        return self.validAnswers == answers
    }

    var description: String {
        return "\(String(describing: self)) Level"
    }
}
