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
import XCTest

enum TestMeasurementParserMetric: String {
    case appLaunch = "Duration (AppLaunch)"
    case clockMonotonicTime = "Clock Monotonic Time"
    case cpuTime = "CPU Time"
    case memoryPeakPhysical = "Memory Peak Physical"
    case memoryPhysical = "Memory Physical"
    case cpuInstructionsRetired = "CPU Instructions Retired"
    case diskLogicalWrites = "Disk Logical Writes"
    case cpuCycles = "CPU Cycles"
    
    var regexValue: String {
        switch self {
        case .appLaunch:
            return rawValue.replacingOccurrences(of: "(", with: "\\(").replacingOccurrences(of: ")", with: "\\)")
        default:
            return rawValue
        }
    }
}

/// This class is responsible for extracting XCTest measurement run results from stderr in lieu of an official API
/// Heavily inspired by https://stackoverflow.com/questions/54814422/how-to-extract-performance-metrics-measured-by-measureblock-in-xctest
class TestMeasurementParser {
    private let pipe = Pipe()
    private let regex: NSRegularExpression
    private var results = [String: Double]()
    
    init() {
        do {
            let pattern = """
            \\[(\
            \(TestMeasurementParserMetric.appLaunch.regexValue)|\
            \(TestMeasurementParserMetric.clockMonotonicTime.regexValue)|\
            \(TestMeasurementParserMetric.cpuTime.regexValue)|\
            \(TestMeasurementParserMetric.memoryPeakPhysical.regexValue)|\
            \(TestMeasurementParserMetric.memoryPhysical.regexValue)|\
            \(TestMeasurementParserMetric.cpuInstructionsRetired.regexValue)|\
            \(TestMeasurementParserMetric.diskLogicalWrites.regexValue)|\
            \(TestMeasurementParserMetric.cpuCycles.regexValue)\
            ), \
            (s|kB|kI|kC)\\] \
            average: ([0-9\\.]*),
            """
            
            regex = try NSRegularExpression(pattern: pattern,
                                            options: .caseInsensitive)
        } catch {
            fatalError("Invalid regular expression")
        }
    }
    
    /// Running an XCTest measure block within this will enable the `XCTestMeasurementParser` to read resulting values from stderr and store them locally
    /// - Parameters:
    ///   - testCase: we need the test case so that we can add and wait for an expectation on it, allowing the capturing to finish
    ///   - block: should contain the normal test steps and measure block
    func capture(testCase: XCTestCase, block: @escaping () -> Void) {
        results.removeAll()
        
        // Save original output
        let original = dup(STDERR_FILENO)
        
        // Configure `stderr` so that it's not buffered
        setvbuf(stderr, nil, _IONBF, 0)
        
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else {
                return
            }
            
            let string = String(data: handle.availableData, encoding: .utf8) ?? "<Non-ascii data of size\(handle.availableData.count)>\n"
            self.regex.matches(in: string, options: .reportCompletion).forEach {
                if let nameIndex = Range($0.range(at: 1), in: string),
                   let averageIndex = Range($0.range(at: 3), in: string) {
                    let name = String(string[nameIndex])
                    let average = Double(string[averageIndex])
                    
                    self.results[name] = average
                }
            }
            
            // Print to stdout because stderr is piped
            print("\(string)")
        }
        
        block()
        
        // Revert
        fflush(stderr)
        dup2(original, STDERR_FILENO)
        close(original)
        
        // Allow the parser to finish
        let expectation = testCase.expectation(description: "Wait for the results to be gathered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            expectation.fulfill()
        }
        
        testCase.waitForExpectations(timeout: 10.0)
    }
    
    /// Retrieve the recorded average value for a particular metric
    /// - Parameter metric: Needs to match one of the metrics passed in the XCTest measure metrics array
    /// - Returns: The resulting average value
    func valueForMetric(_ metric: TestMeasurementParserMetric) -> Double? {
        results[metric.rawValue]
    }
}
