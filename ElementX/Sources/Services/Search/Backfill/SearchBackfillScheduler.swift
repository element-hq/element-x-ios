//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import BackgroundTasks
import Foundation
import UIKit

/// Hosts ``SearchBackfillRunner`` on the background task scheduler so the sweep survives the app being
/// backgrounded, and offers a foreground entry point for when the user opens search.
///
/// The foreground trigger is not a nicety: `BGProcessingTask` is best-effort with no guaranteed
/// cadence, so it is entirely possible for the background half never to run on a given device.
@MainActor
final class SearchBackfillScheduler {
    private let appSettings: AppSettings
    private let userSessionProvider: () -> UserSessionProtocol?
    private let makeRunner: (UserSessionProtocol, SearchBackfillBudget) -> SearchBackfillRunnerProtocol
    
    private var executionTask: Task<Void, Never>?
    /// Distinguishes one execution from the next, so a sweep that finishes after being superseded
    /// cannot clear the handle belonging to the sweep that replaced it.
    private var executionID = 0
    
    init(appSettings: AppSettings,
         userSessionProvider: @escaping () -> UserSessionProtocol?,
         makeRunner: ((UserSessionProtocol, SearchBackfillBudget) -> SearchBackfillRunnerProtocol)? = nil) {
        self.appSettings = appSettings
        self.userSessionProvider = userSessionProvider
        self.makeRunner = makeRunner ?? { userSession, budget in
            SearchBackfillRunner(clientProxy: userSession.clientProxy,
                                 store: SearchBackfillStore(sessionDirectories: userSession.sessionDirectories),
                                 roomQueueProvider: { [clientProxy = userSession.clientProxy] in
                                     await Self.roomQueue(clientProxy: clientProxy, limit: budget.roomQueueLimit)
                                 },
                                 budget: budget)
        }
    }
    
    /// Registers the background task. Must be called before the app finishes launching, so it runs
    /// with no user session — the handler resolves one when it fires.
    func register() {
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: appSettings.backgroundSearchBackfillTaskIdentifier,
                                                         using: .main) { [weak self] task in
            guard let task = task as? BGProcessingTask else {
                MXLog.error("Invalid search backfill background task configuration")
                return
            }
            
            self?.handle(task)
        }
        
