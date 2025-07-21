//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import FirebaseFirestore

class ZeroCustomEventService {
    static let shared = ZeroCustomEventService()
    
    private let db = Firestore.firestore()
        
    private var userId: String? = nil
    private var userName: String? = nil
    
    private var pendingEvents: [(String, String, [String: Any]?)] = []
        
    private init() { }
    
    func setup(userId: String, userName: String) {
        self.userId = userId
        self.userName = userName
        
        if !pendingEvents.isEmpty {
            for (eventName, cat, parameters) in pendingEvents {
                self.logEvent(eventName, category: cat, parameters: parameters)
            }
            pendingEvents.removeAll()
        }
    }
    
    func logUserRooms(rooms: [RoomSummary]) {
        Task.detached {
            var roomParameters: [String: [String : Any]] = [:]
            for room in rooms {
                roomParameters[room.id] = [
                    "id" : room.id,
                    "name" : room.name,
                    "isDirect" : room.isDirect,
                    "isDirectOneToOne" : room.isDirectOneToOneRoom,
                    "activeMembersCount" : room.room.activeMembersCount(),
                    "joinedMembersCount" : room.room.joinedMembersCount(),
                    "invitedMembersCount" : room.room.invitedMembersCount(),
                    "herosCount" : room.room.heroes().count,
                ]
            }
            self.roomScreenEvent(parameters: roomParameters)
        }
    }
    
    func roomScreenEvent(parameters: [String: Any]) {
        logEvent("ROOM", category: "SCREEN", parameters: parameters)
    }
    
    func roomApiEvent(parameters: [String: Any]) {
        logEvent("ROOM", category: "API", parameters: parameters)
    }
    
    func feedScreenEvent(parameters: [String: Any]) {
        logEvent("FEED", category: "SCREEN", parameters: parameters)
    }
    
    func feedApiEvent(parameters: [String: Any]) {
        logEvent("FEED", category: "API", parameters: parameters)
    }
    
    func walletScreenEvent(parameters: [String: Any]) {
        logEvent("WALLET", category: "SCREEN", parameters: parameters)
    }
    
    func walletApiEvent(parameters: [String: Any]) {
        logEvent("WALLET", category: "API", parameters: parameters)
    }
    
    private lazy var logId: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm" 
        return formatter.string(from: Date())
    }()
    
    func logEvent(_ eventName: String, category: String, parameters: [String: Any]? = nil) {
        if let userId = userId {
            if userId.lowercased() != "placeholder_id" {
                let userId = if let name = userName {
                    "\(name)(\(userId))".trim()
                } else {
                    userId
                }
                db.collection("zero_logs")
                    .document(userId)
                    .collection(logId)
                    .document(eventName)
                    .collection(category)
                    .addDocument(data: parameters ?? [:]) { error in
                        if let error = error {
                            print("❌ Failed to log event: \(error.localizedDescription)")
                        }
                    }
            }
        } else {
            pendingEvents.append((eventName, category, parameters))
        }
    }
}
