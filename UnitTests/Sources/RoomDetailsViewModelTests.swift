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
import XCTest

@testable import ElementX

@MainActor
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsScreenViewModelProtocol!
    var roomProxyMock: RoomProxyMock!
    var context: RoomDetailsScreenViewModelType.Context { viewModel.context }

    override func setUp() {
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test"))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        AppSettings.reset()
    }

    func testLeaveRoomTappedWhenPublic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        await context.nextViewState()
        context.send(viewAction: .processTapLeave)
        XCTAssertEqual(context.leaveRoomAlertItem?.state, .public)
        XCTAssertEqual(context.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertSubtitle)
    }

    func testLeaveRoomTappedWhenRoomNotPublic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        await context.nextViewState()
        context.send(viewAction: .processTapLeave)
        XCTAssertEqual(context.leaveRoomAlertItem?.state, .private)
        XCTAssertEqual(context.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertPrivateSubtitle)
    }

    func testLeaveRoomTappedWithLessThanTwoMembers() async {
        context.send(viewAction: .processTapLeave)
        XCTAssertEqual(context.leaveRoomAlertItem?.state, .empty)
        XCTAssertEqual(context.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertEmptySubtitle)
    }

    func testLeaveRoomSuccess() async {
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
        }
        context.send(viewAction: .confirmLeave)
        await Task.yield()
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
    }

    func testLeaveRoomError() async {
        roomProxyMock.leaveRoomClosure = {
            .failure(.failedLeavingRoom)
        }
        context.send(viewAction: .confirmLeave)
        await context.nextViewState()
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
        XCTAssertNotNil(context.alertInfo)
    }

    func testInitialDMDetailsState() async {
        let recipient = RoomMemberProxyMock.mockDan
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
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
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .ignoreConfirmed)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == true }
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == false }
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
    }

    func testIgnoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        recipient.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .failure(.ignoreUserFailed)
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .ignoreConfirmed)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == true }
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == false }
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
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
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .unignoreConfirmed)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == true }
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == false }
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
    }

    func testUnignoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        recipient.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(100))
            return .failure(.unignoreUserFailed)
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        await context.nextViewState()
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .unignoreConfirmed)
        
        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == true }
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)

        _ = await context.$viewState.values.first { $0.isProcessingIgnoreRequest == false }
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testCannotInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        await context.nextViewState()
        
        XCTAssertFalse(context.viewState.canInviteUsers)
    }
    
    func testInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        await context.nextViewState()
        
        XCTAssertTrue(context.viewState.canInviteUsers)
        
        var callbackCorrectlyCalled = false
        viewModel.callback = { action in
            switch action {
            case .requestInvitePeoplePresentation(let members):
                callbackCorrectlyCalled = members.map(\.userID) == mockedMembers.map(\.userID)
            default:
                callbackCorrectlyCalled = false
            }
        }
        
        context.send(viewAction: .processTapInvite)
        await Task.yield()
        XCTAssertTrue(callbackCorrectlyCalled)
    }
    
    func testRoomSubscription() async {
        await context.nextViewState()
        XCTAssertEqual(roomProxyMock.registerTimelineListenerIfNeededCallsCount, 1)
    }
    
    func testCanEditAvatar() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockOwner(allowedStateEvents: [.roomAvatar]), .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        _ = await context.$viewState.values.first(where: { !$0.members.isEmpty })
        
        XCTAssertTrue(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCanEditName() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockOwner(allowedStateEvents: [.roomName]), .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        _ = await context.$viewState.values.first(where: { !$0.members.isEmpty })
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertTrue(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCanEditTopic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockOwner(allowedStateEvents: [.roomTopic]), .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        _ = await context.$viewState.values.first(where: { !$0.members.isEmpty })
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertTrue(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCannotEditRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockOwner(allowedStateEvents: []), .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        _ = await context.$viewState.values.first(where: { !$0.members.isEmpty })

        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertFalse(context.viewState.canEdit)
    }
    
    func testCannotEditDirectRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]), .mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        
        _ = await context.$viewState.values.first(where: { !$0.members.isEmpty })

        XCTAssertFalse(context.viewState.canEdit)
    }
}
