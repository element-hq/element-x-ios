//
//  RoomMessageProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

protocol RoomMessageProtocol {
    var id: String { get }
    var content: String { get }
    var sender: String { get }
    var originServerTs: Date { get }
}
