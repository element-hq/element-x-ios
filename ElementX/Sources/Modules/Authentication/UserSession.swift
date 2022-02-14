//
//  UserSession.swift
//  ElementX
//
//  Created by Stefan Ceriu on 14.02.2022.
//

import Foundation
import MatrixRustSDK

class UserSession {
    
    private let client: Client
    
    init(client: Client) {
        self.client = client
        
        if !client.hasFirstSynced() {
            MXLog.info("Started initial sync")
            client.startSync()
            MXLog.info("Finished intial sync")
        }
    }
    
    func roomList() -> [RoomModel] {
        client.conversations().compactMap { room in
            do {
                return RoomModel(displayName: try room.displayName())
            } catch {
                MXLog.error("Failed retrieving room info with error: \(error)")
                return nil
            }
        }
    }
    
    var displayName: String? {
        do {
            return try client.displayName()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return nil
        }
    }
}
