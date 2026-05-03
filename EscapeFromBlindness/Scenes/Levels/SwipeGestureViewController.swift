//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit

class SwipeGestureViewController: LevelBaseViewController {
    private var level: SwipeGestureLevel!

    convenience init(level: SwipeGestureLevel) {
        self.init()
        self.level = level
    }
}
