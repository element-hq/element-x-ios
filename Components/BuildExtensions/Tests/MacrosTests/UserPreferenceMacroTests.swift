//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MacrosImplementation
import SwiftSyntaxMacrosTestSupport
import XCTest

final class UserPreferenceMacroTests: XCTestCase {
    private let macros = ["UserPreference": UserPreferenceMacro.self]
    
    func testKeyDefaultsToPropertyName() {
        assertMacroExpansion("""
                             @UserPreference(defaultValue: true)
                             var hasSeenNewSoundBanner: Bool
                             """,
                             expandedSource:
                             """
                             var hasSeenNewSoundBanner: Bool {
                                 get {
                                     store["hasSeenNewSoundBanner"] ?? true
                                 }
                                 set {
                                     store["hasSeenNewSoundBanner"] = newValue
                                     _hasSeenNewSoundBannerSubject.send(newValue)
                                 }
                             }
                             
                             private let _hasSeenNewSoundBannerSubject = PassthroughSubject<Bool, Never>()
                             
                             var hasSeenNewSoundBannerPublisher: AnyPublisher<Bool, Never> {
                                 _hasSeenNewSoundBannerSubject.prepend(hasSeenNewSoundBanner).eraseToAnyPublisher()
                             }
                             
                             func resetHasSeenNewSoundBanner() {
                                 store.removeObject(forKey: "hasSeenNewSoundBanner")
                             }
                             """,
                             macros: macros)
    }
    
    func testExplicitKey() {
        assertMacroExpansion("""
                             @UserPreference(key: "liveLocationSharingTimeoutDatesByRoomID", defaultValue: [String: LiveLocationSession]())
                             var liveLocationSharingSessionsByRoomID: [String: LiveLocationSession]
                             """,
                             expandedSource:
                             """
                             var liveLocationSharingSessionsByRoomID: [String: LiveLocationSession] {
                                 get {
                                     store["liveLocationSharingTimeoutDatesByRoomID"] ?? [String: LiveLocationSession]()
                                 }
                                 set {
                                     store["liveLocationSharingTimeoutDatesByRoomID"] = newValue
                                     _liveLocationSharingSessionsByRoomIDSubject.send(newValue)
                                 }
                             }
                             
                             private let _liveLocationSharingSessionsByRoomIDSubject = PassthroughSubject<[String: LiveLocationSession], Never>()
                             
                             var liveLocationSharingSessionsByRoomIDPublisher: AnyPublisher<[String: LiveLocationSession], Never> {
                                 _liveLocationSharingSessionsByRoomIDSubject.prepend(liveLocationSharingSessionsByRoomID).eraseToAnyPublisher()
                             }
                             
                             func resetLiveLocationSharingSessionsByRoomID() {
                                 store.removeObject(forKey: "liveLocationSharingTimeoutDatesByRoomID")
                             }
                             """,
                             macros: macros)
    }
    
    func testOptionalWithoutDefault() {
        assertMacroExpansion("""
                             @UserPreference
                             var pusherProfileTag: String?
                             """,
                             expandedSource:
                             """
                             var pusherProfileTag: String? {
                                 get {
                                     store["pusherProfileTag"]
                                 }
                                 set {
                                     store["pusherProfileTag"] = newValue
                                     _pusherProfileTagSubject.send(newValue)
                                 }
                             }
                             
                             private let _pusherProfileTagSubject = PassthroughSubject<String?, Never>()
                             
                             var pusherProfileTagPublisher: AnyPublisher<String?, Never> {
                                 _pusherProfileTagSubject.prepend(pusherProfileTag).eraseToAnyPublisher()
                             }
                             
                             func resetPusherProfileTag() {
                                 store.removeObject(forKey: "pusherProfileTag")
                             }
                             """,
                             macros: macros)
    }
    
    func testBinaryExpressionDefaultIsParenthesised() {
        assertMacroExpansion("""
                             @UserPreference(defaultValue: Self.appBuildType == .debug)
                             var viewSourceEnabled: Bool
                             """,
                             expandedSource:
                             """
                             var viewSourceEnabled: Bool {
                                 get {
                                     store["viewSourceEnabled"] ?? (Self.appBuildType == .debug)
                                 }
                                 set {
                                     store["viewSourceEnabled"] = newValue
                                     _viewSourceEnabledSubject.send(newValue)
                                 }
                             }
                             
                             private let _viewSourceEnabledSubject = PassthroughSubject<Bool, Never>()
                             
                             var viewSourceEnabledPublisher: AnyPublisher<Bool, Never> {
                                 _viewSourceEnabledSubject.prepend(viewSourceEnabled).eraseToAnyPublisher()
                             }
                             
                             func resetViewSourceEnabled() {
                                 store.removeObject(forKey: "viewSourceEnabled")
                             }
                             """,
                             macros: macros)
    }
    
    func testVolatileStorage() {
        assertMacroExpansion("""
                             @UserPreference(defaultValue: false, volatile: true)
                             var clientPausingAndResumingEnabled: Bool
                             """,
                             expandedSource:
                             """
                             var clientPausingAndResumingEnabled: Bool {
                                 get {
                                     _clientPausingAndResumingEnabledVolatileValue
                                 }
                                 set {
                                     _clientPausingAndResumingEnabledVolatileValue = newValue
                                     _clientPausingAndResumingEnabledSubject.send(newValue)
                                 }
                             }
                             
                             private var _clientPausingAndResumingEnabledVolatileValue: Bool = false
                             
                             private let _clientPausingAndResumingEnabledSubject = PassthroughSubject<Bool, Never>()
                             
                             var clientPausingAndResumingEnabledPublisher: AnyPublisher<Bool, Never> {
                                 _clientPausingAndResumingEnabledSubject.prepend(clientPausingAndResumingEnabled).eraseToAnyPublisher()
                             }
                             
                             func resetClientPausingAndResumingEnabled() {
                                 _clientPausingAndResumingEnabledVolatileValue = false
                             }
                             """,
                             macros: macros)
    }
}
