//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

struct A11yIdentifiers {
    static let analyticsPromptScreen = AnalyticsPromptScreen()
    static let bugReportScreen = BugReportScreen()
    static let changeServerScreen = ChangeServer()
    static let homeScreen = HomeScreen()
    static let loginScreen = LoginScreen()
    static let onboardingScreen = OnboardingScreen()
    static let reportContent = ReportContent()
    static let roomScreen = RoomScreen()
    static let roomDetailsScreen = RoomDetailsScreen()
    static let serverConfirmationScreen = ServerConfirmationScreen()
    static let sessionVerificationScreen = SessionVerificationScreen()
    static let softLogoutScreen = SoftLogoutScreen()
    static let startChatScreen = StartChatScreen()
    static let roomMemberDetailsScreen = RoomMemberDetailsScreen()
    static let createRoomScreen = CreateRoomScreen()
    static let invitesScreen = InvitesScreen()
    
    struct AnalyticsPromptScreen {
        let title = "analytics_prompt-title"
        let enable = "analytics_prompt-enable"
        let notNow = "analytics_prompt-not_now"
    }

    struct BugReportScreen {
        let report = "bug_report-report"
        let sendLogs = "bug_report-send_logs"
        let screenshot = "bug_report-screenshot"
        let removeScreenshot = "bug_report-remove_screenshot"
        let attachScreenshot = "bug-report-attach_screenshot"
    }
    
    struct ChangeServer {
        let server = "change_server-server"
        let `continue` = "change_server-continue"
        let dismiss = "change_server-dismiss"
    }
    
    struct HomeScreen {
        let userAvatar = "home_screen-user_avatar"
        let settings = "home_screen-settings"
        let signOut = "home_screen-sign_out"
        let verificationBannerContinue = "home_screen-verification_continue"
        func roomName(_ name: String) -> String {
            "home_screen-room_name:\(name)"
        }
    }
    
    struct InvitesScreen {
        let noInvites = "invites-no_invites"
        let accept = "invites-accept"
        let decline = "invites-decline"
    }

    struct LoginScreen {
        let emailUsername = "login-email_username"
        let password = "login-password"
        let `continue` = "login-continue"
        let unsupportedServer = "login-unsupported_server"
    }
    
    struct OnboardingScreen {
        let signIn = "onboarding-sign_in"
        let hidden = "onboarding-hidden"
    }
    
    struct ReportContent {
        let ignoreUser = "report_content-ignore_user"
    }
        
    struct RoomScreen {
        let name = "room-name"
        let avatar = "room-avatar"
        let attachmentPicker = "room-attachment_picker"
    }
    
    struct RoomDetailsScreen {
        let addTopic = "room_details-add_topic"
        let avatar = "room_details-avatar"
        let dmAvatar = "room_details-dm_avatar"
        let people = "room_details-people"
        let invite = "room_details-invite"
    }
    
    struct RoomMemberDetailsScreen {
        let ignore = "room_member_details-ignore"
        let unignore = "room_member_details-unignore"
    }
    
    struct ServerConfirmationScreen {
        let `continue` = "server_confirmation-continue"
        let changeServer = "server_confirmation-change_server"
    }
    
    struct SessionVerificationScreen {
        let requestVerification = "session_verification-request_verification"
        let startSasVerification = "session_verification-start_sas_verification"
        let acceptChallenge = "session_verification-accept_challenge"
        let declineChallenge = "session_verification-decline_challenge"
        let emojiWrapper = "session_verification-emojis"
        let verificationComplete = "session_verification-verification_complete"
        let close = "session_verification-close"
    }
    
    struct SoftLogoutScreen {
        let title = "soft_logout-title"
        let message = "soft_logout-message"
        let password = "soft_logout-password"
        let forgotPassword = "soft_logout-forgot_password"
        let next = "soft_logout-next"
        let unsupportedServer = "soft_logout-unsupported_server"
        let clearDataTitle = "soft_logout-clear_data_title"
        let clearDataMessage = "soft_logout-clear_data_message"
        let clearData = "soft_logout-clear_data"
    }
    
    struct StartChatScreen {
        let closeStartChat = "start_chat-close"
        let inviteFriends = "start_chat-invite_friends"
        let searchNoResults = "start_chat-search_no_results"
    }
    
    struct CreateRoomScreen {
        let roomName = "create_room-room_name"
        let roomTopic = "create_room-room_topic"
    }
}
