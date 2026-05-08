import Foundation

// swiftformat:disable wrapArguments indent

public protocol UserDefaultsProtocol: AnyObject {
    func data(forKey key: String) -> Data?
    func object(forKey key: String) -> Any?
    func removeObject(forKey key: String)
    func set(_ value: Any?, forKey key: String)
    func removePersistentDomain(forName name: String)
}

extension UserDefaults: UserDefaultsProtocol { }
