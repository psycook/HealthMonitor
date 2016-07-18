//
//  ProfileInterfaceController.swift
//  HealthMonitor
//
//  Created by Simon Cook on 18/07/2016.
//  Copyright © 2016 Simon Cook. All rights reserved.
//

import WatchKit
import Foundation


class ProfileInterfaceController: WKInterfaceController {

    @IBOutlet var profileDoB: WKInterfaceLabel!
    @IBOutlet var profileAge: WKInterfaceLabel!
    @IBOutlet var profileSex: WKInterfaceLabel!
    @IBOutlet var profileBloodType: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
