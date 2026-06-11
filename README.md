<p align="center">
  <img src="https://raw.githubusercontent.com/Gua-ra/gua-branding/refs/heads/main/logos/gua-logo-transparent.png" alt="Gua Logo" width="200"/>
</p>

# Gua for iOS

**Gua** is a private, phone-number-based messaging app for iOS, built on top of [Matrix](https://matrix.org/).

This repository is Gua-ra's fork of [`element-hq/element-x-ios`](https://github.com/element-hq/element-x-ios) (Element X iOS). The Gua app replaces Element's brand and login flow with Gua's phone-OTP + PIN onboarding, backed by the [Gua Identity Service](https://github.com/Gua-ra/identity-service).

---

## What's different from upstream Element X

| Area | Upstream (Element X) | Gua |
|---|---|---|
| Brand | Element / New Vector | Gua |
| Login flow | Matrix password / SSO | Phone number → OTP → PIN (via Gua Identity Service + MAS) |
| OIDC provider | element.io | Gua Identity Service (`gua-ios` client, PKCE-required) |
| Consent screen | shown for every login | skipped — handled by [`gua-auth-service`](https://github.com/Gua-ra/gua-auth-service) config |
| Two-step verification | device verification | Account PIN (set, change with OTP cooldown, reset) |
| Account deactivation | standard Matrix | Gua-specific reauth (phone OTP) gate |

### Active fork branches

| Branch | Purpose |
|---|---|
| `mvp/phone-otp-oidc-pin-onboarding` | Phone OTP sign-up, PIN screens, settings (two-step verification, deactivation) |
| `mvp/OIDC-integration` | MAS OIDC integration: removes forced `prompt=consent`, adapts redirect handling |

---

## Architecture

```
Gua iOS app
    │  OIDC authorization-code + PKCE
    ▼
Matrix Authentication Service (Gua fork — gua-auth-service)
    │  upstream OIDC (phone → OTP → PIN)
    ▼
Gua Identity Service (Spring Boot)
    │  Matrix admin API
    ▼
Synapse homeserver
```

- The iOS app registers as OIDC client `gua-ios` (public, PKCE-required) against MAS.
- MAS delegates login to the Gua Identity Service via an upstream OIDC provider.
- The Gua Identity Service implements the phone → OTP → PIN flow and issues JWTs.
- The consent screen ("Continue to {client}?") is suppressed by the `gua-auth-service` fork via `gua.skip_consent_client_ids`.

---

## Building

Requirements: **Xcode 16+**, **iOS 17+ simulator or device**.

```bash
# Clone with submodules (Matrix Rust SDK swift package resolves via SPM)
git clone --recurse-submodules git@github.com:Gua-ra/gua-ios.git
cd gua-ios
open ElementX.xcworkspace
```

Select the **Gua** scheme and build. The app connects to the Gua backend; for local development point `ServiceLocator` at your local identity-service instance.

See the upstream [contribution guide](CONTRIBUTING.md) for full environment setup, code-generation steps, and testing instructions.

---

## Upstream relationship

This repository tracks [`element-hq/element-x-ios`](https://github.com/element-hq/element-x-ios). To pull upstream changes:

```bash
git fetch upstream
git merge upstream/develop   # or the relevant release tag
# Resolve conflicts, then push
```

Gua-specific changes are kept on named branches (`mvp/*`) to keep upstream merges clean.

---

## License

Copyright (c) 2022-2025 New Vector Ltd (upstream code)
Copyright (c) 2025 Gua-ra (Gua modifications)

Licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) — see [LICENSE](LICENSE).

Alternatively available under a paid Element Commercial License for the upstream portions; see [LICENSE-COMMERCIAL](LICENSE-COMMERCIAL) if applicable.
