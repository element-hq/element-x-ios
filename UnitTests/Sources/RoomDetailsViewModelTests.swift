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

import MatrixRustSDK
import SwiftUI
import XCTest

@testable import ElementX

@MainActor
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsScreenViewModel!
    var roomProxyMock: RoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var context: RoomDetailsScreenViewModelType.Context { viewModel.context }
    
    override func setUp() {
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", joinedMembersCount: 0))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               appSettings: AppSettings())
        
        AppSettings.reset()
    }
    
    func testLeaveRoomTappedWhenPublic() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        let deferred = deferFulfillment(context.$viewState.collect(2).first())
        context.send(viewAction: .processTapLeave)
        let states = try await deferred.fulfill()
    
        XCTAssertNil(states[0].bindings.leaveRoomAlertItem)
        XCTAssertEqual(states[1].bindings.leaveRoomAlertItem?.state, .public)
        XCTAssertEqual(states[1].bindings.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertSubtitle)
    }
    
    func testLeaveRoomTappedWhenRoomNotPublic() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        let deferred = deferFulfillment(context.$viewState.collect(2).first())
        context.send(viewAction: .processTapLeave)
        let states = try await deferred.fulfill()
        context.send(viewAction: .processTapLeave)
        XCTAssertNil(states[0].bindings.leaveRoomAlertItem)
        XCTAssertEqual(states[1].bindings.leaveRoomAlertItem?.state, .private)
        XCTAssertEqual(states[1].bindings.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertPrivateSubtitle)
    }
    
    func testLeaveRoomTappedWithLessThanTwoMembers() async {
        context.send(viewAction: .processTapLeave)
        XCTAssertEqual(context.leaveRoomAlertItem?.state, .empty)
        XCTAssertEqual(context.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertEmptySubtitle)
    }
    
    func testLeaveRoomSuccess() async {
        let expectation = expectation(description: #function)
        roomProxyMock.leaveRoomClosure = {
            .success(())
        }
        viewModel.callback = { action in
            switch action {
            case .leftRoom:
                break
            default:
                XCTFail("leftRoom expected")
            }
            expectation.fulfill()
        }
        context.send(viewAction: .confirmLeave)
        await fulfillment(of: [expectation])
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
    }
    
    func testLeaveRoomError() async {
        let expectation = expectation(description: #function)
        roomProxyMock.leaveRoomClosure = {
            defer {
                expectation.fulfill()
            }
            return .failure(.failedLeavingRoom)
        }
        context.send(viewAction: .confirmLeave)
        await fulfillment(of: [expectation])
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testInitialDMDetailsState() async {
        let recipient = RoomMemberProxyMock.mockDan
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers, activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
    }
    
    func testIgnoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        recipient.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .success(())
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers, activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        let deferred = deferFulfillment(context.$viewState.map(\.isProcessingIgnoreRequest)
            .removeDuplicates()
            .collect(3).first())
        context.send(viewAction: .ignoreConfirmed)
        
        let states = try await deferred.fulfill()
        XCTAssertEqual(states, [false, true, false])
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
    }
    
    func testIgnoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        recipient.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .failure(.ignoreUserFailed)
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers, activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        let deferred = deferFulfillment(context.$viewState.map(\.isProcessingIgnoreRequest)
            .removeDuplicates()
            .collect(3).first())
        context.send(viewAction: .ignoreConfirmed)
        
        let states = try await deferred.fulfill()
        XCTAssertEqual(states, [false, true, false])
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testUnignoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        recipient.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .success(())
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers, activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        let deferred = deferFulfillment(context.$viewState.map(\.isProcessingIgnoreRequest)
            .removeDuplicates()
            .collect(3).first())
        
        context.send(viewAction: .unignoreConfirmed)
        let states = try await deferred.fulfill()
        XCTAssertEqual(states, [false, true, false])
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
    }
    
    func testUnignoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        recipient.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .failure(.unignoreUserFailed)
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers, activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        let deferred = deferFulfillment(context.$viewState.map(\.isProcessingIgnoreRequest)
            .removeDuplicates()
            .collect(3).first())
        
        context.send(viewAction: .unignoreConfirmed)
        let states = try await deferred.fulfill()
        XCTAssertEqual(states, [false, true, false])
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testCannotInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test",
                                                  isPublic: true,
                                                  members: mockedMembers,
                                                  memberForID: .mockOwner(allowedStateEvents: [], canInviteUsers: false),
                                                  activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canInviteUsers)
    }
    
    func testInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: true, members: mockedMembers, activeMembersCount: mockedMembers.count))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertTrue(context.viewState.canInviteUsers)
        
        var callbackCorrectlyCalled = false
        viewModel.callback = { action in
            switch action {
            case .requestInvitePeoplePresentation:
                callbackCorrectlyCalled = true
            default:
                callbackCorrectlyCalled = false
            }
        }
        
        context.send(viewAction: .processTapInvite)
        await Task.yield()
        XCTAssertTrue(callbackCorrectlyCalled)
    }
        
    func testCanEditAvatar() async {
        let owner: RoomMemberProxyMock = .mockOwner(allowedStateEvents: [.roomAvatar])
        let mockedMembers: [RoomMemberProxyMock] = [owner, .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers, memberForID: owner))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertTrue(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCanEditName() async {
        let owner: RoomMemberProxyMock = .mockOwner(allowedStateEvents: [.roomName])
        let mockedMembers: [RoomMemberProxyMock] = [owner, .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers, memberForID: owner))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertTrue(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCanEditTopic() async {
        let owner: RoomMemberProxyMock = .mockOwner(allowedStateEvents: [.roomTopic])
        let mockedMembers: [RoomMemberProxyMock] = [owner, .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers, memberForID: owner))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertTrue(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCannotEditRoom() async {
        let owner: RoomMemberProxyMock = .mockOwner(allowedStateEvents: [])
        let mockedMembers: [RoomMemberProxyMock] = [owner, .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers, memberForID: owner))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertFalse(context.viewState.canEdit)
    }
    
    func testCannotEditDirectRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]), .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               appSettings: AppSettings())
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEdit)
    }
    
    func testNotificationLoadingSettingsFailure() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomThrowableError = NotificationSettingsError.Generic(message: "error")
        viewModel = RoomDetailsScreenViewModel(accountUserID: "@owner:somewhere.com",
                                               roomProxy: roomProxyMock,
                                               mediaProvider: MockMediaProvider(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               appSettings: AppSettings())
        await context.nextViewState()
        
        XCTAssert(context.viewState.notificationSettingsState.isError)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorLoadingNotificationSettings)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testNotificationDefaultMode() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: true))
        await context.nextViewState()
        XCTAssertEqual(context.viewState.notificationSettingsState.label, "Default")
    }
    
    func testNotificationCustomMode() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
        await context.nextViewState()
        XCTAssertEqual(context.viewState.notificationSettingsState.label, "Custom")
    }
    
    func testNotificationRoomMuted() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mute, isDefault: false))
        await context.nextViewState()
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonUnmute)
        XCTAssertEqual(context.viewState.notificationShortcutButtonImage, Image(systemName: "bell.slash.fill"))
    }
    
    func testNotificationRoomNotMuted() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        await context.nextViewState()
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonMute)
        XCTAssertEqual(context.viewState.notificationShortcutButtonImage, Image(systemName: "bell"))
    }
    
    func testUnmuteTappedFailure() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mute, isDefault: false))
        await context.nextViewState()
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonUnmute)
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.unmuteRoomRoomClosure = { _ in
            defer {
                expectation.fulfill()
            }
            throw NotificationSettingsError.Generic(message: "unmute error")
        }
        context.send(viewAction: .processToogleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonUnmute)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorUnmuting)
        
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testMuteTappedFailure() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
        await context.nextViewState()
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonMute)
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.setNotificationModeRoomModeClosure = { _, _ in
            defer {
                expectation.fulfill()
            }
            throw NotificationSettingsError.Generic(message: "mute error")
        }
        context.send(viewAction: .processToogleMuteNotifications)
        await context.nextViewState()
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonMute)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorMuting)
        
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testMuteTapped() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
        await context.nextViewState()
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.setNotificationModeRoomModeClosure = { [weak notificationSettingsProxyMock] _, mode in
            notificationSettingsProxyMock?.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: mode, isDefault: false))
            expectation.fulfill()
        }
        context.send(viewAction: .processToogleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        await context.nextViewState()
        
        if case .loaded(let newNotificationSettingsState) = viewModel.state.notificationSettingsState {
            XCTAssertFalse(newNotificationSettingsState.isDefault)
            XCTAssertEqual(newNotificationSettingsState.mode, .mute)
        } else {
            XCTFail("invalid state")
        }
    }
    
    func testUnmuteTapped() async {
        notificationSettingsProxyMock.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mute, isDefault: false))
        await context.nextViewState()
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.unmuteRoomRoomClosure = { [weak notificationSettingsProxyMock] _ in
            notificationSettingsProxyMock?.getNotificationSettingsRoomReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
            expectation.fulfill()
        }
        context.send(viewAction: .processToogleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        await context.nextViewState()
        
        if case .loaded(let newNotificationSettingsState) = viewModel.state.notificationSettingsState {
            XCTAssertFalse(newNotificationSettingsState.isDefault)
            XCTAssertEqual(newNotificationSettingsState.mode, .allMessages)
        } else {
            XCTFail("invalid state")
        }
    }
}
