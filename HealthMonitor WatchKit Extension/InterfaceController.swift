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
        self.heartRate.setTextColor(UIColor(red: 255, green:0, blue: 0, alpha: 1))
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
    
    // Create our Heart Rate Query
    func heartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        guard let heartRateSample = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil
        }
        
        let heartRateQuery = HKAnchoredObjectQuery(type:heartRateSample, predicate: nil, anchor: anchor, limit:
        Int(HKObjectQueryNoLimit)) { (query, sampleObjects,
            deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            guard let heartRateSamples = samples as? [HKQuantitySample] else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                guard let sample = heartRateSamples.first else {
                    return
                }
                let value = sample.quantity.doubleValueForUnit(HKUnit(fromString:"count/min"))
                self.heartRate.setText(String(UInt16(value)))
            }
            self.heartRate.setTextColor(UIColor(red: 255, green:0, blue: 0, alpha: 1))
        }
        return heartRateQuery
    }
    
    // Query the HealthKit store to return the total number of
    // steps attempted for a given day
    func dailyStepsStreamingQuery(workoutStartDate: NSDate) -> HKQuery?
    {
        // Call our Sample type for our HealthKit class to return
        guard let dailyStepsSample = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else {
            return nil
        }
        let calendar = NSCalendar.currentCalendar()
        let startDate = calendar.dateByAddingUnit(NSCalendarUnit.Day,value: -1, toDate: workoutStartDate, options:NSCalendarOptions.WrapComponents)
        
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: workoutStartDate, options: HKQueryOptions.StrictEndDate)
        let dailyStepsQuery = HKSampleQuery(sampleType: dailyStepsSample,
                                            predicate: predicate, limit: 0, sortDescriptors: nil) {
                                                [unowned self] (query, results, error) in
                                                guard let dailyStepsSamples = results as?
                                                    [HKQuantitySample] else {
                                                        return
                                                }
                                                guard dailyStepsSamples.count > 0 else {
                                                    return
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue()) {
                                                    var dailySteps : Double = 0
                                                    for steps in dailyStepsSamples {
                                                        dailySteps +=
                                                            steps.quantity.doubleValueForUnit(HKUnit.countUnit())
                                                    }
                                                    self.stepCount.setText(String(UInt16(dailySteps)))
                                                    self.stepCount.setTextColor(UIColor.greenColor())
                                                }
        }
        
        // Return our Query string back to the calling method
        return dailyStepsQuery
    }
    
    // Start a workout
    func didSessionStart(date : NSDate) {
        
        // Start a Step Counter WorkOut
        if let dailyStepsQuery = dailyStepsStreamingQuery(date) {
            healthKitStore.executeQuery(dailyStepsQuery)
        }
        
        // Start a Heart Rate WorkOut
        if let heartRateQuery = heartRateStreamingQuery(date) {
            healthKitStore.executeQuery(heartRateQuery)
        }
    }
    
    func didSessionEnd(date : NSDate) {
        
        // Stop Heart Rate Query from Running
        if let heartRateQuery = heartRateStreamingQuery(date) {
            healthKitStore.stopQuery(heartRateQuery)
            self.heartRate.setText("---")
        }
        if let dailyStepsQuery = dailyStepsStreamingQuery(date) {
            healthKitStore.stopQuery(dailyStepsQuery)
            self.stepCount.setText("---")
        }
    }
    
    @IBAction func startStopButtonPressed() {
        if (self.isSessionActive)
        {
            // Finish the current session
            self.isSessionActive = false
            self.startStopButton.setTitle("Start Monitoring")
            self.didSessionEnd(NSDate())
        } else {
            // Start a new session
            self.isSessionActive = true
            self.startStopButton.setTitle("Stop Monitoring")
            self.didSessionStart(NSDate())
        }
    }
}
