//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
@testable import ElementX
import Foundation
import MatrixRustSDK
import Testing

struct SDKMappingsTests {
    // MARK: Events
    
    @Test
    func stateIsReportedUnderTheSubscribedSpelling() throws {
        let event = RoomStateEvent(eventType: stateEventTypeFromString(s: "org.matrix.msc3401.call.member"),
                                   stateKey: "_@bob:example.org_DEV",
                                   sender: "@bob:example.org",
                                   contentJson: #"{"application":"m.call"}"#,
                                   eventId: "$member",
                                   timestamp: 1234)
        
        let mappedEvent = try #require(SDKMappings.event(event, subscribedAs: "m.call.member"))
        
        #expect(mappedEvent.eventType == "m.call.member")
        #expect(mappedEvent.eventID == "$member")
        #expect(mappedEvent.stateKey == "_@bob:example.org_DEV")
        #expect(mappedEvent.originServerTimestamp == Date(timeIntervalSince1970: 1.234))
        #expect(mappedEvent.contentJSON == #"{"application":"m.call"}"#)
        #expect(mappedEvent.encryption == .cleartext)
    }
    
    @Test
    func strippedStateIsDropped() {
        let event = RoomStateEvent(eventType: stateEventTypeFromString(s: "m.call.member"),
                                   stateKey: "",
                                   sender: "@bob:example.org",
                                   contentJson: "{}",
                                   eventId: nil,
                                   timestamp: nil)
        
        #expect(SDKMappings.event(event, subscribedAs: "m.call.member") == nil)
    }
    
    @Test
    func messageLikeEventsCarryTheirEncryption() {
        let event = RoomMessageLikeEvent(eventType: messageLikeEventTypeFromString(s: "m.reaction"),
                                         eventId: "$hand",
                                         sender: "@bob:example.org",
                                         timestamp: 99,
                                         contentJson: "{}",
                                         encryptionInfo: encryptionInfo(senderID: "@bob:example.org", shield: .none))
        
        let mappedEvent = SDKMappings.event(event, subscribedAs: "m.reaction")
        
        #expect(mappedEvent.eventType == "m.reaction")
        #expect(mappedEvent.stateKey == nil)
        #expect(mappedEvent.encryption == .encrypted(senderDeviceID: "BOBDEVICE", isSenderConfirmed: true))
    }
    
    @Test
    func redactsIsReadFromTheContent() {
        #expect(SDKMappings.redactedEventID(fromContent: #"{"redacts":"$hand","reason":"lowered"}"#) == "$hand")
        // Before room version 11 `redacts` sat beside the content, which the SDK does not hand over.
        #expect(SDKMappings.redactedEventID(fromContent: #"{"reason":"lowered"}"#) == nil)
        #expect(SDKMappings.redactedEventID(fromContent: "not json") == nil)
    }
    
    // MARK: Trust
    
    @Test
    func aSenderIsConfirmedUnlessItsShieldIsRed() {
        #expect(SDKMappings.encryption(encryptionInfo(senderID: "@bob:example.org", shield: .none)) == .encrypted(senderDeviceID: "BOBDEVICE", isSenderConfirmed: true))
        #expect(SDKMappings.encryption(encryptionInfo(senderID: "@bob:example.org", shield: .grey(code: .authenticityNotGuaranteed))) == .encrypted(senderDeviceID: "BOBDEVICE", isSenderConfirmed: true))
        #expect(SDKMappings.encryption(encryptionInfo(senderID: "@bob:example.org", shield: .red(code: .unknownDevice))) == .encrypted(senderDeviceID: "BOBDEVICE", isSenderConfirmed: false))
    }
    
    @Test
    func noEncryptionInfoIsCleartext() {
        #expect(SDKMappings.encryption(nil) == .cleartext)
    }
    
    @Test
    func anUnknownEncryptionStateIsNeverAGuess() {
        #expect(SDKMappings.isEncrypted(.encrypted) == true)
        #expect(SDKMappings.isEncrypted(.notEncrypted) == false)
        #expect(SDKMappings.isEncrypted(.unknown) == nil)
    }
    
    // MARK: Members
    
    @Test
    func membersAreComparedWholeAndNeverDeliveredEmpty() {
        #expect(SDKMappings.shouldDeliver(["@a:x", "@b:x"], lastDelivered: nil))
        #expect(!SDKMappings.shouldDeliver(["@a:x", "@b:x"], lastDelivered: ["@a:x", "@b:x"]))
        // One leaving as another joins keeps the count.
        #expect(SDKMappings.shouldDeliver(["@a:x", "@c:x"], lastDelivered: ["@a:x", "@b:x"]))
        #expect(!SDKMappings.shouldDeliver([], lastDelivered: nil))
    }
    
    // MARK: To-device
    
    @Test
    func anEncryptedMessageComesFromItsAttestedSender() {
        let message = ToDeviceMessage(eventType: "io.element.call.encryption_keys",
                                      senderId: "@mallory:example.org",
                                      content: "{}",
                                      encryptionInfo: encryptionInfo(senderID: "@bob:example.org", shield: .none))
        
        let mappedMessage = SDKMappings.toDeviceMessage(message)
        
        #expect(mappedMessage.sender == "@bob:example.org")
        #expect(mappedMessage.encryption == .encrypted(senderDeviceID: "BOBDEVICE", isSenderConfirmed: true))
    }
    
