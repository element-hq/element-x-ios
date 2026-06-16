import XCTest

@testable import ElementX

@MainActor
final class ContactDiscoveryServiceTests: XCTestCase {
    func testLookupContactMatchesBatchesAllNumbers() async throws {
        let phones = [
            "+15550000001",
            "+15550000002",
            "+15550000003",
            "+15550000004",
            "+15550000005"
        ]
        let identityServiceClient = IdentityServiceClientStub()
        identityServiceClient.matchesByPhone = Dictionary(uniqueKeysWithValues: phones.map { phone in
            (phone, ContactMatch(phoneNumber: phone, userId: "@\(phone):dev.local", username: nil, displayName: nil))
        })
        let service = ContactDiscoveryService(identityServiceClient: identityServiceClient, maxNumbersPerRequest: 2)

        let matches = try await service.lookupContactMatches(accessToken: "access-token", phones: phones)

        XCTAssertEqual(identityServiceClient.lookupRequests, [
            Array(phones[0..<2]),
            Array(phones[2..<4]),
            Array(phones[4..<5])
        ])
        XCTAssertEqual(matches.map(\.phoneNumber), phones)
    }

    func testNormalizeToE164KeepsExplicitInternationalNumber() {
        XCTAssertEqual(ContactDiscoveryService.normalizeToE164("+1 (415) 555-1212", defaultDialCode: "1"), "+14155551212")
    }

    func testNormalizeToE164ConvertsInternationalPrefix() {
        XCTAssertEqual(ContactDiscoveryService.normalizeToE164("00 33 6 12 34 56 78", defaultDialCode: "1"), "+33612345678")
    }

    func testNormalizeToE164PrependsDefaultDialCodeToNationalNumber() {
        XCTAssertEqual(ContactDiscoveryService.normalizeToE164("(415) 555-1212", defaultDialCode: "1"), "+14155551212")
    }

    func testNormalizeToE164DoesNotDuplicateDefaultDialCode() {
        XCTAssertEqual(ContactDiscoveryService.normalizeToE164("1 415 555 1212", defaultDialCode: "1"), "+14155551212")
        XCTAssertEqual(ContactDiscoveryService.normalizeToE164("55 11 98765 4321", defaultDialCode: "55"), "+5511987654321")
    }

    func testNormalizeToE164DropsNationalTrunkPrefix() {
        XCTAssertEqual(ContactDiscoveryService.normalizeToE164("011 98765 4321", defaultDialCode: "55"), "+5511987654321")
    }
}

private final class IdentityServiceClientStub: IdentityServiceClientProtocol {
    var lookupRequests: [[String]] = []
    var matchesByPhone: [String: ContactMatch] = [:]

    func sendOTP(phone: String, language: String?) async throws {
        fatalError("Not implemented")
    }

    func verifyOTP(phone: String, code: String, pin: String?, device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceVerifyOutcome {
        fatalError("Not implemented")
    }

    func completeSignup(signupToken: String, username: String, displayName: String, pin: String?, device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceMatrixSession {
        fatalError("Not implemented")
    }

    func verifyPinChallenge(pinChallengeToken: String, pin: String, device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceMatrixSession {
        fatalError("Not implemented")
    }

    func checkUsernameAvailability(_ username: String) async throws -> UsernameAvailability {
        fatalError("Not implemented")
    }

    func lookupContacts(accessToken: String, phones: [String]) async throws -> [ContactMatch] {
        lookupRequests.append(phones)
        return phones.compactMap { matchesByPhone[$0] }
    }

    func startAccountReauth(accessToken: String, language: String?) async throws {
        fatalError("Not implemented")
    }

    func verifyAccountReauth(accessToken: String, code: String) async throws -> String {
        fatalError("Not implemented")
    }

    func deactivateAccount(accessToken: String, reauthToken: String, eraseData: Bool) async throws {
        fatalError("Not implemented")
    }

    func resetIdentityCredentials(accessToken: String, reauthToken: String) async throws -> IdentityResetCredentials {
        fatalError("Not implemented")
    }

    func pinStatus(accessToken: String) async throws -> Bool {
        fatalError("Not implemented")
    }

    func setInitialPin(accessToken: String, userId: String, newPin: String) async throws {
        fatalError("Not implemented")
    }

    func startPinChange(accessToken: String, phone: String, currentPin: String) async throws -> String {
        fatalError("Not implemented")
    }

    func completePinChange(accessToken: String, challengeId: String, otpCode: String, newPin: String) async throws {
        fatalError("Not implemented")
    }
}
