//
//  RoomMessageFactoryProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 26/05/2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import MatrixRustSDK

protocol RoomMessageFactoryProtocol {
    func buildRoomMessageFrom(_ message: AnyMessage) -> RoomMessageProtocol
}
