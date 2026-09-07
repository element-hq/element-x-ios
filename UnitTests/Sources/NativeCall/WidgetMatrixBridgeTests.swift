//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRtcKit
import Synchronization
import Testing

/// The widget-driver stopgap's wire handling, against a fake driver pipe.
@Suite(.timeLimit(.minutes(1)))
struct WidgetMatrixBridgeTests {
    private let widgetID = "widget"
    private let channel = FakeWidgetChannel()
    
    private func makeBridge(requestTimeout: Duration = .seconds(5)) -> WidgetMatrixBridge {
        WidgetMatrixBridge(roomID: "!room:example.org", widgetID: widgetID, channel: channel, requestTimeout: requestTimeout) { }
    }
    
    // MARK: - Negotiation
    
    @Test
    func negotiationAnswersCapabilitiesAndResolvesStart() async throws {
        let bridge = makeBridge()
        let start = Task { await bridge.start() }
        
        channel.push(toWidget(action: "capabilities", requestID: "cap"))
        let reply = try await nextSent()
        #expect(reply["requestId"] as? String == "cap")
        #expect(reply["api"] as? String == "toWidget")
        let response = try #require(reply["response"] as? [String: Any])
        let strings = try #require(response["capabilities"] as? [String])
        #expect(strings.contains("org.matrix.msc2762.receive.state_event:org.matrix.msc3401.call.member"))
        #expect(strings.contains("org.matrix.msc3819.receive.to_device:io.element.call.encryption_keys"))
        #expect(strings.contains("org.matrix.msc4157.send.delayed_event"))
        
        // Nothing is served before the driver confirms.
        #expect(await bridge.sendRoomEvent(eventType: "m.reaction", contentJSON: "{}") == .failure(.notRunning))
        
        channel.push(toWidget(action: "notify_capabilities", requestID: "notify", data: ["requested": [], "approved": strings]))
        let echo = try await nextSent()
        #expect(echo["requestId"] as? String == "notify")
        #expect((echo["response"] as? [String: Any])?.isEmpty == true)
        
        #expect(await start.value.failure == nil)
    }
    
    @Test
    func startFailsWhenTheDriverStopsFirst() async {
        let bridge = makeBridge()
        let start = Task { await bridge.start() }
        channel.close()
        #expect(await start.value.failure == .notRunning)
    }
    
    @Test
    func startTimesOutWithoutNegotiation() async {
        let bridge = makeBridge(requestTimeout: .milliseconds(50))
        #expect(await bridge.start().failure == .notRunning)
    }
    
    // MARK: - Driver requests
    
    @Test
    func everyDriverRequestIsEchoedOnce() async throws {
        let bridge = try await negotiated(makeBridge())
        for (index, action) in ["update_state", "send_event", "send_to_device", "openid_credentials", "something_new"].enumerated() {
            channel.push(toWidget(action: action, requestID: "req\(index)", data: ["state": []]))
            let echo = try await nextSent()
            #expect(echo["requestId"] as? String == "req\(index)")
            #expect(echo["action"] as? String == action)
            #expect((echo["response"] as? [String: Any])?.isEmpty == true)
        }
        _ = bridge
    }
    
    @Test
    func messagesForAnotherWidgetAreIgnored() async throws {
        let bridge = try await negotiated(makeBridge())
        var stranger = toWidget(action: "update_state", requestID: "other", data: ["state": [stateEvent(key: "@x", eventID: "$x")]])
        stranger["widgetId"] = "someone-else"
        channel.push(stranger)
        channel.push(toWidget(action: "openid_credentials", requestID: "mine"))
        let echo = try await nextSent()
        #expect(echo["requestId"] as? String == "mine")
        _ = bridge
    }
    
    // MARK: - State
    
