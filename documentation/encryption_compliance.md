# Encryption Compliance Documentation

**App Name:** UCMeet.Chat
**Bundle ID:** org.ucmeet.UCMeetChat
**Developer:** UC.Technology LLC
**Date:** March 22, 2026

## 1. Encryption Usage

UCMeet.Chat is a secure messaging application built on the Matrix protocol. The app uses encryption for:

1. **End-to-End Encryption (E2EE):** Messages and calls are encrypted using the Olm and Megolm cryptographic protocols, implemented by the open-source Matrix Rust SDK.
2. **Transport Security:** All client-server communication uses HTTPS/TLS.

## 2. Cryptographic Algorithms

| Algorithm | Purpose | Standard |
|-----------|---------|----------|
| AES-256-CBC | Message encryption (Megolm) | NIST FIPS 197 |
| Curve25519 | Key agreement (Olm) | IETF RFC 7748 |
| Ed25519 | Digital signatures | IETF RFC 8032 |
| HMAC-SHA-256 | Message authentication | IETF RFC 2104 |
| HKDF-SHA-256 | Key derivation | IETF RFC 5869 |
| TLS 1.2/1.3 | Transport security | IETF RFC 8446 |

All algorithms listed above are standard, well-known algorithms accepted by international standards organizations (IETF, NIST).

## 3. Encryption Implementation

The app does **not** implement its own cryptographic algorithms. All cryptographic operations are performed by:

- **Matrix Rust SDK** (open source, Apache 2.0 license): Provides Olm/Megolm E2EE implementation. Source code publicly available at https://github.com/matrix-org/matrix-rust-sdk
- **Apple Security framework / TLS**: Provides transport-layer encryption via the operating system.

## 4. Open Source Exemption

The encryption source code used by this application is publicly available and qualifies for the publicly available encryption source code exemption under EAR Section 742.15(b). The Matrix Rust SDK is published under the Apache 2.0 license at the URL listed above.

## 5. Availability

The app is available to users worldwide through the Apple App Store. It does not restrict encryption functionality based on geography.
