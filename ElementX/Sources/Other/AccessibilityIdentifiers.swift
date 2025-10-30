//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum A11yIdentifiers {
    static let alertInfo = AlertInfo()
    static let analyticsPromptScreen = AnalyticsPromptScreen()
    static let appLockScreen = AppLockScreen()
    static let appLockSetupBiometricsScreen = AppLockSetupBiometricsScreen()
    static let appLockSetupPINScreen = AppLockSetupPINScreen()
    static let appLockSetupSettingsScreen = AppLockSetupSettingsScreen()
    static let bugReportScreen = BugReportScreen()
    static let changeServerScreen = ChangeServer()
    static let encryptionResetScreen = EncryptionResetScreen()
    static let encryptionResetPasswordScreen = EncryptionResetPasswordScreen()
    static let homeScreen = HomeScreen()
    static let loginScreen = LoginScreen()
    static let authenticationStartScreen = AuthenticationStartScreen()
    static let reportContent = ReportContent()
    static let joinRoomScreen = JoinRoomScreen()
    static let roomScreen = RoomScreen()
    static let roomDetailsScreen = RoomDetailsScreen()
    static let roomNotificationSettingsScreen = RoomNotificationSettingsScreen()
    static let roomRolesAndPermissionsScreen = RoomRolesAndPermissionsScreen()
    static let secureBackupScreen = SecureBackupScreen()
    static let secureBackupKeyBackupScreen = SecureBackupKeyBackupScreen()
    static let secureBackupRecoveryKeyScreen = SecureBackupRecoveryKeyScreen()
    static let serverConfirmationScreen = ServerConfirmationScreen()
    static let sessionVerificationScreen = SessionVerificationScreen()
    static let settingsScreen = SettingsScreen()
    static let softLogoutScreen = SoftLogoutScreen()
    static let startChatScreen = StartChatScreen()
    static let roomMemberDetailsScreen = RoomMemberDetailsScreen()
    static let createRoomScreen = CreateRoomScreen()
    static let inviteUsersScreen = InviteUsersScreen()
    static let notificationSettingsScreen = NotificationSettingsScreen()
    static let notificationSettingsEditScreen = NotificationSettingsEditScreen()
    static let pollFormScreen = PollFormScreen()
    static let roomPollsHistoryScreen = RoomPollsHistoryScreen()
    static let manageRoomMemberSheet = ManageRoomMemberSheet()
    static let spaceListScreen = SpaceListScreen()
    
    struct AlertInfo {
        let primaryButton = "alert_info-primary_button"
        let secondaryButton = "alert_info-secondary_button"
    }
    
    struct AppLockScreen {
        func numpad(_ digit: Int) -> String { "app_lock-numpad_\(digit)" }
    }
    
    struct AppLockSetupBiometricsScreen {
        let allow = "app_lock_setup_biometrics-allow"
    }
    
    struct AppLockSetupPINScreen {
        let textField = "app_lock_setup_pin-text_field"
        let cancel = "app_lock_setup_pin-cancel"
    }
    
    struct AppLockSetupSettingsScreen {
        let changePIN = "app_lock_setup_settings-change_pin"
        let removePIN = "app_lock_setup_settings-remove_pin"
    }

    struct AnalyticsPromptScreen {
        let title = "analytics_prompt-title"
        let enable = "analytics_prompt-enable"
        let notNow = "analytics_prompt-not_now"
    }

    struct BugReportScreen {
        let report = "bug_report-report"
        let sendLogs = "bug_report-send_logs"
        let canContact = "bug_report-can_contact"
        let screenshot = "bug_report-screenshot"
        let removeScreenshot = "bug_report-remove_screenshot"
        let attachScreenshot = "bug-report-attach_screenshot"
        let cancel = "bug_report-cancel"
    }
    
    struct ChangeServer {
        let server = "change_server-server"
        let `continue` = "change_server-continue"
        let dismiss = "change_server-dismiss"
    }
    
    struct EncryptionResetScreen {
        let continueReset = "encryption_reset-continue_reset"
    }
    
    struct EncryptionResetPasswordScreen {
        let passwordField = "encryption_reset_password-password_field"
        let submit = "encryption_reset_password-submit"
    }
    
    struct HomeScreen {
        let userAvatar = "home_screen-user_avatar"
        let recoveryKeyConfirmationBannerContinue = "home_screen-recovery_key_confirmation_continue"
        let startChat = "home_screen-start_chat"
        
        let roomNamePrefix = "home_screen-room_name"
        func roomName(_ name: String) -> String {
            "\(roomNamePrefix):\(name)"
        }
    }
    
    struct InviteUsersScreen {
        let proceed = "invite_users-proceed"
        let userProfile = "invite_users-user_profile"
    }
    
    struct LoginScreen {
        let emailUsername = "login-email_username"
        let password = "login-password"
        let `continue` = "login-continue"
        let unsupportedServer = "login-unsupported_server"
    }
    
    struct AuthenticationStartScreen {
        let signIn = "authentication_start-sign_in"
        let signInWithQr = "authentication_start-sign_in_with_qr"
        let appVersion = "authentication_start-app_version"
        let hidden = "authentication_start-hidden"
    }
    
    struct ReportContent {
        let ignoreUser = "report_content-ignore_user"
    }
    
    struct JoinRoomScreen {
        let join = "join-room_join"
    }
    
    struct RoomScreen {
        let name = "room-name"
        let avatar = "room-avatar"
        let attachmentPickerPhotoLibrary = "room-attachment_picker_photo_library"
        let attachmentPickerDocuments = "room-attachment_picker_documents"
        let attachmentPickerCamera = "room-attachment_picker_camera"
        let attachmentPickerLocation = "room-attachment_picker_location"
        let attachmentPickerPoll = "room-attachment_picker_poll"
        let attachmentPickerTextFormatting = "room-attachment_picker_text_formatting"
        let timelineItemActionMenu = "room-timeline_item_action_menu"
        let joinCall = "room-join_call"
        let scrollToBottom = "room-scroll_to_bottom"
        
        let messageComposer = "room-message_composer"
        let sendButton = "room-send_button"

        let composerToolbar = ComposerToolbar()

        struct ComposerToolbar {
            let bold = "composer_toolbar-bold"
            let italic = "composer_toolbar-italic"
            let underline = "composer_toolbar-underline"
            let strikethrough = "composer_toolbar-strikethrough"
            let unorderedList = "composer_toolbar-unordered_list"
            let orderedList = "composer_toolbar-ordered_list"
            let indent = "composer_toolbar-indent"
            let unindent = "composer_toolbar-unindent"
            let inlineCode = "composer_toolbar-inline_code"
            let codeBlock = "composer_toolbar-code_block"
            let quote = "composer_toolbar-quote"
            let link = "composer_toolbar-link"
            let openComposeOptions = "composer_toolbar-open_compose_options"
            let closeFormattingOptions = "composer_toolbar-close-formatting-options"
        }
    }
    
    struct RoomDetailsScreen {
        let addTopic = "room_details-add_topic"
        let avatar = "room_details-avatar"
        let dmAvatar = "room_details-dm_avatar"
        let people = "room_details-people"
        let notifications = "room_details-notifications"
        let pollsHistory = "room_details-polls_history"
        let favourite = "room_details-favourite"
    }
    
    struct RoomMemberDetailsScreen {
        let ignore = "room_member_details-ignore"
        let unignore = "room_member_details-unignore"
        let directChat = "room_member_details-direct_chat"
    }
    
    struct RoomNotificationSettingsScreen {
        let allowCustomSetting = "room_notification_settings-allow_custom"
    }
    
    struct RoomRolesAndPermissionsScreen {
        let administrators = "room_roles_and_permissions-administrators"
        let moderators = "room_roles_and_permissions-moderators"
        let roomDetails = "room_roles_and_permissions-room_details"
        let messagesAndContent = "room_roles_and_permissions-messages_and_content"
        let memberModeration = "room_roles_and_permissions-member_moderation"
    }
    
    struct SecureBackupScreen {
        let keyStorage = "secure_backup-key_storage"
        let recoveryKey = "secure_backup-recovery_key"
    }
    
    struct SecureBackupKeyBackupScreen {
        let deleteKeyStorage = "secure_backup_key_backup-delete_key_storage"
    }
    
    struct SecureBackupRecoveryKeyScreen {
        let generateRecoveryKey = "secure_backup_recovery_key-generate_recovery_key"
        let copyRecoveryKey = "secure_backup_recovery_key-copy_recovery_key"
        let done = "secure_backup_recovery_key-done"
        let recoveryKeyField = "secure_backup_recovery_key-recovery_key_field"
        let confirm = "secure_backup_recovery_key-confirm"
    }
    
    struct ServerConfirmationScreen {
        let `continue` = "server_confirmation-continue"
        let changeServer = "server_confirmation-change_server"
        let serverPicker = "server_confirmation-server_picker"
    }
    
    struct SessionVerificationScreen {
        let acceptVerificationRequest = "session_verification-accept_verification_request"
        let ignoreVerificationRequest = "session_verification-ignore_verification_request"
        let requestVerification = "session_verification-request_verification"
        let startSasVerification = "session_verification-start_sas_verification"
        let acceptChallenge = "session_verification-accept_challenge"
        let declineChallenge = "session_verification-decline_challenge"
        let emojiWrapper = "session_verification-emojis"
        let verificationComplete = "session_verification-verification_complete"
    }
    
    struct SettingsScreen {
        let done = "settings-done"
        let account = "settings-account"
        let secureBackup = "settings-secure_backup"
        let notifications = "settings-notifications"
        let analytics = "settings-analytics"
        let screenLock = "settings-screen_lock"
        let reportBug = "settings-report_bug"
        let about = "settings_about"
        let blockedUsers = "settings_blocked-users"
        let advancedSettings = "settings_advanced-settings"
        let developerOptions = "settings_developer-options"
        let logout = "settings-logout"
    }
    
    struct SoftLogoutScreen {
        let title = "soft_logout-title"
        let message = "soft_logout-message"
        let password = "soft_logout-password"
        let forgotPassword = "soft_logout-forgot_password"
        let next = "soft_logout-next"
        let clearDataTitle = "soft_logout-clear_data_title"
        let clearDataMessage = "soft_logout-clear_data_message"
        let clearData = "soft_logout-clear_data"
    }
    
    struct StartChatScreen {
        let closeStartChat = "start_chat-close"
        let createRoom = "start_chat-create_room"
        let inviteFriends = "start_chat-invite_friends"
        let searchNoResults = "start_chat-search_no_results"
    }
    
    struct CreateRoomScreen {
        let create = "create_room-create"
        let roomAvatar = "create_room-room_avatar"
        let roomName = "create_room-room_name"
        let roomTopic = "create_room-room_topic"
        let mediaPicker = "create_room-media_picker"
    }

    struct PollFormScreen {
        let addOption = "poll_form-add_option"
        let pollKind = "poll_form-kind"
        let question = "poll_form-question"
        let submit = "poll_form-submit"

        private let optionPrefix = "poll_form-option"
        func optionID(_ index: Int) -> String {
            "\(optionPrefix)-\(index)"
        }
    }
    
    struct NotificationSettingsScreen {
        let fixMismatchConfiguration = "notification_settings_screen-fix_mismatch_configuration"
    }
    
    struct NotificationSettingsEditScreen {
        let roomNamePrefix = "notification_settings_edit_screen-room_name"
        func roomName(_ name: String) -> String {
            "\(roomNamePrefix):\(name)"
        }
    }
    
    struct RoomPollsHistoryScreen {
        let loadMore = "room_polls_history_screen-load_more"
    }
    
    struct ManageRoomMemberSheet {
        let viewProfile = "manage_room_member_sheet-view_profile"
    }
    
    struct SpaceListScreen {
        let userAvatar = "space_list_screen-user_avatar"
        
        let roomNamePrefix = "space_list_screen-room_name"
        func spaceRoomName(_ name: String) -> String {
            "\(roomNamePrefix):\(name)"
        }
    }
}
