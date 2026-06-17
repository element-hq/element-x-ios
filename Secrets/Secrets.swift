enum Secrets {
    static let sentryDSN: String? = "https://username@sentry.localhost/project_id"
    static let sentryRustDSN: String? = "https://username@sentry.localhost/project_id"
    static let postHogHost: String? = "https://posthog.localhost"
    static let postHogAPIKey: String? = "your_key"
    static let rageshakeURL: String? = "https://rageshake.localhost/submit"
    static let mapLibreAPIKey: String? = "your_key"

    // DEVELOPMENT-only Gua backend endpoints (used when GuaDeployment.current == .development, i.e. Debug
    // or a GUA_DEVELOPMENT build). Release builds ignore these and use the production gua.global hosts in
    // GuaDeployment. Override locally / in CI with the real dev hosts; the committed placeholders keep the
    // non-public dev infrastructure out of this repo.
    static let identityServiceBaseURL: String? = "http://localhost:8080"
    static let resolverBaseURL: String? = "http://localhost:8095"

}
