//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import MacrosImplementation
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct UserPreferenceMacroTests {
    private let macroSpecs = ["UserPreference": MacroSpec(type: UserPreferenceMacro.self)]
    
    @Test("The storage key defaults to the property name when no key is given")
    func defaultKey() {
        assertExpansion("""
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
                        
                        var hasSeenNewSoundBannerKey: UserPreferenceKey {
                            .init("hasSeenNewSoundBanner")
                        }
                        
                        func resetHasSeenNewSoundBanner() {
                            store.removeObject(forKey: "hasSeenNewSoundBanner")
                        }
                        """)
    }
    
    @Test("An explicit key is used for storage instead of the property name")
    func explicitKey() {
        assertExpansion("""
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
                        
                        var liveLocationSharingSessionsByRoomIDKey: UserPreferenceKey {
                            .init("liveLocationSharingTimeoutDatesByRoomID")
                        }
                        
                        func resetLiveLocationSharingSessionsByRoomID() {
                            store.removeObject(forKey: "liveLocationSharingTimeoutDatesByRoomID")
                        }
                        """)
    }
    
    @Test("An optional without a default value reads from the store with no fallback")
    func optionalWithoutDefault() {
        assertExpansion("""
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
                        
                        var pusherProfileTagKey: UserPreferenceKey {
                            .init("pusherProfileTag")
                        }
                        
                        func resetPusherProfileTag() {
                            store.removeObject(forKey: "pusherProfileTag")
                        }
                        """)
    }
    
    @Test("A binary expression default value is wrapped in parentheses")
    func binaryExpressionDefault() {
        assertExpansion("""
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
                        
                        var viewSourceEnabledKey: UserPreferenceKey {
                            .init("viewSourceEnabled")
                        }
                        
                        func resetViewSourceEnabled() {
                            store.removeObject(forKey: "viewSourceEnabled")
                        }
                        """)
    }
    
    @Test("Volatile storage keeps the value in memory instead of the store")
    func volatileStorage() {
        assertExpansion("""
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
                        """)
    }
    
    // MARK: - Helpers
    
    private func assertExpansion(_ originalSource: String,
                                 expandedSource: String,
                                 fileID: StaticString = #fileID,
                                 filePath: StaticString = #filePath,
                                 line: UInt = #line,
                                 column: UInt = #column) {
        assertMacroExpansion(originalSource,
                             expandedSource: expandedSource,
                             macroSpecs: macroSpecs,
                             failureHandler: { failure in
                                 Issue.record(Comment(rawValue: failure.message),
                                              sourceLocation: SourceLocation(fileID: failure.location.fileID,
                                                                             filePath: failure.location.filePath,
                                                                             line: failure.location.line,
                                                                             column: failure.location.column))
                             },
                             fileID: fileID,
                             filePath: filePath,
                             line: line,
                             column: column)
    }
}