    @Test
    func stateDeltasBecomeFullSnapshots() async throws {
        let bridge = try await negotiated(makeBridge())
        var snapshots = bridge.stateEvents(eventType: "org.matrix.msc3401.call.member").makeAsyncIterator()
        
        channel.push(toWidget(action: "update_state", requestID: "s1", data: ["state": [stateEvent(key: "@alice", eventID: "$a1", content: ["v": 1]),
                                                                                        stateEvent(key: "@bob", eventID: "$b1")]]))
        _ = try await nextSent()
        let first = try #require(await snapshots.next())
        #expect(first.count == 2)
        
        // Timeline-borne state for one member replaces that member only.
        var change = stateEvent(key: "@alice", eventID: "$a2", content: ["v": 2])
        change["room_id"] = "!room:example.org"
        channel.push(toWidget(action: "send_event", requestID: "s2", data: change))
        _ = try await nextSent()
        let second = try #require(await snapshots.next())
        #expect(second.count == 2)
        #expect(second.first { $0.stateKey == "@alice" }?.eventID == "$a2")
        #expect(second.first { $0.stateKey == "@alice" }?.contentJSON == #"{"v":2}"#)
        #expect(second.first { $0.stateKey == "@bob" }?.eventID == "$b1")
        
        // The same change through the other route is not a new emission; a leave is a present `{}`.
        channel.push(toWidget(action: "update_state", requestID: "s3", data: ["state": [change]]))
        _ = try await nextSent()
        channel.push(toWidget(action: "update_state", requestID: "s4", data: ["state": [stateEvent(key: "@bob", eventID: "$b2", content: [:])]]))
        _ = try await nextSent()
        let third = try #require(await snapshots.next())
        #expect(third.count == 2)
        #expect(third.first { $0.stateKey == "@bob" }?.contentJSON == "{}")
        #expect(third.first { $0.stateKey == "@bob" }?.originServerTimestamp == Date(timeIntervalSince1970: 1.7))
    }
    
    @Test
    func lateSubscriberGetsTheCurrentStateAndEmptyStateIsNeverEmitted() async throws {
        let bridge = try await negotiated(makeBridge())
        channel.push(toWidget(action: "update_state", requestID: "empty", data: ["state": []]))
        _ = try await nextSent()
        channel.push(toWidget(action: "update_state", requestID: "s1", data: ["state": [stateEvent(key: "@alice", eventID: "$a1")]]))
        _ = try await nextSent()
        
        var late = bridge.stateEvents(eventType: "org.matrix.msc3401.call.member").makeAsyncIterator()
        let snapshot = try #require(await late.next())
        #expect(snapshot.map(\.stateKey) == ["@alice"])
        
        var other = bridge.stateEvents(eventType: "m.room.name").makeAsyncIterator()
        channel.push(toWidget(action: "update_state", requestID: "s2", data: ["state": [stateEvent(key: "@bob", eventID: "$b1")]]))
        _ = try await nextSent()
        // Only the subscribed type is fed; the name feed stays silent.
        let next = try #require(await late.next())
        #expect(next.count == 2)
        await bridge.stop()
        #expect(await other.next() == nil)
    }
    
    // MARK: - To-device
    
    @Test
    func toDeviceMessagesAreTrustedWhenEncrypted() async throws {
        let bridge = try await negotiated(makeBridge())
        var messages = bridge.toDeviceMessages().makeAsyncIterator()
        channel.push(toWidget(action: "send_to_device", requestID: "td", data: ["type": "io.element.call.encryption_keys",
                                                                                "sender": "@bob:example.org",
                                                                                "encrypted": true,
                                                                                "content": ["device_id": "BOBDEVICE", "keys": [["index": 0, "key": "k"]]]]))
        _ = try await nextSent()
        let message = try #require(await messages.next())
        #expect(message.eventType == "io.element.call.encryption_keys")
        #expect(message.attestedSenderID == "@bob:example.org")
        #expect(message.senderDeviceID == "BOBDEVICE")
        #expect(message.wasEncrypted)
        #expect(message.isSenderCrossSigned)
        #expect(message.contentJSON.contains(#""device_id":"BOBDEVICE""#))
        
        // The current Element Call shape puts the device inside `member`.
        channel.push(toWidget(action: "send_to_device", requestID: "claimed", data: ["type": "io.element.call.encryption_keys",
                                                                                     "sender": "@bob:example.org",
                                                                                     "encrypted": true,
                                                                                     "content": ["member": ["id": "@bob:example.org:BOBDEVICE", "claimed_device_id": "BOBDEVICE"],
                                                                                                 "keys": [["index": 0, "key": "k"]]]]))
        _ = try await nextSent()
        #expect(try #require(await messages.next()).senderDeviceID == "BOBDEVICE")
        
        channel.push(toWidget(action: "send_to_device", requestID: "clear", data: ["type": "io.element.call.encryption_keys",
                                                                                   "sender": "@bob:example.org",
                                                                                   "encrypted": false,
                                                                                   "content": [String: Any]()]))
        _ = try await nextSent()
        let cleartext = try #require(await messages.next())
        #expect(!cleartext.wasEncrypted)
        #expect(!cleartext.isSenderCrossSigned)
        #expect(cleartext.senderDeviceID == nil)
    }
    
