import ArgumentParser
import CommandLineTools
import Foundation

struct SimulatorKeyboard: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool to configure the iOS simulator's hardware keyboard.")
    
    @Argument(help: "Pass 'enable' to enable the hardware keyboard or 'disable' to disable it.")
    var state: State
    
    enum Error: Swift.Error {
        case failedLoading
        case missingDevicePreferences
    }
    
    enum Key {
        static let devices = "DevicePreferences"
        static let hardwareKeyboard = "ConnectHardwareKeyboard"
    }
    
    enum State: String, ExpressibleByArgument {
        case enable
        case disable
        
        var description: String {
            switch self {
            case .enable: "enabled"
            case .disable: "disabled"
            }
        }
        
        var isEnabled: Bool {
            switch self {
            case .enable: true
            case .disable: false
            }
        }
    }

    func run() throws {
        let preferencesURL = URL.libraryDirectory.appending(path: "Preferences/com.apple.iphonesimulator.plist")
        
        guard var preferences = NSDictionary(contentsOf: preferencesURL) as? [String: Any] else {
            throw Error.failedLoading
        }
        guard var devices = preferences[Key.devices] as? [String: [String: Any]] else {
            throw Error.missingDevicePreferences
        }
        
        for deviceID in devices.keys {
            if devices[deviceID]![Key.hardwareKeyboard] as? Bool != state.isEnabled {
                print("\(deviceID): Hardware keyboard \(state.description).")
                devices[deviceID]![Key.hardwareKeyboard] = state.isEnabled
            }
        }
        
        preferences[Key.devices] = devices
        
        let data = try PropertyListSerialization.data(fromPropertyList: preferences, format: .binary, options: 0)
        try data.write(to: preferencesURL)
        print("Preferences plist updated successfully.")
    }
}
