//
//  UIBatteryMonitor.swift
//  logistics
//
//  Created by Sahil Kapoor on 19/06/15.
//  Copyright (c) 2015 ShaleApps. All rights reserved.
//

import UIKit

@objc enum UIBatteryLevel: Int {
    case Unknown
    case CriticallyLow
    case Low
    case Normal
    case Full
}

@objc protocol UIBatteryMonitorDelegate {
    optional func significantBatteryLevelChange(level: UIBatteryLevel)
    
    optional func currentBatteryStateChanged(state: UIDeviceBatteryState)
    
    optional func currentBatteryPercentageChanged(percentage: Int)
    
    optional func currentBatteryStatusChanged(state: UIDeviceBatteryState,_ percentage: Int)

    //Called if battery value reaches the percentages set in notifyForBatteryLevel and notifyForBatteryLevels.
    optional func batteryPercentageReachedUserSetLevel(batteryPercentage: Int)
}

class UIBatteryMonitor: NSObject {
    // Don't use sharedInstance if using delegate funcitons at multiple places.
    static let sharedInstance = UIBatteryMonitor()
    var reportLevelOnCharging = false
    var delegate: UIBatteryMonitorDelegate?
    
    // Private vars
    private let device = UIDevice.currentDevice()
    
    private let kBatteryCriticallyLowLevel = 10
    private let kBatteryLowLevel = 20
    
    private var notifyPercentages = [Int]()
    private var isMonitoring = false
    private var batteryLevel = UIBatteryLevel.Unknown
    
    deinit {
        stopMonitoring()
    }
}

// MARK:- Public Methods

extension UIBatteryMonitor {
    func startMonitoring() {
        if isMonitoring == false {
            activateMonitoring(true)
            registerForBatteryNotifications()
        }
    }
    
    func stopMonitoring() {
        if isMonitoring {
            activateMonitoring(false)
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    func notifyForBatteryLevel(percentage: Int) {
        notifyForBatteryLevels([percentage])
    }

    func notifyForBatteryLevels(percentages: [Int]) {
        notifyPercentages = percentages
    }
    
    func isPlugged() -> Bool {
        if isMonitoring {
            return device.batteryState == .Unplugged
        } else {
            activateMonitoring(true)
            let bool = device.batteryState == .Unplugged
            activateMonitoring(false)
            
            return bool
        }
    }

    func isFullyCharged() -> Bool {
        if isMonitoring {
            return device.batteryState == .Full
        } else {
            activateMonitoring(true)
            let bool = device.batteryState == .Full
            activateMonitoring(false)
            
            return bool
        }
    }
    
    func currentBatteryLevel() -> UIBatteryLevel {
        if isMonitoring {
            return calculateBatteryLevelFromPercentage()
        } else {
            activateMonitoring(true)
            let level = calculateBatteryLevelFromPercentage()
            activateMonitoring(false)
            
            return level
        }
    }
    
    func currentBatteryPercentage() -> Int {
        if isMonitoring {
            return batteryPercentage()
        } else {
            activateMonitoring(true)
            let percentage = batteryPercentage()
            activateMonitoring(false)
            
            return percentage
        }
    }
    
    func batteryState() -> UIDeviceBatteryState {
        if isMonitoring {
            return device.batteryState
        } else {
            activateMonitoring(true)
            let state = device.batteryState
            activateMonitoring(false)
            
            return state
        }
    }
}

// MARK:- Notification Handler

extension UIBatteryMonitor {
    func batteryLevelChanged() {
        let level = calculateBatteryLevelFromPercentage()
        let percentage = batteryPercentage()
        let state = device.batteryState
        
        if reportLevelOnCharging == false {
            if device.batteryState != .Unknown {
                return
            }
        }
        
        delegate?.currentBatteryPercentageChanged?(percentage)
        delegate?.currentBatteryStateChanged?(state)
        delegate?.currentBatteryStatusChanged?(state, percentage)
        
        if state != .Charging && batteryLevel != level {
            delegate?.significantBatteryLevelChange?(level)
        }
        
        for notifyPercentage in notifyPercentages {
            if percentage == notifyPercentage {
                delegate?.batteryPercentageReachedUserSetLevel?(percentage)
                break
            }
        }
    }
}

// MARK:- Private Methods

extension UIBatteryMonitor {
    private func batteryPercentage() -> Int {
        return Int(device.batteryLevel * 100)
    }
    
    private func activateMonitoring(activate: Bool) {
        device.batteryMonitoringEnabled = activate
        isMonitoring = activate
    }
    
    private func registerForBatteryNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("batteryLevelChanged"), name: UIDeviceBatteryLevelDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("batteryStateChanged"), name: UIDeviceBatteryStateDidChangeNotification, object: nil)
    }
    
    private func calculateBatteryLevelFromPercentage() -> UIBatteryLevel {
        let percentage = batteryPercentage()
        if percentage < kBatteryCriticallyLowLevel {
            return .CriticallyLow
        } else if percentage < kBatteryLowLevel {
            return .Low;
        } else if percentage < 100 {
            return .Normal;
        } else if percentage ==  100 {
            return .Full;
        } else {
            return .Unknown;
        }
    }
}