    @Test
    func senderDeviceIsInferredFromTheMembershipWhenTheKeyNamesNone() async throws {
        let bridge = try await negotiated(makeBridge())
        var messages = bridge.toDeviceMessages().makeAsyncIterator()
        var membership = stateEvent(key: "_@bob:example.org_BOBDEVICE_m.call", eventID: "$m", content: ["memberships": [["device_id": "BOBDEVICE", "application": "m.call"]]])
        membership["sender"] = "@bob:example.org"
        var bare = stateEvent(key: "_@carol:example.org_CARDEV_m.call", eventID: "$c", content: ["memberships": []])
        bare["sender"] = "@carol:example.org"
        channel.push(toWidget(action: "update_state", requestID: "s", data: ["state": [membership, bare]]))
        _ = try await nextSent()
        
        for sender in ["@bob:example.org", "@carol:example.org", "@dave:example.org"] {
            channel.push(toWidget(action: "send_to_device", requestID: sender, data: ["type": "io.element.call.encryption_keys",
                                                                                      "sender": sender,
                                                                                      "encrypted": true,
                                                                                      "content": ["keys": [["index": 0, "key": "k"]]]]))
            _ = try await nextSent()
        }
        #expect(try #require(await messages.next()).senderDeviceID == "BOBDEVICE")
        #expect(try #require(await messages.next()).senderDeviceID == "CARDEV")
        #expect(try #require(await messages.next()).senderDeviceID == nil)
    }
    
