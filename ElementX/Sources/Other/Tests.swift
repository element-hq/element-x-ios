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

public enum Tests {
    /// Flag indicating whether the app is running the unit tests.
    static var isRunningUnitTests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["IS_RUNNING_UNIT_TESTS"] == "1"
        #else
        false
        #endif
    }

    /// Flag indicating whether the app is running the UI tests.
    static var isRunningUITests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["IS_RUNNING_UI_TESTS"] == "1"
        #else
        false
        #endif
    }
}
