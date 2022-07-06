//
//  BackgroundTaskTests.swift
//  UnitTests
//
//  Created by Ismail on 28.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest

@testable import ElementX

class BackgroundTaskTests: XCTestCase {

    private enum Constants {
        static let bgTaskName = "test"
    }

    func testInAnExtension() {
        let service = UIKitBackgroundTaskService(withApplication: nil)
        let task = service.startBackgroundTask(withName: Constants.bgTaskName)

        XCTAssertNil(task, "Task should not be created")
    }

    func testInitAndStop() {
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockHealty)
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
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockHealty)

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
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockHealty)

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
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockHealty)

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
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockHealty)

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
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockHealty)

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
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockBroken)

        //  create two reusable task with the same name
        let task = service.startBackgroundTask(withName: Constants.bgTaskName)

        XCTAssertNil(task, "Task should not be created")
    }

    func testNoTimeApp() {
        let service = UIKitBackgroundTaskService(withApplication: UIApplication.mockAboutToSuspend)

        //  create two reusable task with the same name
        let task = service.startBackgroundTask(withName: Constants.bgTaskName)

        XCTAssertNil(task, "Task should not be created")
    }

}

private extension UIApplication {

    static var mockHealty: ApplicationProtocol {
        MockApplication()
    }

    static var mockBroken: ApplicationProtocol {
        MockApplication(withState: .inactive,
                        backgroundTimeRemaining: 0,
                        allowTasks: false)
    }

    static var mockAboutToSuspend: ApplicationProtocol {
        MockApplication(withState: .background,
                        backgroundTimeRemaining: 2,
                        allowTasks: false)
    }

}

private class MockApplication: ApplicationProtocol {

    let applicationState: UIApplication.State
    let backgroundTimeRemaining: TimeInterval
    private let allowTasks: Bool

    init(withState applicationState: UIApplication.State = .active,
         backgroundTimeRemaining: TimeInterval = 10,
         allowTasks: Bool = true) {
        self.applicationState = applicationState
        self.backgroundTimeRemaining = backgroundTimeRemaining
        self.allowTasks = allowTasks
    }

    private static var bgTaskIdentifier = 0

    private var bgTasks: [UIBackgroundTaskIdentifier: Bool] = [:]

    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        guard allowTasks else {
            return .invalid
        }
        return beginBackgroundTask(withName: nil, expirationHandler: handler)
    }

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        guard allowTasks else {
            return .invalid
        }
        Self.bgTaskIdentifier += 1

        let identifier = UIBackgroundTaskIdentifier(rawValue: Self.bgTaskIdentifier)
        bgTasks[identifier] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            handler?()
        }
        return identifier
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        guard allowTasks else {
            return
        }
        bgTasks.removeValue(forKey: identifier)
    }

}
