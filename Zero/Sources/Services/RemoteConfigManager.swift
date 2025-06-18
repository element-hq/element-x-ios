//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import FirebaseRemoteConfig

// MARK: - Remote Config Model
struct ZeroRemoteConfigs: Codable {
    let android: AppRemoteConfigs
    let iOS: AppRemoteConfigs
}

struct AppRemoteConfigs: Codable {
    let appVersion: String
    let maintenanceModeEnabled: Bool
    let forceUpdateEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case maintenanceModeEnabled = "maintenance_mode"
        case forceUpdateEnabled = "force_update"
    }
}

// MARK: - Remote Config Manager
class RemoteConfigManager: ObservableObject {
    
    static let shared = RemoteConfigManager()
    private let remoteConfig: RemoteConfig
    private var configSettings: RemoteConfigSettings
    private var configUpdateListener: ConfigUpdateListenerRegistration?
    
    @Published var forceUpdateEnabled = false
    @Published var maintenanceModeEnabled = false
    
    private init() {
        self.remoteConfig = RemoteConfig.remoteConfig()
        self.configSettings = RemoteConfigSettings()
        
        setupRemoteConfig()
        initializeConfigs()
    }
    
    // MARK: - Setup
    private func setupRemoteConfig() {
        // Configure settings
        //        configSettings.minimumFetchInterval = 0 // For development - increase for production
        //        configSettings.fetchTimeout = 30
        remoteConfig.configSettings = configSettings
    }
    
    private func initializeConfigs() {
        remoteConfig.fetchAndActivate { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    MXLog.info("Remote_Config: fetch failed: \(error.localizedDescription)")
                } else {
                    MXLog.info("Remote_Config: fetched successfully. Status: \(status)")
                    self?.updateValues()
                    self?.addRemoteConfigsObserver()
                }
            }
        }
    }
    
    private func addRemoteConfigsObserver() {
        configUpdateListener = remoteConfig.addOnConfigUpdateListener { [weak self] configUpdate, error in
            guard error == nil else {
                MXLog.info("Remote_Config: Error listening for config updates: \(error!.localizedDescription)")
                return
            }
            
            MXLog.info("Remote_Config: Config updated remotely. Fetching and activating...")
            self?.remoteConfig.activate { _, _ in
                DispatchQueue.main.async {
                    self?.updateValues()
                }
            }
        }
    }
    
    // Update published properties
    private func updateValues() {
        let jsonString = remoteConfig.configValue(forKey: "remote_configs").stringValue
        guard !jsonString.isEmpty else {
            print("Remote_Config: JSON string is empty")
            return
        }
        if let zeroRemoteConfigs = parseJSONString(jsonString, as: ZeroRemoteConfigs.self) {
            forceUpdateEnabled = zeroRemoteConfigs.iOS.forceUpdateEnabled
            maintenanceModeEnabled = zeroRemoteConfigs.iOS.maintenanceModeEnabled
        } else {
            print("Remote_Config: Failed to parse JSON string")
        }
    }
    
    private func parseJSONString<T: Codable>(_ jsonString: String, as type: T.Type) -> T? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Remote_Config: Failed to convert string to data")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(type, from: jsonData)
            return result
        } catch {
            print("Remote_Config: JSON parsing error: \(error)")
            return nil
        }
    }
}
