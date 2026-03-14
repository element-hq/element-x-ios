import AVFoundation
import SwiftUI

@Observable
final class AudioPlaybackService {
    
    // MARK: - Состояние для UI
    
    var state: PlaybackState = .idle
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var progress: Double = 0          // 0...1
    var playbackSpeed: Double = 1.0
    var currentTitle: String = ""
    var error: Error?
    
    // MARK: - Очередь треков (как в Telegram)
    
    private(set) var queue: [PlayableAudioItem] = []
    private(set) var currentIndex: Int = -1
    
    enum PlaybackState {
        case idle, loading, playing, paused, finished, error
        
        var isActive: Bool { self == .playing || self == .paused }
        
        var displayText: String {
            switch self {
            case .playing:   return "Воспроизводится"
            case .paused, .finished: return "На паузе"
            case .loading:   return "Загрузка..."
            case .error:     return "Ошибка"
            default:         return ""
            }
        }
    }
    
    // MARK: - Внутренние объекты
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var rateObservation: NSKeyValueObservation?
    private var endTimeObserver: Any?
    
    static let shared = AudioPlaybackService()
    
    private init() {
        setupAudioSession()
        observeInterruptions()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = error
            state = .error
        }
    }
    
    private func observeInterruptions() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            
            switch type {
            case .began:
                if state == .playing { pause() }
            case .ended:
                if let options = info[AVAudioSessionInterruptionOptionKey] as? UInt,
                   AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                    if state == .paused { player?.play() }
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Основные методы
    
    func play(url: URL, title: String? = nil) {
        stop()  // всегда очищаем предыдущее
        
        currentTitle = title ?? url.lastPathComponent
        state = .loading
        
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        
        // Готовность к воспроизведению
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            
            switch item.status {
            case .readyToPlay:
                duration = item.duration.seconds.isFinite ? item.duration.seconds : 0
                player?.rate = Float(playbackSpeed)
                player?.play()
                state = .playing
                
            case .failed:
                error = item.error ?? NSError(domain: "AVPlayer", code: -1)
                state = .error
                
            default:
                break
            }
        }
        
        // Прогресс
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let ct = time.seconds
            currentTime = ct
            if duration > 0 {
                progress = ct / duration
            }
        }
        
        // Автоматический переход к следующему треку при завершении
        endTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            state = .finished
            progress = 1.0
            currentTime = duration
            next()   // ← автопродолжение
        }
        
        // Отслеживание изменения скорости / паузы
        rateObservation = player?.observe(\.rate) { [weak self] _, _ in
            guard let self else { return }
            state = (player?.rate ?? 0 > 0) ? .playing : .paused
        }
    }
    
    func togglePlayPause() {
        guard let player else { return }
        if state == .playing {
            pause()
        } else {
            if state == .finished {
                seek(to: 0)
            }
            player.play()
            player.rate = Float(playbackSpeed)
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func setSpeed(_ speed: Double) {
        playbackSpeed = max(0.5, min(2.0, speed))
        if state == .playing {
            player?.rate = Float(playbackSpeed)
        }
    }
    
    func seek(to progress: Double) {
        guard duration > 0 else { return }
        let clamped = max(0, min(1, progress))
        let time = CMTime(seconds: clamped * duration, preferredTimescale: 600)
        player?.seek(to: time)
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        
        state = .idle
        currentTime = 0
        progress = 0
        currentTitle = ""
        
        queue = []
        currentIndex = -1
        
        cleanupObservers()
    }
    
    private func cleanupObservers() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let end = endTimeObserver {
            NotificationCenter.default.removeObserver(end)
            endTimeObserver = nil
        }
        statusObservation?.invalidate()
        rateObservation?.invalidate()
        statusObservation = nil
        rateObservation = nil
    }
    
    // MARK: - Управление очередью (как в Telegram)
    
    func startPlayback(items: [PlayableAudioItem], startAt index: Int = 0) {
        guard !items.isEmpty, index >= 0, index < items.count else {
            stop()
            return
        }
        
        stop()
        
        queue = items
        currentIndex = index
        playCurrent()
    }
    
    private func playCurrent() {
        guard currentIndex >= 0, currentIndex < queue.count else {
            stop()
            return
        }
        
        let item = queue[currentIndex]
        currentTitle = item.displayTitle
        
        // Можно здесь пометить сообщение как прослушанное в модели чата
        // например: NotificationCenter.default.post(name: .audioMessagePlayed, object: item.messageId)
        
        play(url: item.url, title: item.displayTitle)
    }
    
    func next() {
        if currentIndex + 1 < queue.count {
            currentIndex += 1
            playCurrent()
        } else {
            stop()
        }
    }
    
    func previous() {
        if currentIndex - 1 >= 0 {
            currentIndex -= 1
            playCurrent()
        }
    }
}

// MARK: - Структура для элемента очереди

struct PlayableAudioItem {
    let url: URL
    let displayTitle: String            // "от Иван" или "Лето 2025.mp3"
    let isVoiceMessage: Bool
    let messageId: String?              // для отметки прослушано / навигации
    let senderDisplayName: String?      // только для голосовых
}
