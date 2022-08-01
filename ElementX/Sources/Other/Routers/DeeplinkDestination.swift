//
//  DeeplinkDestination.swift
//  ElementX
//
//  Created by vollkorntomate on 2022-08-02.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum DeeplinkDestination {
    case room(_ roomId: String)
    case user(_ userId: String)
    
    init?(urlPathComponents: [String]) {
        guard urlPathComponents[safe: 0] == "/" else {
            return nil
        }
        let match = (urlPathComponents[safe: 1],
                     urlPathComponents[safe: 2],
                     urlPathComponents[safe: 3],
                     urlPathComponents[safe: 4])
        
        switch match {
        case ("room", let roomId, _, _):
            guard let roomId = roomId else { return nil }
            self = .room(roomId)
        case ("user", let userId, _, _):
            guard let userId = userId, userId.isMatrixUserID else { return nil }
            self = .user(userId)
        default:
            return nil
        }
    }
}

extension Collection {
    subscript(safe index: Self.Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
