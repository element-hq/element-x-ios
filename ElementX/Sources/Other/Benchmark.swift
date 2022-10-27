//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

struct Benchmark {
    private static var trackingIdentifiers = [String: CFAbsoluteTime]()
    
    public static var trackingEnabled = false
    
    static func startTrackingForIdentifier(_ identifier: String, message: String? = nil) {
        guard trackingEnabled else {
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        trackingIdentifiers[identifier] = startTime
        
        if let message {
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
        if let message {
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
