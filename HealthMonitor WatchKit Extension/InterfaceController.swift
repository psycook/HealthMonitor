//
//  InterfaceController.swift
//  HealthMonitor WatchKit Extension
//
//  Created by Simon Cook on 18/07/2016.
//  Copyright © 2016 Simon Cook. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController {

    @IBOutlet var heartRate: WKInterfaceLabel!
    @IBOutlet var stepCount: WKInterfaceLabel!
    @IBOutlet var startStopButton: WKInterfaceButton!
    
    var isSessionActive = false
    let healthKitStore = HKHealthStore()
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.heartRate.setText("---")
        self.heartRate.setTextColor(UIColor(red: 255, green:0,
            blue: 0, alpha: 1))
        self.stepCount.setText("---")
        self.stepCount.setTextColor(UIColor.greenColor())
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        guard HKHealthStore.isHealthDataAvailable() == true else {
            self.showDialog("HealthKit",
                            message: "HealthKit not supported", buttonText: "OK")
            return
        }
        // Specify our HealthKit object types to read
        let healthKitTypesToRead = NSSet(
            objects: HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
            HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!) as! Set<HKObjectType>
        
        healthKitStore.requestAuthorizationToShareTypes(nil,
                                                        readTypes: healthKitTypesToRead) {
                                                            (success, error) -> Void in
                                                            if success == false {
                                                                self.showDialog("HealthKit", message: "HealthKit is not allowed", buttonText: "OK")
                                                            }
        }
    }
    
    // method to display a popup dialog if HealthKit is unavailable
    func showDialog(title: String, message: String, buttonText: String)-> Void
    {
        let buttonAction = WKAlertAction(title: buttonText,
                                         style: WKAlertActionStyle.Cancel) { () -> Void in
        }
        presentAlertControllerWithTitle(title, message: message,
                                        preferredStyle: .ActionSheet, actions: [buttonAction])
        return
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func startStopButtonPressed() {
    }
    

    
}
