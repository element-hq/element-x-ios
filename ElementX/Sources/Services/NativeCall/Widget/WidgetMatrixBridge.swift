//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtcKit

// Temporary: the widget-driver stopgap. The released SDK bindings lack delayed events, a room-state
// feed and to-device messaging, but their widget driver implements all of them for Element Call web.
// This speaks the widget API to that driver in-process, with no web view. Delete this folder once
// the bindings gain those entry points (delayed and delayed-state sends, delayed-event updates, a
// room-state subscription, to-device send and subscribe with encryption info), and give
// `MatrixRtcTransportAdapter` an SDK-backed `MatrixRtcRoomBridgeProtocol`.

/// One widget driver for one room, as the RTC core's Matrix bridge.
///
/// Wire protocol (verified against the SDK's widget machine): every message is
/// `{api, widgetId, requestId, action, data}`; a response echoes the request with a `response` key.
/// With `initAfterContentLoad` off the driver opens with a `capabilities` request, calls the
/// capabilities provider, confirms with `notify_capabilities`, then pushes the current room state.
/// Requests sent before that are silently dropped, and the driver keeps at most 15 unanswered
/// requests of its own, so everything it sends is answered inline.
///
/// State arrives as deltas (`update_state` from sync, `send_event` for timeline-borne state) while the
/// core wants the full state on every tick. Room state is replace-only, a leave being a present `{}`
/// event, so the latest event per state key *is* the full state and the map below re-emits it whole.
actor WidgetMatrixBridge: MatrixRtcRoomBridgeProtocol {
    nonisolated let roomID: String
    
    private enum Phase: Equatable {
        case idle, negotiating, ready, stopped
    }
    
    private struct PendingRequest {
        let continuation: CheckedContinuation<Result<Data, MatrixRtcRoomBridgeError>, Never>
        let timeout: Task<Void, Never>
    }
    
    private let widgetID: String
    private let runDriver: @Sendable () async -> Void
    private let requestTimeout: Duration
    
    private var channel: (any WidgetDriverChannel)?
    private var phase: Phase = .idle
    private var negotiationWaiters = [CheckedContinuation<Result<Void, MatrixRtcRoomBridgeError>, Never>]()
    private var negotiationTimeout: Task<Void, Never>?
    private var pending = [String: PendingRequest]()
    
    /// Event type → state key → latest event: the current state of every type we receive.
    private var state = [String: [String: MatrixRtcRoomStateEvent]]()
    private var stateSubscribers = [UUID: (eventType: String, continuation: AsyncStream<[MatrixRtcRoomStateEvent]>.Continuation)]()
    private var toDeviceSubscribers = [UUID: AsyncStream<MatrixRtcToDeviceMessage>.Continuation]()
    
    /// - Parameters:
    ///   - channel: the driver's handle (or a fake in tests).
    ///   - runDriver: runs the driver; must not capture the handle, or the driver never stops.
    init(roomID: String,
         widgetID: String,
         channel: any WidgetDriverChannel,
         requestTimeout: Duration = .seconds(30),
         runDriver: @escaping @Sendable () async -> Void) {
        self.roomID = roomID
        self.widgetID = widgetID
        self.channel = channel
        self.requestTimeout = requestTimeout
        self.runDriver = runDriver
    }
    
    // MARK: - Lifecycle
    
    func start() async -> Result<Void, MatrixRtcRoomBridgeError> {
        guard phase == .idle, let channel else { return .failure(.notRunning) }
        phase = .negotiating
        MXLog.info("WidgetBridge: starting for \(roomID)")
        
        let runDriver = runDriver
        Task.detached { await runDriver() }
        
        // Receiving must be under way before negotiation is awaited: the driver's first request
        // times out after 10 s.
        Task { [weak self] in
            while let raw = await channel.recv() {
                guard let self, await self.handleIncoming(raw) else { return }
            }
            await self?.driverStopped()
        }
        
        negotiationTimeout = Task { [weak self, requestTimeout] in
            try? await Task.sleep(for: requestTimeout)
            await self?.failNegotiation(with: .timedOut)
        }
        return await withCheckedContinuation { continuation in
            negotiationWaiters.append(continuation)
        }
    }
    
    func stop() async {
        guard phase != .stopped, let channel else { return }
        MXLog.info("WidgetBridge: stopping for \(roomID)")
        tearDown()
        // The driver only stops once its handle is gone, and the pending `recv()` holds the handle:
        // a request the machine always answers makes that `recv()` return, after which nothing
        // receives again and the handle is released.
        _ = await channel.send(msg: WidgetJSON.serialize(["api": "fromWidget",
                                                          "widgetId": widgetID,
                                                          "requestId": UUID().uuidString,
                                                          "action": "supported_api_versions",
                                                          "data": [String: Any]()]) ?? "")
    }
    
    // MARK: - Sends
    
    func sendDelayedEvent(eventType: String, stateKey: String?, contentJSON: String, delayMs: UInt64) async -> Result<String, MatrixRtcRoomBridgeError> {
        guard let content = WidgetJSON.parseObject(contentJSON) else { return .failure(.invalidResponse("content is not a JSON object")) }
        var data: [String: Any] = ["type": eventType, "content": content, "delay": delayMs]
        if let stateKey {
            data["state_key"] = stateKey
        }
        return await request(action: "send_event", data: data).flatMap { response in
            guard let delayID = response["delay_id"] as? String else {
                return .failure(.invalidResponse("no delay_id in the send_event response"))
            }
            return .success(delayID)
        }
    }
    
    func updateDelayedEvent(delayID: String, action: MatrixRtcDelayedEventAction) async -> Result<Void, MatrixRtcRoomBridgeError> {
        let wireAction = switch action {
        case .cancel: "cancel"
        case .restart: "restart"
        }
        return await request(action: "org.matrix.msc4157.update_delayed_event", data: ["delay_id": delayID, "action": wireAction]).map { _ in }
    }
    
    func sendRoomEvent(eventType: String, contentJSON: String) async -> Result<String, MatrixRtcRoomBridgeError> {
        guard let content = WidgetJSON.parseObject(contentJSON) else { return .failure(.invalidResponse("content is not a JSON object")) }
        return await request(action: "send_event", data: ["type": eventType, "content": content]).flatMap { response in
            guard let eventID = response["event_id"] as? String else {
                return .failure(.invalidResponse("no event_id in the send_event response"))
            }
            return .success(eventID)
        }
    }
    
    func sendToDeviceMessage(eventType: String, messages: [String: [String: String]]) async -> Result<[String: [String]], MatrixRtcRoomBridgeError> {
        var wireMessages = [String: [String: Any]]()
        for (userID, devices) in messages {
            for (deviceID, contentJSON) in devices {
                guard let content = WidgetJSON.parseObject(contentJSON) else { return .failure(.invalidResponse("content is not a JSON object")) }
                wireMessages[userID, default: [:]][deviceID] = content
            }
        }
        return await request(action: "send_to_device", data: ["type": eventType, "messages": wireMessages]).map { response in
            response["failures"] as? [String: [String]] ?? [:]
        }
    }
    
    // MARK: - Feeds
    
    nonisolated func stateEvents(eventType: String) -> AsyncStream<[MatrixRtcRoomStateEvent]> {
        let (stream, continuation) = AsyncStream<[MatrixRtcRoomStateEvent]>.makeStream()
        let id = UUID()
        Task { await self.addStateSubscriber(id: id, eventType: eventType, continuation: continuation) }
        continuation.onTermination = { _ in
            Task { await self.removeStateSubscriber(id: id) }
        }
        return stream
    }
    
    nonisolated func toDeviceMessages() -> AsyncStream<MatrixRtcToDeviceMessage> {
        let (stream, continuation) = AsyncStream<MatrixRtcToDeviceMessage>.makeStream()
        let id = UUID()
        Task { await self.addToDeviceSubscriber(id: id, continuation: continuation) }
        continuation.onTermination = { _ in
            Task { await self.removeToDeviceSubscriber(id: id) }
        }
        return stream
    }
    
    private func addStateSubscriber(id: UUID, eventType: String, continuation: AsyncStream<[MatrixRtcRoomStateEvent]>.Continuation) {
        guard phase != .stopped else {
            continuation.finish()
            return
        }
        stateSubscribers[id] = (eventType, continuation)
        if let current = state[eventType], !current.isEmpty {
            continuation.yield(Array(current.values))
        }
    }
    
    private func removeStateSubscriber(id: UUID) {
        stateSubscribers[id] = nil
    }
    
    private func addToDeviceSubscriber(id: UUID, continuation: AsyncStream<MatrixRtcToDeviceMessage>.Continuation) {
        guard phase != .stopped else {
            continuation.finish()
            return
        }
        toDeviceSubscribers[id] = continuation
    }
    
    private func removeToDeviceSubscriber(id: UUID) {
        toDeviceSubscribers[id] = nil
    }
    
    // MARK: - Requests
    
    private func request(action: String, data: [String: Any]) async -> Result<[String: Any], MatrixRtcRoomBridgeError> {
        guard phase == .ready, let channel else { return .failure(.notRunning) }
        let requestID = UUID().uuidString
        guard let message = WidgetJSON.serialize(["api": "fromWidget",
                                                  "widgetId": widgetID,
                                                  "requestId": requestID,
                                                  "action": action,
                                                  "data": data]) else {
            return .failure(.invalidResponse("cannot encode the \(action) request"))
        }
        MXLog.verbose("WidgetBridge: → \(action) \(requestID)")
        
        let reply: Result<Data, MatrixRtcRoomBridgeError> = await withCheckedContinuation { continuation in
            let timeout = Task { [weak self, requestTimeout] in
                try? await Task.sleep(for: requestTimeout)
                await self?.resume(requestID, with: .failure(.timedOut))
            }
            pending[requestID] = PendingRequest(continuation: continuation, timeout: timeout)
            Task {
                if await !channel.send(msg: message) {
                    resume(requestID, with: .failure(.notRunning))
                }
            }
        }
        return reply.flatMap { data in
            guard let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(.invalidResponse("the \(action) response is not a JSON object"))
            }
            return .success(response)
        }
    }
    
    private func resume(_ requestID: String, with result: Result<Data, MatrixRtcRoomBridgeError>) {
        guard let request = pending.removeValue(forKey: requestID) else { return }
        request.timeout.cancel()
        request.continuation.resume(returning: result)
    }
    
    // MARK: - Incoming
    
    /// - Returns: whether to keep receiving.
    private func handleIncoming(_ raw: String) async -> Bool {
        guard phase != .stopped else { return false }
        guard let message = WidgetJSON.parseObject(raw), message["widgetId"] as? String == widgetID else {
            MXLog.warning("WidgetBridge: ignoring a message for another widget")
            return true
        }
        let api = message["api"] as? String
        let action = message["action"] as? String ?? ""
        let requestID = message["requestId"] as? String ?? ""
        
        if api == "fromWidget", let response = message["response"] {
            handleResponse(response, action: action, requestID: requestID)
            return true
        }
        guard api == "toWidget" else { return true }
        
        MXLog.verbose("WidgetBridge: ← \(action) \(requestID)")
        let data = message["data"] as? [String: Any] ?? [:]
        var response: [String: Any] = [:]
        switch action {
        case "capabilities":
            response["capabilities"] = WidgetCapabilityGrant.capabilityStrings
        case "notify_capabilities":
            didNegotiate(approved: data["approved"] as? [String] ?? [])
        case "update_state":
            var changedTypes = Set<String>()
            for case let event as [String: Any] in data["state"] as? [Any] ?? [] {
                if let eventType = upsert(event) {
                    changedTypes.insert(eventType)
                }
            }
            changedTypes.forEach(emitSnapshot)
        case "send_event":
            if data["state_key"] != nil, let eventType = upsert(data) {
                emitSnapshot(of: eventType)
            }
        case "send_to_device":
            deliverToDevice(data)
        default:
            break
        }
        
        var echo = message
        echo["response"] = response
        if let channel, let encoded = WidgetJSON.serialize(echo) {
            if await !channel.send(msg: encoded) {
                driverStopped()
                return false
            }
        }
        return phase != .stopped
    }
    
    private func handleResponse(_ response: Any, action: String, requestID: String) {
        guard pending[requestID] != nil else {
            // Our own stop poke, or a request that already timed out.
            MXLog.verbose("WidgetBridge: unmatched response to \(action) \(requestID)")
            return
        }
        guard let object = response as? [String: Any] else {
            resume(requestID, with: .failure(.invalidResponse("the \(action) response is not a JSON object")))
            return
        }
        if let error = object["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "unknown error"
            let matrixError = error["matrix_api_error"] as? [String: Any]
            let body = matrixError?["response"] as? [String: Any]
            MXLog.warning("WidgetBridge: \(action) \(requestID) failed: \(message)")
            resume(requestID, with: .failure(.matrixAPI(errcode: body?["errcode"] as? String,
                                                        httpStatus: matrixError?["http_status"] as? Int,
                                                        message: message)))
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: object) else {
            resume(requestID, with: .failure(.invalidResponse("cannot encode the \(action) response")))
            return
        }
        resume(requestID, with: .success(data))
    }
    
    private func didNegotiate(approved: [String]) {
        guard phase == .negotiating else { return }
        MXLog.info("WidgetBridge: negotiated \(approved.count) capabilities for \(roomID)")
        phase = .ready
        negotiationTimeout?.cancel()
        negotiationTimeout = nil
        let waiters = negotiationWaiters
        negotiationWaiters.removeAll()
        waiters.forEach { $0.resume(returning: .success(())) }
    }
    
    private func failNegotiation(with error: MatrixRtcRoomBridgeError) {
        guard phase == .negotiating else { return }
        MXLog.error("WidgetBridge: negotiation failed for \(roomID): \(error)")
        tearDown()
    }
    
    /// A state event arrived (initial read, sync state block or timeline): remember the latest per
    /// state key. One batch yields one snapshot, so emitting is the caller's.
    /// - Returns: the event type when the state changed.
    private func upsert(_ event: [String: Any]) -> String? {
        guard let eventType = event["type"] as? String,
              let stateKey = event["state_key"] as? String,
              let sender = event["sender"] as? String,
              let content = event["content"] as? [String: Any],
              let contentJSON = WidgetJSON.serialize(content) else {
            MXLog.warning("WidgetBridge: ignoring a malformed state event")
            return nil
        }
        let eventID = event["event_id"] as? String
        if let eventID, state[eventType]?[stateKey]?.eventID == eventID {
            return nil // The same change through both routes.
        }
        let timestamp = (event["origin_server_ts"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        state[eventType, default: [:]][stateKey] = MatrixRtcRoomStateEvent(eventID: eventID,
                                                                           eventType: eventType,
                                                                           stateKey: stateKey,
                                                                           sender: sender,
                                                                           originServerTimestamp: timestamp,
                                                                           contentJSON: contentJSON)
        return eventType
    }
    
    /// Hands subscribers the whole current state of the type.
    private func emitSnapshot(of eventType: String) {
        let snapshot = Array(state[eventType, default: [:]].values)
        guard !snapshot.isEmpty else { return }
        for (subscribedType, continuation) in stateSubscribers.values where subscribedType == eventType {
            continuation.yield(snapshot)
        }
    }
    
    /// The driver hands over `{type, content, sender, encrypted}` only: it has already dropped
    /// cleartext in an encrypted room and attested the sender of an encrypted message, but reports
    /// neither the sender's device nor whether it is cross-signed. The device is read from the key
    /// message itself, or failing that from the sender's one live membership, and an encrypted
    /// message is taken as cross-signed: the trust Element Call web gets through this same driver, and
    /// a relaxation of the core's own rule for as long as the driver is the transport.
    private func deliverToDevice(_ data: [String: Any]) {
        guard let eventType = data["type"] as? String,
              let sender = data["sender"] as? String,
              let content = data["content"] as? [String: Any],
              let contentJSON = WidgetJSON.serialize(content) else {
            MXLog.warning("WidgetBridge: ignoring a malformed to-device message")
            return
        }
        let wasEncrypted = data["encrypted"] as? Bool ?? false
        let claimedDeviceID = Self.claimedDeviceID(in: content)
        let deviceID = claimedDeviceID ?? membershipDeviceID(of: sender)
        if claimedDeviceID == nil {
            // Field names only, never values: which shape of key message the peer speaks.
            MXLog.info("WidgetBridge: \(eventType) from \(sender) names no device (fields: \(content.keys.sorted())), inferred \(deviceID ?? "none")")
        }
        let message = MatrixRtcToDeviceMessage(eventType: eventType,
                                               attestedSenderID: sender,
                                               senderDeviceID: deviceID,
                                               isSenderCrossSigned: wasEncrypted,
                                               wasEncrypted: wasEncrypted,
                                               contentJSON: contentJSON)
        toDeviceSubscribers.values.forEach { $0.yield(message) }
    }
    
    /// The device the key message claims to come from: Element Call has written it at the top level
    /// (`device_id`) and, more recently, as `member.claimed_device_id` (matrix-js-sdk's
    /// `EncryptionKeysToDeviceEventContent`). Claimed is the right word: nothing here verifies it against
    /// the Olm sender device, see `deliverToDevice`.
    private nonisolated static func claimedDeviceID(in content: [String: Any]) -> String? {
        if let deviceID = content["device_id"] as? String {
            return deviceID
        }
        let member = content["member"] as? [String: Any]
        return (member?["claimed_device_id"] ?? member?["device_id"]) as? String
    }
    
    /// The device behind the user's live call membership, when there is exactly one. Element Call's
    /// key messages do not always name their device, while the core refuses a key whose device it
    /// cannot match to the membership.
    private func membershipDeviceID(of userID: String) -> String? {
        let memberships = (state[MatrixRtcEventTypes.legacyStateMember] ?? [:]).values.filter { $0.sender == userID && $0.contentJSON != "{}" }
        var deviceIDs = Set<String>()
        for membership in memberships {
            if let content = WidgetJSON.parseObject(membership.contentJSON) {
                for case let entry as [String: Any] in content["memberships"] as? [Any] ?? [] {
                    if let deviceID = entry["device_id"] as? String {
                        deviceIDs.insert(deviceID)
                    }
                }
            }
            if deviceIDs.isEmpty, let deviceID = Self.deviceID(inStateKey: membership.stateKey, userID: userID) {
                deviceIDs.insert(deviceID)
            }
        }
        return deviceIDs.count == 1 ? deviceIDs.first : nil
    }
    
    /// Element Call keys its membership `_{user}_{device}_m.call` (or `{user}_{device}`, or just the
    /// user); the device is whatever follows the user ID.
    private nonisolated static func deviceID(inStateKey stateKey: String, userID: String) -> String? {
        var key = stateKey
        if key.hasPrefix("_") {
            key.removeFirst()
        }
        guard key.hasPrefix(userID + "_") else { return nil }
        key.removeFirst(userID.count + 1)
        if key.hasSuffix("_m.call") {
            key.removeLast("_m.call".count)
        }
        return key.isEmpty ? nil : key
    }
    
    private func driverStopped() {
        guard phase != .stopped else { return }
        MXLog.warning("WidgetBridge: driver stopped for \(roomID)")
        tearDown()
    }
    
    /// Fails everything in flight and closes every feed; the channel reference goes with it.
    private func tearDown() {
        phase = .stopped
        negotiationTimeout?.cancel()
        negotiationTimeout = nil
        let waiters = negotiationWaiters
        negotiationWaiters.removeAll()
        waiters.forEach { $0.resume(returning: .failure(.notRunning)) }
        for requestID in Array(pending.keys) {
            resume(requestID, with: .failure(.notRunning))
        }
        stateSubscribers.values.forEach { $0.continuation.finish() }
        stateSubscribers.removeAll()
        toDeviceSubscribers.values.forEach { $0.finish() }
        toDeviceSubscribers.removeAll()
        channel = nil
    }
}
