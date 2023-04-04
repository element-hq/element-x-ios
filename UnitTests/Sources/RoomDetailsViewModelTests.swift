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
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsViewModelProtocol!
    var roomProxyMock: RoomProxyMock!
    var context: RoomDetailsViewModelType.Context { viewModel.context }

    override func setUp() {
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test"))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
    }

    func testLeaveRoomTappedWhenPublic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        context.send(viewAction: .processTapLeave)
        XCTAssertEqual(context.leaveRoomAlertItem?.state, .public)
        XCTAssertEqual(context.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertSubtitle)
    }

    func testLeaveRoomTappedWhenRoomNotPublic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
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
        await nextViewState()
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
        XCTAssertNotNil(context.alertInfo)
    }

    func testInitialDMDetailsState() async {
        let recipient = RoomMemberProxyMock.mockDan
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
    }

    func testIgnoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        recipient.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .success(())
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .ignoreConfirmed)
        await nextViewState()

        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        await nextViewState()
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
    }

    func testIgnoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        recipient.ignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .failure(.ignoreUserFailed)
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .ignoreConfirmed)
        await nextViewState()

        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        await nextViewState()
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
        XCTAssertNotNil(context.alertInfo)
    }

    func testUnignoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        recipient.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .success(())
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .unignoreConfirmed)
        await nextViewState()

        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)
        await nextViewState()
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
    }

    func testUnignoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        recipient.unignoreUserClosure = {
            try? await Task.sleep(for: .milliseconds(10))
            return .failure(.unignoreUserFailed)
        }
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsViewModel(roomProxy: roomProxyMock, mediaProvider: MockMediaProvider())
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))

        context.send(viewAction: .unignoreConfirmed)
        await nextViewState()
        XCTAssertTrue(context.viewState.isProcessingIgnoreRequest)

        await nextViewState()
        XCTAssertFalse(context.viewState.isProcessingIgnoreRequest)
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
        XCTAssertNotNil(context.alertInfo)
    }
    
    // MARK: - Private
    
    @discardableResult
    func nextViewState() async -> RoomDetailsViewState? {
        await context.nextViewState()
    }
}
