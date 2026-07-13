//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

final class PresenceService {
    private let clientProxy: ClientProxyProtocol
    private let appSettings: AppSettings
    private let sharedPresenceStateStore: SharedPresenceStateStoreProtocol
    private let notificationCenter: NotificationCenter
    
    private var isForegroundActive: Bool
    private var lastSentPresence: ClientProxyPresence?
    private var pendingPresence: ClientProxyPresence?
    private var sendTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    private var foregroundActivityRefreshCancellable: AnyCancellable?
    
    init(clientProxy: ClientProxyProtocol,
         appSettings: AppSettings,
         sharedPresenceStateStore: SharedPresenceStateStoreProtocol,
         notificationCenter: NotificationCenter = .default,
         initialApplicationState: UIApplication.State = UIApplication.shared.applicationState) {
        self.clientProxy = clientProxy
        self.appSettings = appSettings
        self.sharedPresenceStateStore = sharedPresenceStateStore
        self.notificationCenter = notificationCenter
        isForegroundActive = initialApplicationState == .active
        
        observeApplicationState()
        observeSharePresence()
        updateMainAppActivityState(for: initialApplicationState)
        updateForegroundActivityRefresh()
        reportCurrentState()
    }
    
    isolated deinit {
        sendTask?.cancel()
        foregroundActivityRefreshCancellable?.cancel()
        cancellables.forEach { $0.cancel() }
    }
    
    private var desiredPresence: ClientProxyPresence {
        switch (isForegroundActive, appSettings.sharePresence) {
        case (true, true):
            .online
        case (true, false):
            .offline
        case (false, true):
            .unavailable
        case (false, false):
            .offline
        }
    }
    
    private func observeApplicationState() {
        notificationCenter.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.apply(applicationState: .inactive)
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.apply(applicationState: .active)
            }
            .store(in: &cancellables)
    }
    
    private func observeSharePresence() {
        appSettings.sharePresencePublisher
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reportCurrentState()
            }
            .store(in: &cancellables)
    }
    
    private func apply(applicationState: UIApplication.State) {
        isForegroundActive = applicationState == .active
        updateMainAppActivityState(for: applicationState)
        updateForegroundActivityRefresh()
        reportCurrentState()
    }
    
    private func updateMainAppActivityState(for applicationState: UIApplication.State) {
        sharedPresenceStateStore.updateMainAppActivityState(applicationState.mainAppActivityState,
                                                            systemUptime: ProcessInfo.processInfo.systemUptime)
    }
    
    private func updateForegroundActivityRefresh() {
        foregroundActivityRefreshCancellable?.cancel()
        foregroundActivityRefreshCancellable = nil
        
        guard isForegroundActive else {
            return
        }
        
        foregroundActivityRefreshCancellable = Timer.publish(every: NotificationExtensionPresencePolicy.foregroundActiveRefreshInterval,
                                                             on: .main,
                                                             in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshForegroundActiveState()
            }
    }
    
    private func refreshForegroundActiveState() {
        guard isForegroundActive else {
            return
        }
        
        updateMainAppActivityState(for: .active)
    }
    
    private func reportCurrentState() {
        let presence = desiredPresence
        guard sendTask != nil || presence != lastSentPresence else {
            return
        }
        
        guard pendingPresence != presence else {
            return
        }
        
        pendingPresence = presence
        startSendTaskIfNeeded()
    }
    
    private func startSendTaskIfNeeded() {
        guard sendTask == nil else {
            return
        }
        
        let clientProxy = clientProxy
        sendTask = Task { [weak self, clientProxy] in
            while !Task.isCancelled {
                guard let presence = await self?.nextPendingPresence() else {
                    break
                }
                
                _ = await clientProxy.configurePresence(presence, sendImmediately: true)
                
                guard !Task.isCancelled else {
                    break
                }
                
                await self?.finishSending(presence)
            }
            
            await self?.finishSendTask()
        }
    }
    
    private func nextPendingPresence() -> ClientProxyPresence? {
        guard let pendingPresence else {
            return nil
        }
        
        self.pendingPresence = nil
        return pendingPresence
    }
    
    private func finishSending(_ presence: ClientProxyPresence) {
        lastSentPresence = presence
        
        if pendingPresence == presence {
            pendingPresence = nil
        }
    }
    
    private func finishSendTask() {
        sendTask = nil
        
        if pendingPresence != nil {
            startSendTaskIfNeeded()
        }
    }
}