        MXLog.info("Registered search backfill background task with result: \(registered)")
    }
    
    /// Asks the system to run a sweep at some future point of its choosing.
    func schedule() {
        guard appSettings.searchBackfillEnabled else { return }
        
        let request = BGProcessingTaskRequest(identifier: appSettings.backgroundSearchBackfillTaskIdentifier)
        // `element-meta#3252` asks for "connected to the power source and wifi". iOS has no Wi-Fi-only
        // constraint, so the page budgets and inter-page delays are what bound the data cost instead.
        request.requiresExternalPower = true
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            MXLog.info("Scheduled the search backfill background task")
        } catch {
            MXLog.error("Failed scheduling the search backfill background task: \(error)")
        }
    }
    
    /// Runs a bounded sweep while the app is in the foreground, e.g. when the user opens search.
    ///
    /// Budgets are much tighter than the background task's: the user is holding the device, on their
    /// own battery and quite possibly on cellular, so this tops the index up rather than trying to
    /// drain the queue.
    func runInForeground(excludedRoomIDs: Set<String> = []) {
        guard appSettings.searchBackfillEnabled, executionTask == nil, let userSession = userSessionProvider() else { return }
        
        start(runner: makeRunner(userSession, .foreground), excludedRoomIDs: excludedRoomIDs)
    }
    
    /// Stops any running sweep and unschedules the background task. The cursor file dies with the
    /// session directory, but a sweep left running would keep downloading a signed-out user's history.
    func stop() {
        executionTask?.cancel()
        executionTask = nil
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: appSettings.backgroundSearchBackfillTaskIdentifier)
    }
    
    // MARK: - Private
    
    private func handle(_ task: BGProcessingTask) {
        MXLog.info("Started the search backfill background task")
        
        // Re-armed before doing any work so a sweep that needs more executions gets them.
        schedule()
        
        // BGTask isn't annotated but is documented as thread-safe, with setTaskCompleted(success:)
        // callable from any thread.
        nonisolated(unsafe) let task = task
        // The task must be completed exactly once: never calling it counts against future scheduling
        // budget, and the expiration handler can race the sweep's own completion.
        let completion = OneShotTaskCompletion { success in task.setTaskCompleted(success: success) }
        
        // Re-read live rather than trusting the value frozen at submission time: a user who turned
        // the sweep off should stop paying for history downloads at the next execution.
        guard appSettings.searchBackfillEnabled, let userSession = userSessionProvider() else {
            MXLog.info("Search backfill is unavailable, skipping the sweep")
            completion.complete(success: true)
            return
        }
        
        // A processing task can be delivered while the app is active — the same reason
        // `pauseClientServices(isBackgroundTask:)` guards on the application state. A room may be on
        // screen then, and this path has no way to know which, so it would double-paginate the live
        // timeline the user is reading. The foreground trigger covers that case with an exclusion set.
        guard UIApplication.shared.applicationState != .active else {
            MXLog.info("The app is active, leaving the search backfill to the foreground trigger")
            completion.complete(success: true)
            return
        }
        
        // Without this, a foreground sweep started moments ago would be replaced rather than
        // cancelled, leaving two runners racing on one cursor file with the older one unreachable
        // from `stop()` — so it would outlive sign-out.
        guard executionTask == nil else {
            MXLog.info("A search backfill sweep is already running, skipping this execution")
            completion.complete(success: true)
            return
        }
        
        let executionTask = start(runner: makeRunner(userSession, .background), excludedRoomIDs: []) { cursor in
            MXLog.info("Search backfill background task finished, \(cursor.index)/\(cursor.queue.count) rooms")
            completion.complete(success: true)
        }
        
        task.expirationHandler = { @Sendable in
            MXLog.info("Search backfill background task is about to expire")
            executionTask.cancel()
            completion.complete(success: false)
        }
    }
    
    @discardableResult
    private func start(runner: SearchBackfillRunnerProtocol,
                       excludedRoomIDs: Set<String>,
                       completion: (@MainActor (SearchBackfillCursor) -> Void)? = nil) -> Task<Void, Never> {
        executionID += 1
        let executionID = executionID
        
        let task = Task { [weak self] in
            let cursor = await runner.runOnce(excludedRoomIDs: excludedRoomIDs)
            self?.finish(executionID: executionID)
            completion?(cursor)
        }
        
        executionTask = task
        return task
    }
    
    private func finish(executionID: Int) {
        guard executionID == self.executionID else { return }
        executionTask = nil
    }
    
    /// Builds the sweep queue from the room list, waiting a bounded time for it to sync.
    ///
    /// Uses the static provider because the others have their filters mutated by whatever screen is
    /// on top, and only IDs are kept because a `RoomSummary` pins a live Rust room handle.
    private static func roomQueue(clientProxy: ClientProxyProtocol, limit: Int) async -> [String] {
        let provider = clientProxy.staticRoomSummaryProvider
        
        // A headless start can begin before the room list has synced. Bounded, because an unbounded
        // wait here would burn the background task's whole allowance and get it killed.
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        while !provider.statePublisher.value.isLoaded, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(250))
        }
        
        guard provider.statePublisher.value.isLoaded else {
            MXLog.warning("Room list did not load in time, skipping the search backfill sweep")
            return []
        }
        
        return SearchBackfillPlanner.plan(summaries: provider.roomListPublisher.value, limit: limit)
    }
}

/// Calls through exactly once, however many times it is asked to.
///
/// `BGTask.setTaskCompleted(success:)` must be called precisely once — the expiration handler and the
/// sweep's own completion can otherwise both fire for the same task.
private final nonisolated class OneShotTaskCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@Sendable (Bool) -> Void)?
    
    init(_ handler: @escaping @Sendable (Bool) -> Void) {
        self.handler = handler
    }
    
    func complete(success: Bool) {
        let handler = lock.withLock {
            defer { self.handler = nil }
            return self.handler
        }
        handler?(success)
    }
}