    @Test
    func aCleartextMessageKeepsItsClaimedSender() {
        let message = ToDeviceMessage(eventType: "io.element.call.encryption_keys", senderId: "@bob:example.org", content: "{}", encryptionInfo: nil)
        
        let mappedMessage = SDKMappings.toDeviceMessage(message)
        
        #expect(mappedMessage.sender == "@bob:example.org")
        #expect(mappedMessage.encryption == .cleartext)
    }
    
    @Test
    func onlyTheFailedRecipientsAreUndelivered() {
        let recipients = [ElementCallDevice(userID: "@bob:x", deviceID: "B1"),
                          ElementCallDevice(userID: "@bob:x", deviceID: "B2"),
                          ElementCallDevice(userID: "@carol:x", deviceID: "C1")]
        
        let undelivered = SDKMappings.undelivered(recipients, failures: ["@bob:x": ["B2"]])
        
        #expect(Set(undelivered.keys) == [ElementCallDevice(userID: "@bob:x", deviceID: "B2")])
    }
    
    // MARK: Transports and failures
    
    @Test
    func transportsAreRebuiltAsTheMSC4143Array() throws {
        let json = SDKMappings.transportsJSON([.liveKit(url: nil, serviceUrl: "https://sfu.example.org"),
                                               .custom(transportType: "other", data: #"{"url":"https://other.example.org"}"#)])
        
        let array = try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: String]])
        #expect(array == [["type": "livekit", "livekit_service_url": "https://sfu.example.org"],
                          ["type": "other", "url": "https://other.example.org"]])
        #expect(SDKMappings.transportsJSON([]) == "[]")
    }
    
    @Test
    func aHomeserverRefusalKeepsItsErrorCode() {
        let error = SDKMappings.backendError(ClientError.MatrixApi(kind: .forbidden, code: "M_FORBIDDEN", msg: "no", details: nil))
        
        #expect(error.errorCode == "M_FORBIDDEN")
        #expect(error.statusCode == nil)
        #expect(error.retryAfter == nil)
        // The core classifies on the code; the mark is only for a final failure with none.
        #expect(!error.isPermanent)
    }
    
    @Test
    func aRateLimitCarriesTheServersDelay() {
        let error = SDKMappings.backendError(ClientError.MatrixApi(kind: .limitExceeded(retryAfterMs: 7000), code: "M_LIMIT_EXCEEDED", msg: "slow down", details: nil))
        
        #expect(error.errorCode == "M_LIMIT_EXCEEDED")
        #expect(error.retryAfter == .seconds(7))
        #expect(!error.isPermanent)
    }
    
    @Test
    func aFailureWithNoCodeIsLeftForTheCoreToRetry() {
        struct Offline: Error { }
        
        let error = SDKMappings.backendError(Offline())
        
        #expect(error.errorCode == nil)
        #expect(error.retryAfter == nil)
        #expect(!error.isPermanent)
    }
    
    // MARK: Sticky events
    
    @Test
    func stickyUpdatesFoldIntoTheWholeSet() {
        var set = SDKStickyEventSet()
        let alice = stickyEvent(sender: "@alice:x", id: "$a1")
        let bob = stickyEvent(sender: "@bob:x", id: "$b1")
        
        #expect(set.apply(.reset(events: [])).isEmpty)
        #expect(set.apply(.reset(events: [alice, bob])).map(\.eventID) == ["$a1", "$b1"])
        
        let aliceAgain = stickyEvent(sender: "@alice:x", id: "$a2")
        #expect(set.apply(.changes(added: [], updated: [aliceAgain], removed: [])).map(\.eventID) == ["$a2", "$b1"])
        
        let removal = StickyEventRemoval(key: bob.key, reason: .expired)
        #expect(set.apply(.changes(added: [], updated: [], removed: [removal])).map(\.eventID) == ["$a2"])
    }
    
    @Test
    func aStickyEventIsReportedWithItsWireTypeAndContent() throws {
        let mappedEvent = try #require(SDKMappings.event(stickyEvent(sender: "@alice:x", id: "$a1")))
        
        #expect(mappedEvent.eventType == "org.matrix.msc4143.rtc.member")
        #expect(mappedEvent.sender == "@alice:x")
        #expect(mappedEvent.originServerTimestamp == Date(timeIntervalSince1970: 0.042))
        #expect(mappedEvent.contentJSON == #"{"slot_id":"m.call#ROOM"}"#)
    }
    
    // MARK: - Fixtures
    
    private func encryptionInfo(senderID: String, shield: ShieldState) -> EventEncryptionInfo {
        EventEncryptionInfo(senderId: senderID,
                            senderDeviceId: "BOBDEVICE",
                            senderCurve25519Key: nil,
                            sessionId: nil,
                            shieldState: shield,
                            shieldStateStrict: shield)
    }
    
    private func stickyEvent(sender: String, id: String) -> StickyEvent {
        let json = #"{"type":"org.matrix.msc4143.rtc.member","origin_server_ts":42,"content":{"slot_id":"m.call#ROOM"}}"#
        return StickyEvent(key: StickyKey(sender: sender, eventType: "m.rtc.member", stickyKey: "\(sender)_DEV"),
                           eventId: id,
                           expiresAtMs: 0,
                           eventJson: json,
                           encryptionInfo: nil)
    }
}
