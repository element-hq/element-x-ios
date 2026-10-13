# Tidy

Follow-ups that aren't worth their own PR yet. Do each item in one go, not piecemeal.

- **Enterprise hook tests should use `EnterpriseESSServiceMock(configuration:)` instead of the on-disk cache.** Today `EnterpriseCreateRoomScreenHookTests`, `EnterpriseSecurityAndPrivacyScreenHookTests`, `EnterpriseUserSessionHookTests` and parts of `EnterpriseRemoteSettingsHookTests` seed a real `EnterpriseESSService` by writing an `EnterpriseESSConfiguration` to `URL.cachedESSConfigurationFile(for:)`, and each wipes `.enterpriseApplicationSupportBaseDirectory` in `init`. Passing the mock removes the disk dependency and the shared-directory coupling. Switch all of them together so the pattern stays consistent, and leave `EnterpriseESSServiceTests` alone since the cache is what it tests.
