//
//  Created by Michael Martinez on 19/03/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import Foundation

/// A code made of distinct digits, leading zero included ("0385", not "385").
func randomCode(length: Int) -> String {
    return (0...9).shuffled().prefix(length).map(String.init).joined()
}

/// `count` codes different from each other and from `excluded`.
func randomCodes(_ count: Int, length: Int, excluding excluded: String) -> [String] {
    var codes: Set<String> = []
    while codes.count < count {
        let code = randomCode(length: length)
        if code != excluded {
            codes.insert(code)
        }
    }
    return Array(codes)
}
