//
//  EventBrief.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct EventBrief {
    let eventId: String
    let senderId: String
    let senderDisplayName: String?
    let body: String
    let htmlBody: String?
    let date: Date
}
