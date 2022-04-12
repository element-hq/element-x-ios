//
//  Benchmark.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct Benchmark {
    static private var trackingIdentifiers = [String: CFAbsoluteTime]()
    
    static public var trackingEnabled = false
    
    static func startTrackingForIdentifier(_ identifier: String, message: String? = nil) {
        guard trackingEnabled else {
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        trackingIdentifiers[identifier] = startTime
        
        if let message = message {
            MXLog.verbose("⏰ \(message).")
        }
    }
    
    static func logElapsedDurationForIdentifier(_ identifier: String, message: String? = nil) {
        guard trackingEnabled else {
            return
        }
        
        guard let start = trackingIdentifiers[identifier] else {
            assertionFailure("⏰ Invalid tracking identifier")
            return
        }
        
        let elapsedTime = CFAbsoluteTimeGetCurrent() - start
        if let message = message {
            MXLog.verbose("⏰ \(message). Elapsed time: \(elapsedTime.round(to: 4)) seconds.")
        } else {
            MXLog.verbose("⏰ Elapsed time: \(elapsedTime.round(to: 4)) seconds.")
        }
    }
    
    static func endTrackingForIdentifier(_ identifier: String, message: String? = nil) {
        guard trackingEnabled else {
            return
        }
        
        logElapsedDurationForIdentifier(identifier, message: message)
        trackingIdentifiers[identifier] = nil
    }
}

private extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
