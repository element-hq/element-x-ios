//
//  RoomSummaryProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import Combine

enum RoomSummaryCallback {
    case updatedData
}

protocol RoomSummaryProtocol {
    var id: String { get }
    var name: String? { get }
    var topic: String? { get }
    var isDirect: Bool { get }
    var isEncrypted: Bool { get }
    var isSpace: Bool { get }
    var isTombstoned: Bool { get }
    
    var displayName: String? { get }
    var lastMessage: EventBrief? { get }
    var avatar: UIImage? { get }
    
    var callbacks: PassthroughSubject<RoomSummaryCallback, Never> { get }
    
    func loadData()
}
