import Foundation
import MatrixRustSDK

public extension RoomInfo {
    func matrixFormattedRoomName(homeServerPostFix: String) -> String? {
        if let roomName = displayName {
            roomName.toMatrixUserIdFormat(homeServerPostFix)
        } else {
            nil
        }
    }
}
