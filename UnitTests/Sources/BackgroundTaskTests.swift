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

import XCTest

@testable import ElementX

@MainActor
class BackgroundTaskTests: XCTestCase {
    private enum Constants {
        static let bgTaskName = "test"
    }

    func testInitAndStop() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.default)

        guard let task = service.startBackgroundTask(withName: Constants.bgTaskName) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        XCTAssertEqual(task.name, Constants.bgTaskName, "Task name should be persisted")
        XCTAssertFalse(task.isReusable, "Task should be not reusable by default")
        XCTAssertTrue(task.isRunning, "Task should be running")

        task.stop()

        XCTAssertFalse(task.isRunning, "Task should be stopped")
    }

    func testNotReusableInit() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.default)

        //  create two not reusable task with the same name
        guard let task1 = service.startBackgroundTask(withName: Constants.bgTaskName),
              let task2 = service.startBackgroundTask(withName: Constants.bgTaskName) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        //  task1 & task2 should be different instances
        XCTAssertFalse(task1 === task2,
                       "Handler should create different tasks when reusability disabled")
    }

    func testReusableInit() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.default)

        //  create two reusable task with the same name
        guard let task1 = service.startBackgroundTask(withName: Constants.bgTaskName, isReusable: true),
              let task2 = service.startBackgroundTask(withName: Constants.bgTaskName, isReusable: true) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        //  task1 and task2 should be the same instance
        XCTAssertTrue(task1 === task2,
                      "Handler should create different tasks when reusability disabled")

        XCTAssertEqual(task1.name, Constants.bgTaskName, "Task name should be persisted")
        XCTAssertTrue(task1.isReusable, "Task should be reusable")
        XCTAssertTrue(task1.isRunning, "Task should be running")
    }

    func testMultipleStops() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.default)

        //  create two reusable task with the same name
        guard let task = service.startBackgroundTask(withName: Constants.bgTaskName, isReusable: true),
              service.startBackgroundTask(withName: Constants.bgTaskName, isReusable: true) != nil else {
            XCTFail("Failed to setup test conditions")
            return
        }

        XCTAssertTrue(task.isRunning, "Task should be running")

        task.stop()

        XCTAssertTrue(task.isRunning, "Task should be still running after one stop call")

        task.stop()

        XCTAssertFalse(task.isRunning, "Task should be stopped after two stop calls")
    }

    func testNotValidReuse() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.default)

        //  create two reusable task with the same name
        guard let task = service.startBackgroundTask(withName: Constants.bgTaskName, isReusable: true) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        XCTAssertTrue(task.isRunning, "Task should be running")

        task.stop()

        XCTAssertFalse(task.isRunning, "Task should be stopped after stop")

        task.reuse()

        XCTAssertFalse(task.isRunning, "Task should be stopped after one stop call, even if reuse is called after")
    }

    func testValidReuse() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.default)

        //  create two reusable task with the same name
        guard let task = service.startBackgroundTask(withName: Constants.bgTaskName, isReusable: true) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        XCTAssertTrue(task.isRunning, "Task should be running")

        task.reuse()

        XCTAssertTrue(task.isRunning, "Task should be still running")

        task.stop()

        XCTAssertTrue(task.isRunning, "Task should be still running after one stop call")

        task.stop()

        XCTAssertFalse(task.isRunning, "Task should be stopped after two stop calls")
    }

    func testBrokenApp() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.mockBroken)

        //  create two reusable task with the same name
        let task = service.startBackgroundTask(withName: Constants.bgTaskName)

        XCTAssertNil(task, "Task should not be created")
    }

    func testNoTimeApp() {
        let service = UIKitBackgroundTaskService(appMediator: AppMediatorMock.mockAboutToSuspend)

        //  create two reusable task with the same name
        let task = service.startBackgroundTask(withName: Constants.bgTaskName)

        XCTAssertNil(task, "Task should not be created")
    }
}
