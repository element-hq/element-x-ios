//
// Copyright 2023 New Vector Ltd
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

@testable import ElementX
import MatrixRustSDK
import XCTest

final class MediaLoaderTests: XCTestCase {
    func testMediaRequestCoalescing() async {
        let mediaLoadingClient = MockMediaLoadingClient()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = MediaSourceProxy(url: URL.documentsDirectory, mimeType: nil)
        
        do {
            for _ in 1...10 {
                _ = try await mediaLoader.loadMediaContentForSource(mediaSource)
            }
            
            XCTAssertEqual(mediaLoadingClient.numberOfInvocations, 10)
        } catch {
            fatalError()
        }
    }
    
    func testMediaThumbnailRequestCoalescing() async {
        let mediaLoadingClient = MockMediaLoadingClient()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = MediaSourceProxy(url: URL.documentsDirectory, mimeType: nil)
        
        do {
            for _ in 1...10 {
                _ = try await mediaLoader.loadMediaThumbnailForSource(mediaSource, width: 100, height: 100)
            }
            
            XCTAssertEqual(mediaLoadingClient.numberOfInvocations, 10)
        } catch {
            fatalError()
        }
    }
}

private class MockMediaLoadingClient: ClientProtocol {
    private(set) var numberOfInvocations = 0
    
    func getMediaContent(mediaSource: MatrixRustSDK.MediaSource) throws -> [UInt8] {
        numberOfInvocations += 1
        return []
    }
    
    func getMediaThumbnail(mediaSource: MatrixRustSDK.MediaSource, width: UInt64, height: UInt64) throws -> [UInt8] {
        numberOfInvocations += 1
        return []
    }
    
    // MARK: - Not implemented
    
    func setDelegate(delegate: MatrixRustSDK.ClientDelegate?) { }
    
    func login(username: String, password: String, initialDeviceName: String?, deviceId: String?) throws { }
    
    func restoreSession(session: MatrixRustSDK.Session) throws { }
    
    func session() throws -> MatrixRustSDK.Session { fatalError() }
    
    func userId() throws -> String { fatalError() }
    
    func displayName() throws -> String { fatalError() }
    
    func setDisplayName(name: String) throws { }
    
    func avatarUrl() throws -> String? { fatalError() }

    func cachedAvatarUrl() throws -> String? { fatalError() }
    
    func deviceId() throws -> String { fatalError() }
    
    func accountData(eventType: String) throws -> String? { fatalError() }
    
    func setAccountData(eventType: String, content: String) throws { fatalError() }
    
    func uploadMedia(mimeType: String, data content: [UInt8]) throws -> String { fatalError() }
    
    func getMediaFile(mediaSource: MatrixRustSDK.MediaSource, body: String?, mimeType: String) throws -> MatrixRustSDK.MediaFileHandle { fatalError() }
    
    func getProfile(userId: String) throws -> MatrixRustSDK.UserProfile { fatalError() }
    
    func getSessionVerificationController() throws -> MatrixRustSDK.SessionVerificationController { fatalError() }
    
    func fullSlidingSync() throws -> MatrixRustSDK.SlidingSync { fatalError() }
    
    func logout() throws { }
    
    func hasFirstSynced() -> Bool { fatalError() }
    
    func homeserver() -> String { fatalError() }
    
    func isSoftLogout() -> Bool { fatalError() }
    
    func isSyncing() -> Bool { fatalError() }
    
    func rooms() -> [MatrixRustSDK.Room] { fatalError() }
    
    func slidingSync() -> MatrixRustSDK.SlidingSyncBuilder { fatalError() }
    
    func startSync(timelineLimit: UInt16?) { }
    
    func createRoom(request: MatrixRustSDK.CreateRoomParameters) throws -> String { fatalError() }

    func getDmRoom(userId: String) throws -> MatrixRustSDK.Room? {
        fatalError()
    }

    func ignoreUser(userId: String) throws {
        fatalError()
    }

    func unignoreUser(userId: String) throws {
        fatalError()
    }

    // swiftlint:disable:next function_parameter_count
    func setPusher(identifiers: MatrixRustSDK.PusherIdentifiers,
                   kind: MatrixRustSDK.PusherKind,
                   appDisplayName: String,
                   deviceDisplayName: String,
                   profileTag: String?,
                   lang: String) throws {
        fatalError()
    }
    
    func searchUsers(searchTerm: String, limit: UInt64) throws -> MatrixRustSDK.SearchUsersResults { fatalError() }

    func setNotificationDelegate(notificationDelegate: MatrixRustSDK.NotificationDelegate?) { }

    func getNotificationItem(roomId: String, eventId: String) throws -> MatrixRustSDK.NotificationItem {
        fatalError()
    }
}