    @Test
    func requestsPutTheActionBeforeTheData() async throws {
        let bridge = try await negotiated(makeBridge())
        let send = Task { await bridge.sendRoomEvent(eventType: "m.reaction", contentJSON: "{}") }
        let raw = try #require(await channel.nextSent())
        let actionIndex = try #require(raw.range(of: #""action""#)?.lowerBound)
        let dataIndex = try #require(raw.range(of: #""data""#)?.lowerBound)
        #expect(actionIndex < dataIndex)
        try channel.push(response(to: #require(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any]), ["event_id": "$e"]))
        #expect(await send.value == .success("$e"))
    }
    
    // MARK: - Our requests
    
    @Test
    func delayedStateEventReturnsTheDelayID() async throws {
        let bridge = try await negotiated(makeBridge())
        let send = Task { await bridge.sendDelayedEvent(eventType: "org.matrix.msc3401.call.member", stateKey: "_@a_DEV", contentJSON: #"{"memberships":[]}"#, delayMs: 8000) }
        let request = try await nextSent()
        #expect(request["api"] as? String == "fromWidget")
        #expect(request["action"] as? String == "send_event")
        let data = try #require(request["data"] as? [String: Any])
        #expect(data["type"] as? String == "org.matrix.msc3401.call.member")
        #expect(data["state_key"] as? String == "_@a_DEV")
        #expect(data["delay"] as? Int == 8000)
        #expect((data["content"] as? [String: Any])?["memberships"] is [Any])
        
        channel.push(response(to: request, ["room_id": "!room:example.org", "delay_id": "syd_abc"]))
        #expect(await send.value == .success("syd_abc"))
    }
    
    @Test
    func roomEventReturnsTheEventIDAndAnUnexpectedShapeIsAnError() async throws {
        let bridge = try await negotiated(makeBridge())
        let send = Task { await bridge.sendRoomEvent(eventType: "m.reaction", contentJSON: "{}") }
        let request = try await nextSent()
        #expect((request["data"] as? [String: Any])?["state_key"] == nil)
        channel.push(response(to: request, ["room_id": "!room:example.org", "event_id": "$ev"]))
        #expect(await send.value == .success("$ev"))
        
        let delayed = Task { await bridge.sendDelayedEvent(eventType: "m.reaction", stateKey: nil, contentJSON: "{}", delayMs: 1) }
        let delayedRequest = try await nextSent()
        channel.push(response(to: delayedRequest, ["room_id": "!room:example.org", "event_id": "$oops"]))
        #expect(await delayed.value == .failure(.invalidResponse("no delay_id in the send_event response")))
    }
    
    @Test
    func updateDelayedEventSendsTheAction() async throws {
        let bridge = try await negotiated(makeBridge())
        let update = Task { await bridge.updateDelayedEvent(delayID: "syd", action: .restart) }
        let request = try await nextSent()
        #expect(request["action"] as? String == "org.matrix.msc4157.update_delayed_event")
        #expect((request["data"] as? [String: Any])?["action"] as? String == "restart")
        #expect((request["data"] as? [String: Any])?["delay_id"] as? String == "syd")
        channel.push(response(to: request, [:]))
        #expect(await update.value.failure == nil)
    }
    
    @Test
    func toDeviceSendReportsFailuresPerRecipient() async throws {
        let bridge = try await negotiated(makeBridge())
        let send = Task {
            await bridge.sendToDeviceMessage(eventType: "io.element.call.encryption_keys",
                                             messages: ["@bob:example.org": ["DEV1": #"{"k":1}"#, "DEV2": #"{"k":1}"#]])
        }
        let request = try await nextSent()
        let messages = try #require((request["data"] as? [String: Any])?["messages"] as? [String: [String: [String: Any]]])
        #expect(messages["@bob:example.org"]?["DEV1"]?["k"] as? Int == 1)
        channel.push(response(to: request, ["failures": ["@bob:example.org": ["DEV2"]]]))
        #expect(await send.value == .success(["@bob:example.org": ["DEV2"]]))
        
        let clean = Task { await bridge.sendToDeviceMessage(eventType: "t", messages: [:]) }
        try await channel.push(response(to: nextSent(), [:]))
        #expect(await clean.value == .success([:]))
    }
    
    @Test
    func homeserverErrorsCarryTheErrcode() async throws {
        let bridge = try await negotiated(makeBridge())
        let send = Task { await bridge.sendDelayedEvent(eventType: "t", stateKey: "k", contentJSON: "{}", delayMs: 1) }
        let request = try await nextSent()
        channel.push(response(to: request, error: ["message": "Sending delayed events has been disallowed",
                                                   "matrix_api_error": ["http_status": 403,
                                                                        "response": ["errcode": "M_FORBIDDEN", "error": "Sending delayed events has been disallowed"]]]))
        #expect(await send.value == .failure(.matrixAPI(errcode: "M_FORBIDDEN", httpStatus: 403, message: "Sending delayed events has been disallowed")))
        
        let denied = Task { await bridge.sendRoomEvent(eventType: "t", contentJSON: "{}") }
        try await channel.push(response(to: nextSent(), error: ["message": "Not allowed"]))
        #expect(await denied.value == .failure(.matrixAPI(errcode: nil, httpStatus: nil, message: "Not allowed")))
    }
    
    @Test
    func unansweredRequestsTimeOut() async throws {
        let bridge = try await negotiated(makeBridge(requestTimeout: .milliseconds(50)))
        let send = Task { await bridge.sendRoomEvent(eventType: "t", contentJSON: "{}") }
        _ = try await nextSent()
        #expect(await send.value == .failure(.timedOut))
    }
    
    @Test
    func aDyingDriverFailsWhatIsInFlight() async throws {
        let bridge = try await negotiated(makeBridge())
        var messages = bridge.toDeviceMessages().makeAsyncIterator()
        let send = Task { await bridge.sendRoomEvent(eventType: "t", contentJSON: "{}") }
        _ = try await nextSent()
        channel.close()
        #expect(await send.value == .failure(.notRunning))
        #expect(await messages.next() == nil)
    }
    
    // MARK: - Stop
    
    @Test
    func stopPokesTheDriverAndStopsServing() async throws {
        let bridge = try await negotiated(makeBridge())
        var snapshots = bridge.stateEvents(eventType: "org.matrix.msc3401.call.member").makeAsyncIterator()
        await bridge.stop()
        let poke = try await nextSent()
        #expect(poke["action"] as? String == "supported_api_versions")
        #expect(poke["api"] as? String == "fromWidget")
        #expect(await snapshots.next() == nil)
        #expect(await bridge.sendRoomEvent(eventType: "t", contentJSON: "{}") == .failure(.notRunning))
        
        // The poke's answer is the last thing received; the pipe is then left alone.
        channel.push(response(to: poke, ["supported_versions": []]))
        channel.push(toWidget(action: "update_state", requestID: "late", data: ["state": []]))
        #expect(channel.unreadCount() == 1)
    }
    
    // MARK: - Helpers
    
    private func negotiated(_ bridge: WidgetMatrixBridge) async throws -> WidgetMatrixBridge {
        let start = Task { await bridge.start() }
        channel.push(toWidget(action: "capabilities", requestID: "cap"))
        _ = try await nextSent()
        channel.push(toWidget(action: "notify_capabilities", requestID: "notify", data: ["requested": [], "approved": WidgetCapabilityGrant.capabilityStrings]))
        _ = try await nextSent()
        try #require(await start.value.failure == nil)
        return bridge
    }
    
    private func nextSent() async throws -> [String: Any] {
        let raw = try #require(await channel.nextSent())
        return try #require(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
    }
    
    private func toWidget(action: String, requestID: String, data: [String: Any] = [:]) -> [String: Any] {
        ["api": "toWidget", "widgetId": widgetID, "requestId": requestID, "action": action, "data": data]
    }
    
    private func response(to request: [String: Any], _ response: [String: Any]) -> [String: Any] {
        var message = request
        message["response"] = response
        return message
    }
    
    private func response(to request: [String: Any], error: [String: Any]) -> [String: Any] {
        response(to: request, ["error": error])
    }
    
    private func stateEvent(key: String, eventID: String, content: [String: Any] = ["memberships": []]) -> [String: Any] {
        ["type": "org.matrix.msc3401.call.member",
         "state_key": key,
         "sender": "@sender:example.org",
         "event_id": eventID,
         "origin_server_ts": 1700,
         "content": content]
    }
}

/// A driver pipe the test drives by hand: `push` is what the driver would say, `nextSent` what the bridge said.
private final nonisolated class FakeWidgetChannel: WidgetDriverChannel, Sendable {
    /// A queue with waiting readers; `nil` is delivered once closed.
    private final class Pipe: Sendable {
        private struct State {
            var queue = [String]()
            var waiters = [CheckedContinuation<String?, Never>]()
            var isOpen = true
        }
        
        private let state = Mutex(State())
        
        func write(_ message: String) {
            let waiter = state.withLock { state -> CheckedContinuation<String?, Never>? in
                if state.waiters.isEmpty {
                    state.queue.append(message)
                    return nil
                }
                return state.waiters.removeFirst()
            }
            waiter?.resume(returning: message)
        }
        
        func close() {
            let waiters = state.withLock { state in
                state.isOpen = false
                defer { state.waiters.removeAll() }
                return state.waiters
            }
            waiters.forEach { $0.resume(returning: nil) }
        }
        
        var isOpen: Bool {
            state.withLock { $0.isOpen }
        }
        
        var unreadCount: Int {
            state.withLock { $0.queue.count }
        }
        
        func read() async -> String? {
            await withCheckedContinuation { continuation in
                let ready = state.withLock { state -> String?? in
                    if !state.queue.isEmpty {
                        return .some(state.queue.removeFirst())
                    }
                    if !state.isOpen {
                        return .some(nil)
                    }
                    state.waiters.append(continuation)
                    return nil
                }
                if let ready {
                    continuation.resume(returning: ready)
                }
            }
        }
    }
    
    private let toBridge = Pipe()
    private let fromBridge = Pipe()
    
    func push(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message), let raw = String(data: data, encoding: .utf8) else {
            fatalError("Test message is not JSON")
        }
        toBridge.write(raw)
    }
    
    func close() {
        toBridge.close()
    }
    
    /// The next message the bridge sent.
    func nextSent() async -> String? {
        await fromBridge.read()
    }
    
    /// Messages the bridge has not asked for; only meaningful once it stopped receiving.
    func unreadCount() -> Int {
        toBridge.unreadCount
    }
    
    func recv() async -> String? {
        await toBridge.read()
    }
    
    func send(msg: String) async -> Bool {
        fromBridge.write(msg)
        return toBridge.isOpen
    }
}

private extension Result {
    var failure: Failure? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}
