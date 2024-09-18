import Foundation
import MatrixRustSDK

extension RoomInfo {
    public func matrixFormattedRoomName(homeServerPostFix: String) -> String? {
        if let roomName = displayName {
            roomName.toMatrixUserIdFormat(homeServerPostFix)
        } else {
            nil
        }
    }
}
