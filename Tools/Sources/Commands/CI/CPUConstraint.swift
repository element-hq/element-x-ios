import Foundation

/// Saturates the CPU with busy processes for the duration of a test run, approximating
/// a loaded CI runner where timing-sensitive tests are starved of processor time.
final class CPUConstraint {
    private var processes = [Process]()
    
    /// Starts the given number of CPU hogging tasks. 2× the machine's cores is
    /// enough to keep the scheduler permanently oversubscribed.
    func start(taskCount: Int) {
        logger.info("\n🐌 Constraining the CPU with \(taskCount) tasks…\n")
        
        for _ in 0..<taskCount {
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/yes")
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                processes.append(process)
            } catch {
                logger.error("Failed to start a CPU constraining task: \(error)")
            }
        }
    }
    
    func stop() {
        guard !processes.isEmpty else { return }
        
        logger.info("\n🐌 Releasing the CPU…\n")
        processes.forEach { $0.terminate() }
        processes.removeAll()
    }
    
    deinit {
        stop()
    }
}
