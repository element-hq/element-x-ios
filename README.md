![](https://github.com/user-attachments/assets/054e40c6-e796-4c6b-9700-7b7c3c4bfc18)

<div align="center">
  
  ![Gua Logo](https://github.com/user-attachments/assets/33d5300f-24ac-42fe-84c2-37ca84920bd1)
  
  <h1>Gua for iOS</h1>
</div>

**Gua** is a private messenger built on the open [Matrix](https://matrix.org/) protocol. It pairs an end-to-end encrypted, federated network with the simplicity people expect from a mainstream messaging app: sign in with something you already have, find your friends privately, and start talking. Sign-in is deliberately simple: it is phone-based by default today, and the account model is designed to stay flexible, including institutional SSO for organizations that bring their own identity.

This repository is the Gua iOS client. It began as a fork of [`element-hq/element-x-ios`](https://github.com/element-hq/element-x-ios) and keeps its Matrix core (Matrix Rust SDK, timelines, calls, encryption) while adding a Gua product layer that spans routing, onboarding, account security, contact discovery, and the day-to-day experience.

---

## The Gua product layer

- **Trusted-federation routing.** Sign-in starts at the Gua resolver, which answers where in the closed Gua federation an account lives (sign-in) or should be created (registration). The client then authenticates against that server. Users never pick, type, or see a server name.
- **Homeserver abstraction.** Server details stay out of the product: people appear as simple usernames rather than full Matrix IDs, and the homeserver behind an account is an implementation detail, not part of a user's identity.
- **Simplified onboarding.** A native welcome and sign-in flow: enter a phone number, confirm a one-time code, set up a profile, and secure the account, all inside the app. Under the hood the client authenticates over OIDC (authorization code + PKCE) against a Matrix Authentication Service that delegates identity to the Gua identity service.
- **Two-step verification (account PIN).** A six-digit account PIN is the account's second factor: set during onboarding, required for sensitive operations, and changeable or resettable with verification. The client mirrors the server's PIN strength policy (no repeated, sequential, or common PINs).
- **Private contact discovery.** Find Friends shows which of your contacts are already on Gua. It runs only with address-book permission, normalizes numbers on the device, and looks up matches in capped batches; the address book itself never leaves the phone.
- **Phone-number management.** The number linked to an account can be changed from Settings, verified with a one-time code sent to the new number plus the account PIN as the second factor.
- **Welcome experience.** A polished, localized welcome screen (en, fr, es, pt, pt-BR) with the animated glass Gua logo.
- **Safe defaults.** End-to-end encryption stays on with sensible defaults while advanced encryption controls are hidden; the app-lock code is called a passcode so it is never confused with the account PIN.

## Architecture

```
Gua iOS app
    |  1. resolver lookup: which homeserver serves this account?
    ▼
Gua resolver
    |  2. OIDC authorization code + PKCE against the resolved server
    ▼
Matrix Authentication Service (gua-auth-service)
    |  3. delegated sign-in (phone + one-time code + PIN today, SSO-capable)
    ▼
Gua Identity Service
    |
    ▼
Matrix homeserver in the Gua federation
```

- The resolver answers "where does this account live?" so the client stays universal and account placement remains a backend concern.
- [`gua-auth-service`](https://github.com/Gua-ra/gua-auth-service) is Gua's Matrix Authentication Service; it skips the consent interstitial for first-party clients and delegates identity upstream.
- The [Gua Identity Service](https://github.com/Gua-ra/identity-service) implements verification codes, the account PIN, contact lookup, and phone-number changes.
- Every sign-in performs a fresh upstream authentication (ephemeral web session, `prompt=login`), so a cached browser session never bypasses verification.

---

## Building

Requirements: **Xcode 26.5** and an iOS simulator (iOS 17.5 or newer).

```bash
git clone git@github.com:Gua-ra/gua-ios.git
cd gua-ios
open Gua.xcodeproj
```

Select the **Gua** scheme and run. Open `Gua.xcodeproj`; the `ElementX.xcodeproj` next to it is an upstream leftover scheduled for removal.

Things to know:

- **Secrets.** `Secrets/Secrets.swift` is committed with placeholder values (localhost development endpoints and dummy analytics keys) so the project always compiles. Debug builds read the development backend endpoints from this file; point them at your own backend locally and keep those edits out of your commits. Release builds use the production configuration instead.
- **Project generation.** The Xcode project is generated from `project.yml` / `app.yml` with XcodeGen; if you change project configuration, run `xcodegen` and rebuild.
- **Forking.** Bundle identifiers, app groups, team configuration, and the OIDC client requirements are covered in [docs/FORKING.md](docs/FORKING.md).
- **Everything else.** Code generation, tests, and tooling are described in the [contribution guide](CONTRIBUTING.md).

---

## Upstream relationship

This fork tracks [`element-hq/element-x-ios`](https://github.com/element-hq/element-x-ios) as its upstream but does not share git history with it. Catching up with upstream means re-porting Gua's changes onto a new upstream snapshot rather than running `git merge`. See [docs/FORKING.md](docs/FORKING.md) for the fork configuration itself.

---

## License

Copyright (c) 2022-2025 New Vector Ltd (upstream code)
Copyright (c) 2025 Gua (Gua modifications)

Licensed under the GNU Affero General Public License v3.0 (AGPL-3.0), see [LICENSE](LICENSE).

Alternatively available under a paid Element Commercial License for the upstream portions; see [LICENSE-COMMERCIAL](LICENSE-COMMERCIAL) if applicable.
