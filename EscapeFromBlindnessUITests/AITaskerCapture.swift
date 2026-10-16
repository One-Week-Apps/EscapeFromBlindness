//
//  Created by Michael Martinez on 16/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

enum AITaskerCapture {

    /// Joint une capture de l'écran au test en cours, nommée `nodeId` et conservée même si le test réussit.
    static func captureScreen(nodeId: String, action: String) {
        XCTContext.runActivity(named: action) { activity in
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = nodeId
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

}
