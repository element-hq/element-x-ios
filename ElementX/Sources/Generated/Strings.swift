// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Thêm phản ứng: %1$@
  internal static func a11yAddReaction(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_add_reaction", String(describing: p1))
  }
  /// Avatar
  internal static var a11yAvatar: String { return L10n.tr("Localizable", "a11y_avatar") }
  /// Xóa
  internal static var a11yDelete: String { return L10n.tr("Localizable", "a11y_delete") }
  /// Plural format key: "%#@COUNT@"
  internal static func a11yDigitsEntered(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_digits_entered", p1)
  }
  /// Chỉnh sửa avatar
  internal static var a11yEditAvatar: String { return L10n.tr("Localizable", "a11y_edit_avatar") }
  /// Địa chỉ đầy đủ sẽ là %1$@
  internal static func a11yEditRoomAddressHint(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_edit_room_address_hint", String(describing: p1))
  }
  /// Ẩn mật khẩu
  internal static var a11yHidePassword: String { return L10n.tr("Localizable", "a11y_hide_password") }
  /// Tham gia cuộc gọi
  internal static var a11yJoinCall: String { return L10n.tr("Localizable", "a11y_join_call") }
  /// Nhảy xuống dưới
  internal static var a11yJumpToBottom: String { return L10n.tr("Localizable", "a11y_jump_to_bottom") }
  /// Chỉ nhắc đến
  internal static var a11yNotificationsMentionsOnly: String { return L10n.tr("Localizable", "a11y_notifications_mentions_only") }
  /// Đã tắt tiếng
  internal static var a11yNotificationsMuted: String { return L10n.tr("Localizable", "a11y_notifications_muted") }
  /// Nhắc đến mới
  internal static var a11yNotificationsNewMentions: String { return L10n.tr("Localizable", "a11y_notifications_new_mentions") }
  /// Tin nhắn mới
  internal static var a11yNotificationsNewMessages: String { return L10n.tr("Localizable", "a11y_notifications_new_messages") }
  /// Cuộc gọi đang diễn ra
  internal static var a11yNotificationsOngoingCall: String { return L10n.tr("Localizable", "a11y_notifications_ongoing_call") }
  /// Trang %1$d
  internal static func a11yPageN(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_page_n", p1)
  }
  /// Tạm dừng
  internal static var a11yPause: String { return L10n.tr("Localizable", "a11y_pause") }
  /// Tin nhắn thoại, thời lượng: %1$@, vị trí hiện tại: %2$@
  internal static func a11yPausedVoiceMessage(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "a11y_paused_voice_message", String(describing: p1), String(describing: p2))
  }
  /// Trường PIN
  internal static var a11yPinField: String { return L10n.tr("Localizable", "a11y_pin_field") }
  /// Phát
  internal static var a11yPlay: String { return L10n.tr("Localizable", "a11y_play") }
  /// Bình chọn
  internal static var a11yPoll: String { return L10n.tr("Localizable", "a11y_poll") }
  /// Kết thúc bình chọn
  internal static var a11yPollEnd: String { return L10n.tr("Localizable", "a11y_poll_end") }
  /// Plural format key: "%#@COUNT@"
  internal static func a11yPollsPercentOfTotal(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_polls_percent_of_total", p1)
  }
  /// Sẽ xóa lựa chọn trước đó
  internal static var a11yPollsWillRemoveSelection: String { return L10n.tr("Localizable", "a11y_polls_will_remove_selection") }
  /// Đây là câu trả lời thắng cuộc
  internal static var a11yPollsWinningAnswer: String { return L10n.tr("Localizable", "a11y_polls_winning_answer") }
  /// Phản ứng bằng %1$@
  internal static func a11yReactWith(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_react_with", String(describing: p1))
  }
  /// Phản ứng bằng emoji khác
  internal static var a11yReactWithOtherEmojis: String { return L10n.tr("Localizable", "a11y_react_with_other_emojis") }
  /// Đã đọc bởi %1$@ và %2$@
  internal static func a11yReadReceiptsMultiple(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "a11y_read_receipts_multiple", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func a11yReadReceiptsMultipleWithOthers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "a11y_read_receipts_multiple_with_others", p1)
  }
  /// Đã đọc bởi %1$@
  internal static func a11yReadReceiptsSingle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_read_receipts_single", String(describing: p1))
  }
  /// Chạm để hiển thị tất cả
  internal static var a11yReadReceiptsTapToShowAll: String { return L10n.tr("Localizable", "a11y_read_receipts_tap_to_show_all") }
  /// Xóa phản ứng: %1$@
  internal static func a11yRemoveReaction(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_remove_reaction", String(describing: p1))
  }
  /// Xóa phản ứng bằng %1$@
  internal static func a11yRemoveReactionWith(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_remove_reaction_with", String(describing: p1))
  }
  /// Gửi tệp
  internal static var a11ySendFiles: String { return L10n.tr("Localizable", "a11y_send_files") }
  /// Hiển thị mật khẩu
  internal static var a11yShowPassword: String { return L10n.tr("Localizable", "a11y_show_password") }
  /// Bắt đầu cuộc gọi
  internal static var a11yStartCall: String { return L10n.tr("Localizable", "a11y_start_call") }
  /// Cần hành động trong thời gian giới hạn
  internal static var a11yTimeLimitedActionRequired: String { return L10n.tr("Localizable", "a11y_time_limited_action_required") }
  /// Phòng đã bị hủy
  internal static var a11yTombstonedRoom: String { return L10n.tr("Localizable", "a11y_tombstoned_room") }
  /// Menu người dùng
  internal static var a11yUserMenu: String { return L10n.tr("Localizable", "a11y_user_menu") }
  /// Xem avatar
  internal static var a11yViewAvatar: String { return L10n.tr("Localizable", "a11y_view_avatar") }
  /// Xem chi tiết
  internal static var a11yViewDetails: String { return L10n.tr("Localizable", "a11y_view_details") }
  /// Tin nhắn thoại, thời lượng: %1$@
  internal static func a11yVoiceMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "a11y_voice_message", String(describing: p1))
  }
  /// Ghi âm tin nhắn thoại.
  internal static var a11yVoiceMessageRecord: String { return L10n.tr("Localizable", "a11y_voice_message_record") }
  /// Dừng ghi âm
  internal static var a11yVoiceMessageStopRecording: String { return L10n.tr("Localizable", "a11y_voice_message_stop_recording") }
  /// Chấp nhận
  internal static var actionAccept: String { return L10n.tr("Localizable", "action_accept") }
  /// Thêm chú thích
  internal static var actionAddCaption: String { return L10n.tr("Localizable", "action_add_caption") }
  /// Thêm vào dòng thời gian
  internal static var actionAddToTimeline: String { return L10n.tr("Localizable", "action_add_to_timeline") }
  /// Quay lại
  internal static var actionBack: String { return L10n.tr("Localizable", "action_back") }
  /// Gọi
  internal static var actionCall: String { return L10n.tr("Localizable", "action_call") }
  /// Hủy
  internal static var actionCancel: String { return L10n.tr("Localizable", "action_cancel") }
  /// Hủy bây giờ
  internal static var actionCancelForNow: String { return L10n.tr("Localizable", "action_cancel_for_now") }
  /// Chọn ảnh
  internal static var actionChoosePhoto: String { return L10n.tr("Localizable", "action_choose_photo") }
  /// Xóa
  internal static var actionClear: String { return L10n.tr("Localizable", "action_clear") }
  /// Đóng
  internal static var actionClose: String { return L10n.tr("Localizable", "action_close") }
  /// Hoàn thành xác minh
  internal static var actionCompleteVerification: String { return L10n.tr("Localizable", "action_complete_verification") }
  /// Xác nhận
  internal static var actionConfirm: String { return L10n.tr("Localizable", "action_confirm") }
  /// Xác nhận mật khẩu
  internal static var actionConfirmPassword: String { return L10n.tr("Localizable", "action_confirm_password") }
  /// Tiếp tục
  internal static var actionContinue: String { return L10n.tr("Localizable", "action_continue") }
  /// Sao chép
  internal static var actionCopy: String { return L10n.tr("Localizable", "action_copy") }
  /// Sao chép chú thích
  internal static var actionCopyCaption: String { return L10n.tr("Localizable", "action_copy_caption") }
  /// Sao chép liên kết
  internal static var actionCopyLink: String { return L10n.tr("Localizable", "action_copy_link") }
  /// Sao chép liên kết đến tin nhắn
  internal static var actionCopyLinkToMessage: String { return L10n.tr("Localizable", "action_copy_link_to_message") }
  /// Sao chép văn bản
  internal static var actionCopyText: String { return L10n.tr("Localizable", "action_copy_text") }
  /// Tạo
  internal static var actionCreate: String { return L10n.tr("Localizable", "action_create") }
  /// Tạo phòng
  internal static var actionCreateARoom: String { return L10n.tr("Localizable", "action_create_a_room") }
  /// Vô hiệu hóa
  internal static var actionDeactivate: String { return L10n.tr("Localizable", "action_deactivate") }
  /// Vô hiệu hóa tài khoản
  internal static var actionDeactivateAccount: String { return L10n.tr("Localizable", "action_deactivate_account") }
  /// Từ chối
  internal static var actionDecline: String { return L10n.tr("Localizable", "action_decline") }
  /// Từ chối và chặn
  internal static var actionDeclineAndBlock: String { return L10n.tr("Localizable", "action_decline_and_block") }
  /// Xóa bình chọn
  internal static var actionDeletePoll: String { return L10n.tr("Localizable", "action_delete_poll") }
  /// Tắt
  internal static var actionDisable: String { return L10n.tr("Localizable", "action_disable") }
  /// Bỏ
  internal static var actionDiscard: String { return L10n.tr("Localizable", "action_discard") }
  /// Loại bỏ
  internal static var actionDismiss: String { return L10n.tr("Localizable", "action_dismiss") }
  /// Xong
  internal static var actionDone: String { return L10n.tr("Localizable", "action_done") }
  /// Chỉnh sửa
  internal static var actionEdit: String { return L10n.tr("Localizable", "action_edit") }
  /// Chỉnh sửa chú thích
  internal static var actionEditCaption: String { return L10n.tr("Localizable", "action_edit_caption") }
  /// Chỉnh sửa bình chọn
  internal static var actionEditPoll: String { return L10n.tr("Localizable", "action_edit_poll") }
  /// Bật
  internal static var actionEnable: String { return L10n.tr("Localizable", "action_enable") }
  /// Kết thúc bình chọn
  internal static var actionEndPoll: String { return L10n.tr("Localizable", "action_end_poll") }
  /// Nhập PIN
  internal static var actionEnterPin: String { return L10n.tr("Localizable", "action_enter_pin") }
  /// Quên mật khẩu?
  internal static var actionForgotPassword: String { return L10n.tr("Localizable", "action_forgot_password") }
  /// Chuyển tiếp
  internal static var actionForward: String { return L10n.tr("Localizable", "action_forward") }
  /// Quay lại
  internal static var actionGoBack: String { return L10n.tr("Localizable", "action_go_back") }
  /// Bỏ qua
  internal static var actionIgnore: String { return L10n.tr("Localizable", "action_ignore") }
  /// Mời
  internal static var actionInvite: String { return L10n.tr("Localizable", "action_invite") }
  /// Mời mọi người
  internal static var actionInviteFriends: String { return L10n.tr("Localizable", "action_invite_friends") }
  /// Mời mọi người đến %1$@
  internal static func actionInviteFriendsToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_friends_to_app", String(describing: p1))
  }
  /// Mời mọi người đến %1$@
  internal static func actionInvitePeopleToApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "action_invite_people_to_app", String(describing: p1))
  }
  /// Danh sách lời mời
  internal static var actionInvitesList: String { return L10n.tr("Localizable", "action_invites_list") }
  /// Tham gia
  internal static var actionJoin: String { return L10n.tr("Localizable", "action_join") }
  /// Tìm hiểu thêm
  internal static var actionLearnMore: String { return L10n.tr("Localizable", "action_learn_more") }
  /// Rời
  internal static var actionLeave: String { return L10n.tr("Localizable", "action_leave") }
  /// Rời cuộc trò chuyện
  internal static var actionLeaveConversation: String { return L10n.tr("Localizable", "action_leave_conversation") }
  /// Rời phòng
  internal static var actionLeaveRoom: String { return L10n.tr("Localizable", "action_leave_room") }
  /// Tải thêm
  internal static var actionLoadMore: String { return L10n.tr("Localizable", "action_load_more") }
  /// Quản lý tài khoản
  internal static var actionManageAccount: String { return L10n.tr("Localizable", "action_manage_account") }
  /// Quản lý thiết bị
  internal static var actionManageDevices: String { return L10n.tr("Localizable", "action_manage_devices") }
  /// Tin nhắn
  internal static var actionMessage: String { return L10n.tr("Localizable", "action_message") }
  /// Tiếp theo
  internal static var actionNext: String { return L10n.tr("Localizable", "action_next") }
  /// Không
  internal static var actionNo: String { return L10n.tr("Localizable", "action_no") }
  /// Không phải bây giờ
  internal static var actionNotNow: String { return L10n.tr("Localizable", "action_not_now") }
  /// OK
  internal static var actionOk: String { return L10n.tr("Localizable", "action_ok") }
  /// Cài đặt
  internal static var actionOpenSettings: String { return L10n.tr("Localizable", "action_open_settings") }
  /// Mở bằng
  internal static var actionOpenWith: String { return L10n.tr("Localizable", "action_open_with") }
  /// Ghim
  internal static var actionPin: String { return L10n.tr("Localizable", "action_pin") }
  /// Trả lời nhanh
  internal static var actionQuickReply: String { return L10n.tr("Localizable", "action_quick_reply") }
  /// Trích dẫn
  internal static var actionQuote: String { return L10n.tr("Localizable", "action_quote") }
  /// Phản ứng
  internal static var actionReact: String { return L10n.tr("Localizable", "action_react") }
  /// Từ chối
  internal static var actionReject: String { return L10n.tr("Localizable", "action_reject") }
  /// Xóa
  internal static var actionRemove: String { return L10n.tr("Localizable", "action_remove") }
  /// Xóa chú thích
  internal static var actionRemoveCaption: String { return L10n.tr("Localizable", "action_remove_caption") }
  /// Xóa tin nhắn
  internal static var actionRemoveMessage: String { return L10n.tr("Localizable", "action_remove_message") }
  /// Trả lời
  internal static var actionReply: String { return L10n.tr("Localizable", "action_reply") }
  /// Trả lời trong chuỗi
  internal static var actionReplyInThread: String { return L10n.tr("Localizable", "action_reply_in_thread") }
  /// Báo cáo
  internal static var actionReport: String { return L10n.tr("Localizable", "action_report") }
  /// Báo cáo lỗi
  internal static var actionReportBug: String { return L10n.tr("Localizable", "action_report_bug") }
  /// Báo cáo nội dung
  internal static var actionReportContent: String { return L10n.tr("Localizable", "action_report_content") }
  /// Báo cáo cuộc trò chuyện
  internal static var actionReportDm: String { return L10n.tr("Localizable", "action_report_dm") }
  /// Báo cáo phòng
  internal static var actionReportRoom: String { return L10n.tr("Localizable", "action_report_room") }
  /// Đặt lại
  internal static var actionReset: String { return L10n.tr("Localizable", "action_reset") }
  /// Đặt lại danh tính
  internal static var actionResetIdentity: String { return L10n.tr("Localizable", "action_reset_identity") }
  /// Thử lại
  internal static var actionRetry: String { return L10n.tr("Localizable", "action_retry") }
  /// Thử giải mã lại
  internal static var actionRetryDecryption: String { return L10n.tr("Localizable", "action_retry_decryption") }
  /// Lưu
  internal static var actionSave: String { return L10n.tr("Localizable", "action_save") }
  /// Tìm kiếm
  internal static var actionSearch: String { return L10n.tr("Localizable", "action_search") }
  /// Gửi
  internal static var actionSend: String { return L10n.tr("Localizable", "action_send") }
  /// Gửi tin nhắn
  internal static var actionSendMessage: String { return L10n.tr("Localizable", "action_send_message") }
  /// Chia sẻ
  internal static var actionShare: String { return L10n.tr("Localizable", "action_share") }
  /// Chia sẻ liên kết
  internal static var actionShareLink: String { return L10n.tr("Localizable", "action_share_link") }
  /// Hiển thị
  internal static var actionShow: String { return L10n.tr("Localizable", "action_show") }
  /// Đăng nhập lại
  internal static var actionSignInAgain: String { return L10n.tr("Localizable", "action_sign_in_again") }
  /// Đăng xuất
  internal static var actionSignout: String { return L10n.tr("Localizable", "action_signout") }
  /// Đăng xuất dù sao
  internal static var actionSignoutAnyway: String { return L10n.tr("Localizable", "action_signout_anyway") }
  /// Bỏ qua
  internal static var actionSkip: String { return L10n.tr("Localizable", "action_skip") }
  /// Bắt đầu
  internal static var actionStart: String { return L10n.tr("Localizable", "action_start") }
  /// Bắt đầu trò chuyện
  internal static var actionStartChat: String { return L10n.tr("Localizable", "action_start_chat") }
  /// Bắt đầu xác minh
  internal static var actionStartVerification: String { return L10n.tr("Localizable", "action_start_verification") }
  /// Chạm để tải bản đồ
  internal static var actionStaticMapLoad: String { return L10n.tr("Localizable", "action_static_map_load") }
  /// Chụp ảnh
  internal static var actionTakePhoto: String { return L10n.tr("Localizable", "action_take_photo") }
  /// Chạm để xem tùy chọn
  internal static var actionTapForOptions: String { return L10n.tr("Localizable", "action_tap_for_options") }
  /// Thử lại
  internal static var actionTryAgain: String { return L10n.tr("Localizable", "action_try_again") }
  /// Bỏ ghim
  internal static var actionUnpin: String { return L10n.tr("Localizable", "action_unpin") }
  /// Xem trong dòng thời gian
  internal static var actionViewInTimeline: String { return L10n.tr("Localizable", "action_view_in_timeline") }
  /// Xem nguồn
  internal static var actionViewSource: String { return L10n.tr("Localizable", "action_view_source") }
  /// Có
  internal static var actionYes: String { return L10n.tr("Localizable", "action_yes") }
  /// Có, thử lại
  internal static var actionYesTryAgain: String { return L10n.tr("Localizable", "action_yes_try_again") }
  /// Đăng xuất & nâng cấp
  internal static var bannerMigrateToNativeSlidingSyncAction: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_action") }
  /// %1$@ không còn hỗ trợ giao thức cũ. Vui lòng đăng xuất và đăng nhập lại để tiếp tục sử dụng ứng dụng.
  internal static func bannerMigrateToNativeSlidingSyncAppForceLogoutTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_app_force_logout_title", String(describing: p1))
  }
  /// Máy chủ của bạn giờ hỗ trợ giao thức mới, nhanh hơn. Đăng xuất và đăng nhập lại để nâng cấp ngay. Làm điều này bây giờ sẽ giúp bạn tránh bị buộc đăng xuất khi giao thức cũ bị loại bỏ sau này.
  internal static var bannerMigrateToNativeSlidingSyncDescription: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_description") }
  /// Homeserver của bạn không còn hỗ trợ giao thức cũ. Vui lòng đăng xuất và đăng nhập lại để tiếp tục sử dụng ứng dụng.
  internal static var bannerMigrateToNativeSlidingSyncForceLogoutTitle: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_force_logout_title") }
  /// Có bản nâng cấp
  internal static var bannerMigrateToNativeSlidingSyncTitle: String { return L10n.tr("Localizable", "banner_migrate_to_native_sliding_sync_title") }
  /// Khôi phục danh tính mã hóa và lịch sử tin nhắn bằng khóa khôi phục nếu bạn đã mất tất cả thiết bị hiện có.
  internal static var bannerSetUpRecoveryContent: String { return L10n.tr("Localizable", "banner_set_up_recovery_content") }
  /// Thiết lập khôi phục
  internal static var bannerSetUpRecoverySubmit: String { return L10n.tr("Localizable", "banner_set_up_recovery_submit") }
  /// Thiết lập khôi phục để bảo vệ tài khoản
  internal static var bannerSetUpRecoveryTitle: String { return L10n.tr("Localizable", "banner_set_up_recovery_title") }
  /// Element Call không hỗ trợ sử dụng thiết bị âm thanh Bluetooth trong phiên bản Android này. Vui lòng chọn thiết bị âm thanh khác.
  internal static var callInvalidAudioDeviceBluetoothDevicesDisabled: String { return L10n.tr("Localizable", "call_invalid_audio_device_bluetooth_devices_disabled") }
  /// Giới thiệu
  internal static var commonAbout: String { return L10n.tr("Localizable", "common_about") }
  /// Chính sách sử dụng chấp nhận được
  internal static var commonAcceptableUsePolicy: String { return L10n.tr("Localizable", "common_acceptable_use_policy") }
  /// Đang thêm chú thích
  internal static var commonAddingCaption: String { return L10n.tr("Localizable", "common_adding_caption") }
  /// Cài đặt nâng cao
  internal static var commonAdvancedSettings: String { return L10n.tr("Localizable", "common_advanced_settings") }
  /// một hình ảnh
  internal static var commonAnImage: String { return L10n.tr("Localizable", "common_an_image") }
  /// Phân tích
  internal static var commonAnalytics: String { return L10n.tr("Localizable", "common_analytics") }
  /// Giao diện
  internal static var commonAppearance: String { return L10n.tr("Localizable", "common_appearance") }
  /// Âm thanh
  internal static var commonAudio: String { return L10n.tr("Localizable", "common_audio") }
  /// Người dùng bị chặn
  internal static var commonBlockedUsers: String { return L10n.tr("Localizable", "common_blocked_users") }
  /// Bong bóng
  internal static var commonBubbles: String { return L10n.tr("Localizable", "common_bubbles") }
  /// Cuộc gọi đã bắt đầu
  internal static var commonCallStarted: String { return L10n.tr("Localizable", "common_call_started") }
  /// Sao lưu trò chuyện
  internal static var commonChatBackup: String { return L10n.tr("Localizable", "common_chat_backup") }
  /// Đã sao chép vào clipboard
  internal static var commonCopiedToClipboard: String { return L10n.tr("Localizable", "common_copied_to_clipboard") }
  /// Bản quyền
  internal static var commonCopyright: String { return L10n.tr("Localizable", "common_copyright") }
  /// Đang tạo phòng…
  internal static var commonCreatingRoom: String { return L10n.tr("Localizable", "common_creating_room") }
  /// Yêu cầu đã hủy
  internal static var commonCurrentUserCanceledKnock: String { return L10n.tr("Localizable", "common_current_user_canceled_knock") }
  /// Đã rời phòng
  internal static var commonCurrentUserLeftRoom: String { return L10n.tr("Localizable", "common_current_user_left_room") }
  /// Lời mời đã từ chối
  internal static var commonCurrentUserRejectedInvite: String { return L10n.tr("Localizable", "common_current_user_rejected_invite") }
  /// Tối
  internal static var commonDark: String { return L10n.tr("Localizable", "common_dark") }
  /// %1$@ lúc %2$@
  internal static func commonDateDateAtTime(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "common_date_date_at_time", String(describing: p1), String(describing: p2))
  }
  /// Tháng này
  internal static var commonDateThisMonth: String { return L10n.tr("Localizable", "common_date_this_month") }
  /// Lỗi giải mã
  internal static var commonDecryptionError: String { return L10n.tr("Localizable", "common_decryption_error") }
  /// Tùy chọn nhà phát triển
  internal static var commonDeveloperOptions: String { return L10n.tr("Localizable", "common_developer_options") }
  /// ID thiết bị
  internal static var commonDeviceId: String { return L10n.tr("Localizable", "common_device_id") }
  /// Trò chuyện trực tiếp
  internal static var commonDirectChat: String { return L10n.tr("Localizable", "common_direct_chat") }
  /// Không hiển thị lại
  internal static var commonDoNotShowThisAgain: String { return L10n.tr("Localizable", "common_do_not_show_this_again") }
  /// Tải xuống thất bại
  internal static var commonDownloadFailed: String { return L10n.tr("Localizable", "common_download_failed") }
  /// Đang tải xuống
  internal static var commonDownloading: String { return L10n.tr("Localizable", "common_downloading") }
  /// (đã chỉnh sửa)
  internal static var commonEditedSuffix: String { return L10n.tr("Localizable", "common_edited_suffix") }
  /// Đang chỉnh sửa
  internal static var commonEditing: String { return L10n.tr("Localizable", "common_editing") }
  /// Đang chỉnh sửa chú thích
  internal static var commonEditingCaption: String { return L10n.tr("Localizable", "common_editing_caption") }
  /// * %1$@ %2$@
  internal static func commonEmote(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "common_emote", String(describing: p1), String(describing: p2))
  }
  /// Tệp trống
  internal static var commonEmptyFile: String { return L10n.tr("Localizable", "common_empty_file") }
  /// Mã hóa
  internal static var commonEncryption: String { return L10n.tr("Localizable", "common_encryption") }
  /// Đã bật mã hóa
  internal static var commonEncryptionEnabled: String { return L10n.tr("Localizable", "common_encryption_enabled") }
  /// Nhập PIN của bạn
  internal static var commonEnterYourPin: String { return L10n.tr("Localizable", "common_enter_your_pin") }
  /// Lỗi
  internal static var commonError: String { return L10n.tr("Localizable", "common_error") }
  /// Mọi người
  internal static var commonEveryone: String { return L10n.tr("Localizable", "common_everyone") }
  /// Face ID
  internal static var commonFaceIdIos: String { return L10n.tr("Localizable", "common_face_id_ios") }
  /// Thất bại
  internal static var commonFailed: String { return L10n.tr("Localizable", "common_failed") }
  /// Yêu thích
  internal static var commonFavourite: String { return L10n.tr("Localizable", "common_favourite") }
  /// Đã yêu thích
  internal static var commonFavourited: String { return L10n.tr("Localizable", "common_favourited") }
  /// Tệp
  internal static var commonFile: String { return L10n.tr("Localizable", "common_file") }
  /// Tệp đã xóa
  internal static var commonFileDeleted: String { return L10n.tr("Localizable", "common_file_deleted") }
  /// Tệp đã lưu
  internal static var commonFileSaved: String { return L10n.tr("Localizable", "common_file_saved") }
  /// Chuyển tiếp tin nhắn
  internal static var commonForwardMessage: String { return L10n.tr("Localizable", "common_forward_message") }
  /// Sử dụng thường xuyên
  internal static var commonFrequentlyUsed: String { return L10n.tr("Localizable", "common_frequently_used") }
  /// GIF
  internal static var commonGif: String { return L10n.tr("Localizable", "common_gif") }
  /// Hình ảnh
  internal static var commonImage: String { return L10n.tr("Localizable", "common_image") }
  /// Trả lời %1$@
  internal static func commonInReplyTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_in_reply_to", String(describing: p1))
  }
  /// Không tìm thấy Matrix ID này, nên lời mời có thể không được nhận.
  internal static var commonInviteUnknownProfile: String { return L10n.tr("Localizable", "common_invite_unknown_profile") }
  /// Đang rời phòng
  internal static var commonLeavingRoom: String { return L10n.tr("Localizable", "common_leaving_room") }
  /// Sáng
  internal static var commonLight: String { return L10n.tr("Localizable", "common_light") }
  /// Dòng đã sao chép vào clipboard
  internal static var commonLineCopiedToClipboard: String { return L10n.tr("Localizable", "common_line_copied_to_clipboard") }
  /// Liên kết đã sao chép vào clipboard
  internal static var commonLinkCopiedToClipboard: String { return L10n.tr("Localizable", "common_link_copied_to_clipboard") }
  /// Đang tải…
  internal static var commonLoading: String { return L10n.tr("Localizable", "common_loading") }
  /// Đang tải thêm…
  internal static var commonLoadingMore: String { return L10n.tr("Localizable", "common_loading_more") }
  /// Plural format key: "%#@COUNT@"
  internal static func commonManyMembers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_many_members", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func commonMemberCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_member_count", p1)
  }
  /// Tin nhắn
  internal static var commonMessage: String { return L10n.tr("Localizable", "common_message") }
  /// Hành động tin nhắn
  internal static var commonMessageActions: String { return L10n.tr("Localizable", "common_message_actions") }
  /// Bố cục tin nhắn
  internal static var commonMessageLayout: String { return L10n.tr("Localizable", "common_message_layout") }
  /// Tin nhắn đã xóa
  internal static var commonMessageRemoved: String { return L10n.tr("Localizable", "common_message_removed") }
  /// Hiện đại
  internal static var commonModern: String { return L10n.tr("Localizable", "common_modern") }
  /// Tắt tiếng
  internal static var commonMute: String { return L10n.tr("Localizable", "common_mute") }
  /// %1$@ (%2$@)
  internal static func commonNameAndId(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "common_name_and_id", String(describing: p1), String(describing: p2))
  }
  /// Không có kết quả
  internal static var commonNoResults: String { return L10n.tr("Localizable", "common_no_results") }
  /// Không có tên phòng
  internal static var commonNoRoomName: String { return L10n.tr("Localizable", "common_no_room_name") }
  /// Chưa mã hóa
  internal static var commonNotEncrypted: String { return L10n.tr("Localizable", "common_not_encrypted") }
  /// Ngoại tuyến
  internal static var commonOffline: String { return L10n.tr("Localizable", "common_offline") }
  /// Giấy phép mã nguồn mở
  internal static var commonOpenSourceLicenses: String { return L10n.tr("Localizable", "common_open_source_licenses") }
  /// Optic ID
  internal static var commonOpticIdIos: String { return L10n.tr("Localizable", "common_optic_id_ios") }
  /// hoặc
  internal static var commonOr: String { return L10n.tr("Localizable", "common_or") }
  /// Mật khẩu
  internal static var commonPassword: String { return L10n.tr("Localizable", "common_password") }
  /// Mọi người
  internal static var commonPeople: String { return L10n.tr("Localizable", "common_people") }
  /// Liên kết cố định
  internal static var commonPermalink: String { return L10n.tr("Localizable", "common_permalink") }
  /// Quyền
  internal static var commonPermission: String { return L10n.tr("Localizable", "common_permission") }
  /// Đã ghim
  internal static var commonPinned: String { return L10n.tr("Localizable", "common_pinned") }
  /// Vui lòng kiểm tra kết nối internet
  internal static var commonPleaseCheckInternetConnection: String { return L10n.tr("Localizable", "common_please_check_internet_connection") }
  /// Vui lòng chờ…
  internal static var commonPleaseWait: String { return L10n.tr("Localizable", "common_please_wait") }
  /// Bạn có chắc chắn muốn kết thúc cuộc bình chọn này?
  internal static var commonPollEndConfirmation: String { return L10n.tr("Localizable", "common_poll_end_confirmation") }
  /// Bình chọn: %1$@
  internal static func commonPollSummary(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_poll_summary", String(describing: p1))
  }
  /// Tổng số phiếu: %1$@
  internal static func commonPollTotalVotes(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_poll_total_votes", String(describing: p1))
  }
  /// Kết quả sẽ hiển thị sau khi kết thúc bình chọn
  internal static var commonPollUndisclosedText: String { return L10n.tr("Localizable", "common_poll_undisclosed_text") }
  /// Plural format key: "%#@COUNT@"
  internal static func commonPollVotesCount(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_poll_votes_count", p1)
  }
  /// Đang chuẩn bị…
  internal static var commonPreparing: String { return L10n.tr("Localizable", "common_preparing") }
  /// Chính sách riêng tư
  internal static var commonPrivacyPolicy: String { return L10n.tr("Localizable", "common_privacy_policy") }
  /// Phản ứng
  internal static var commonReaction: String { return L10n.tr("Localizable", "common_reaction") }
  /// Phản ứng
  internal static var commonReactions: String { return L10n.tr("Localizable", "common_reactions") }
  /// Lý do
  internal static var commonReason: String { return L10n.tr("Localizable", "common_reason") }
  /// Khóa khôi phục
  internal static var commonRecoveryKey: String { return L10n.tr("Localizable", "common_recovery_key") }
  /// Đang làm mới…
  internal static var commonRefreshing: String { return L10n.tr("Localizable", "common_refreshing") }
  /// Plural format key: "%#@COUNT@"
  internal static func commonReplies(_ p1: Int) -> String {
    return L10n.tr("Localizable", "common_replies", p1)
  }
  /// Đang trả lời %1$@
  internal static func commonReplyingTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "common_replying_to", String(describing: p1))
  }
  /// Báo cáo lỗi
  internal static var commonReportABug: String { return L10n.tr("Localizable", "common_report_a_bug") }
  /// Báo cáo vấn đề
  internal static var commonReportAProblem: String { return L10n.tr("Localizable", "common_report_a_problem") }
  /// Báo cáo đã gửi
  internal static var commonReportSubmitted: String { return L10n.tr("Localizable", "common_report_submitted") }
  /// Trình soạn thảo văn bản phong phú
  internal static var commonRichTextEditor: String { return L10n.tr("Localizable", "common_rich_text_editor") }
  /// Phòng
  internal static var commonRoom: String { return L10n.tr("Localizable", "common_room") }
  /// Tên phòng
  internal static var commonRoomName: String { return L10n.tr("Localizable", "common_room_name") }
  /// ví dụ: tên dự án của bạn
  internal static var commonRoomNamePlaceholder: String { return L10n.tr("Localizable", "common_room_name_placeholder") }
  /// Đã lưu thay đổi
  internal static var commonSavedChanges: String { return L10n.tr("Localizable", "common_saved_changes") }
  /// Đang lưu
  internal static var commonSaving: String { return L10n.tr("Localizable", "common_saving") }
  /// Khóa màn hình
  internal static var commonScreenLock: String { return L10n.tr("Localizable", "common_screen_lock") }
  /// Tìm kiếm ai đó
  internal static var commonSearchForSomeone: String { return L10n.tr("Localizable", "common_search_for_someone") }
  /// Kết quả tìm kiếm
  internal static var commonSearchResults: String { return L10n.tr("Localizable", "common_search_results") }
  /// Bảo mật
  internal static var commonSecurity: String { return L10n.tr("Localizable", "common_security") }
  /// Đã xem bởi
  internal static var commonSeenBy: String { return L10n.tr("Localizable", "common_seen_by") }
  /// Gửi đến
  internal static var commonSendTo: String { return L10n.tr("Localizable", "common_send_to") }
  /// Đang gửi…
  internal static var commonSending: String { return L10n.tr("Localizable", "common_sending") }
  /// Gửi thất bại
  internal static var commonSendingFailed: String { return L10n.tr("Localizable", "common_sending_failed") }
  /// Đã gửi
  internal static var commonSent: String { return L10n.tr("Localizable", "common_sent") }
  /// . 
  internal static var commonSentenceDelimiter: String { return L10n.tr("Localizable", "common_sentence_delimiter") }
  /// Máy chủ không được hỗ trợ
  internal static var commonServerNotSupported: String { return L10n.tr("Localizable", "common_server_not_supported") }
  /// URL máy chủ
  internal static var commonServerUrl: String { return L10n.tr("Localizable", "common_server_url") }
  /// Cài đặt
  internal static var commonSettings: String { return L10n.tr("Localizable", "common_settings") }
  /// Vị trí đã chia sẻ
  internal static var commonSharedLocation: String { return L10n.tr("Localizable", "common_shared_location") }
  /// Đang đăng xuất
  internal static var commonSigningOut: String { return L10n.tr("Localizable", "common_signing_out") }
  /// Có gì đó không ổn
  internal static var commonSomethingWentWrong: String { return L10n.tr("Localizable", "common_something_went_wrong") }
  /// Chúng tôi gặp vấn đề. Vui lòng thử lại.
  internal static var commonSomethingWentWrongMessage: String { return L10n.tr("Localizable", "common_something_went_wrong_message") }
  /// Đang bắt đầu trò chuyện…
  internal static var commonStartingChat: String { return L10n.tr("Localizable", "common_starting_chat") }
  /// Sticker
  internal static var commonSticker: String { return L10n.tr("Localizable", "common_sticker") }
  /// Thành công
  internal static var commonSuccess: String { return L10n.tr("Localizable", "common_success") }
  /// Gợi ý
  internal static var commonSuggestions: String { return L10n.tr("Localizable", "common_suggestions") }
  /// Đang đồng bộ
  internal static var commonSyncing: String { return L10n.tr("Localizable", "common_syncing") }
  /// Hệ thống
  internal static var commonSystem: String { return L10n.tr("Localizable", "common_system") }
  /// Văn bản
  internal static var commonText: String { return L10n.tr("Localizable", "common_text") }
  /// Thông báo bên thứ ba
  internal static var commonThirdPartyNotices: String { return L10n.tr("Localizable", "common_third_party_notices") }
  /// Chuỗi
  internal static var commonThread: String { return L10n.tr("Localizable", "common_thread") }
  /// Chủ đề
  internal static var commonTopic: String { return L10n.tr("Localizable", "common_topic") }
  /// Phòng này về gì?
  internal static var commonTopicPlaceholder: String { return L10n.tr("Localizable", "common_topic_placeholder") }
  /// Touch ID
  internal static var commonTouchIdIos: String { return L10n.tr("Localizable", "common_touch_id_ios") }
  /// Không thể giải mã
  internal static var commonUnableToDecrypt: String { return L10n.tr("Localizable", "common_unable_to_decrypt") }
  /// Gửi từ thiết bị không an toàn
  internal static var commonUnableToDecryptInsecureDevice: String { return L10n.tr("Localizable", "common_unable_to_decrypt_insecure_device") }
  /// Bạn không có quyền truy cập tin nhắn này
  internal static var commonUnableToDecryptNoAccess: String { return L10n.tr("Localizable", "common_unable_to_decrypt_no_access") }
  /// Danh tính đã xác minh của người gửi đã được đặt lại
  internal static var commonUnableToDecryptVerificationViolation: String { return L10n.tr("Localizable", "common_unable_to_decrypt_verification_violation") }
  /// Không thể gửi lời mời đến một hoặc nhiều người dùng.
  internal static var commonUnableToInviteMessage: String { return L10n.tr("Localizable", "common_unable_to_invite_message") }
  /// Không thể gửi lời mời
  internal static var commonUnableToInviteTitle: String { return L10n.tr("Localizable", "common_unable_to_invite_title") }
  /// Mở khóa
  internal static var commonUnlock: String { return L10n.tr("Localizable", "common_unlock") }
  /// Bật tiếng
  internal static var commonUnmute: String { return L10n.tr("Localizable", "common_unmute") }
  /// Cuộc gọi không được hỗ trợ
  internal static var commonUnsupportedCall: String { return L10n.tr("Localizable", "common_unsupported_call") }
  /// Sự kiện không được hỗ trợ
  internal static var commonUnsupportedEvent: String { return L10n.tr("Localizable", "common_unsupported_event") }
  /// Tên người dùng
  internal static var commonUsername: String { return L10n.tr("Localizable", "common_username") }
  /// Xác minh đã hủy
  internal static var commonVerificationCancelled: String { return L10n.tr("Localizable", "common_verification_cancelled") }
  /// Xác minh hoàn thành
  internal static var commonVerificationComplete: String { return L10n.tr("Localizable", "common_verification_complete") }
  /// Xác minh thất bại
  internal static var commonVerificationFailed: String { return L10n.tr("Localizable", "common_verification_failed") }
  /// Đã xác minh
  internal static var commonVerified: String { return L10n.tr("Localizable", "common_verified") }
  /// Xác minh thiết bị
  internal static var commonVerifyDevice: String { return L10n.tr("Localizable", "common_verify_device") }
  /// Xác minh danh tính
  internal static var commonVerifyIdentity: String { return L10n.tr("Localizable", "common_verify_identity") }
  /// Xác minh người dùng
  internal static var commonVerifyUser: String { return L10n.tr("Localizable", "common_verify_user") }
  /// Video
  internal static var commonVideo: String { return L10n.tr("Localizable", "common_video") }
  /// Tin nhắn thoại
  internal static var commonVoiceMessage: String { return L10n.tr("Localizable", "common_voice_message") }
  /// Đang chờ…
  internal static var commonWaiting: String { return L10n.tr("Localizable", "common_waiting") }
  /// Đang chờ tin nhắn này
  internal static var commonWaitingForDecryptionKey: String { return L10n.tr("Localizable", "common_waiting_for_decryption_key") }
  /// Bạn
  internal static var commonYou: String { return L10n.tr("Localizable", "common_you") }
  /// Xác nhận khóa khôi phục để duy trì quyền truy cập vào kho lưu trữ khóa và lịch sử tin nhắn.
  internal static var confirmRecoveryKeyBannerMessage: String { return L10n.tr("Localizable", "confirm_recovery_key_banner_message") }
  /// Nhập khóa khôi phục
  internal static var confirmRecoveryKeyBannerPrimaryButtonTitle: String { return L10n.tr("Localizable", "confirm_recovery_key_banner_primary_button_title") }
  /// Quên khóa khôi phục?
  internal static var confirmRecoveryKeyBannerSecondaryButtonTitle: String { return L10n.tr("Localizable", "confirm_recovery_key_banner_secondary_button_title") }
  /// Kho lưu trữ khóa không đồng bộ
  internal static var confirmRecoveryKeyBannerTitle: String { return L10n.tr("Localizable", "confirm_recovery_key_banner_title") }
  /// %1$@ đã gặp sự cố lần cuối sử dụng. Bạn có muốn chia sẻ báo cáo sự cố với chúng tôi?
  internal static func crashDetectionDialogContent(_ p1: Any) -> String {
    return L10n.tr("Localizable", "crash_detection_dialog_content", String(describing: p1))
  }
  /// Danh tính của %1$@ đã được đặt lại. %2$@
  internal static func cryptoIdentityChangePinViolation(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "crypto_identity_change_pin_violation", String(describing: p1), String(describing: p2))
  }
  /// Danh tính %2$@ của %1$@ đã được đặt lại. %3$@
  internal static func cryptoIdentityChangePinViolationNew(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "crypto_identity_change_pin_violation_new", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// (%1$@)
  internal static func cryptoIdentityChangePinViolationNewUserId(_ p1: Any) -> String {
    return L10n.tr("Localizable", "crypto_identity_change_pin_violation_new_user_id", String(describing: p1))
  }
  /// Danh tính của %1$@ đã được đặt lại.
  internal static func cryptoIdentityChangeProfilePinViolation(_ p1: Any) -> String {
    return L10n.tr("Localizable", "crypto_identity_change_profile_pin_violation", String(describing: p1))
  }
  /// Danh tính %2$@ của %1$@ đã được đặt lại. %3$@
  internal static func cryptoIdentityChangeVerificationViolationNew(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "crypto_identity_change_verification_violation_new", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Rút xác minh
  internal static var cryptoIdentityChangeWithdrawVerificationAction: String { return L10n.tr("Localizable", "crypto_identity_change_withdraw_verification_action") }
  /// Liên kết %1$@ đang đưa bạn đến trang khác %2$@
  /// 
  /// Bạn có chắc chắn muốn tiếp tục?
  internal static func dialogConfirmLinkMessage(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "dialog_confirm_link_message", String(describing: p1), String(describing: p2))
  }
  /// Kiểm tra lại liên kết này
  internal static var dialogConfirmLinkTitle: String { return L10n.tr("Localizable", "dialog_confirm_link_title") }
  /// Để cho phép ứng dụng sử dụng camera, vui lòng cấp quyền trong cài đặt hệ thống.
  internal static var dialogPermissionCamera: String { return L10n.tr("Localizable", "dialog_permission_camera") }
  /// Vui lòng cấp quyền trong cài đặt hệ thống.
  internal static var dialogPermissionGeneric: String { return L10n.tr("Localizable", "dialog_permission_generic") }
  /// Cấp quyền truy cập trong Cài đặt -> Vị trí.
  internal static var dialogPermissionLocationDescriptionIos: String { return L10n.tr("Localizable", "dialog_permission_location_description_ios") }
  /// %1$@ không có quyền truy cập vào vị trí của bạn.
  internal static func dialogPermissionLocationTitleIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "dialog_permission_location_title_ios", String(describing: p1))
  }
  /// Để cho phép ứng dụng sử dụng microphone, vui lòng cấp quyền trong cài đặt hệ thống.
  internal static var dialogPermissionMicrophone: String { return L10n.tr("Localizable", "dialog_permission_microphone") }
  /// Cấp quyền truy cập để bạn có thể ghi âm và gửi tin nhắn có âm thanh.
  internal static var dialogPermissionMicrophoneDescriptionIos: String { return L10n.tr("Localizable", "dialog_permission_microphone_description_ios") }
  /// %1$@ cần quyền truy cập microphone.
  internal static func dialogPermissionMicrophoneTitleIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "dialog_permission_microphone_title_ios", String(describing: p1))
  }
  /// Để cho phép ứng dụng hiển thị thông báo, vui lòng cấp quyền trong cài đặt hệ thống.
  internal static var dialogPermissionNotification: String { return L10n.tr("Localizable", "dialog_permission_notification") }
  /// %1$@ không có quyền truy cập vào thư viện ảnh của bạn.
  internal static func dialogPermissionPhotoLibraryTitleIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "dialog_permission_photo_library_title_ios", String(describing: p1))
  }
  /// Phòng đã báo cáo
  internal static var dialogRoomReported: String { return L10n.tr("Localizable", "dialog_room_reported") }
  /// Đã báo cáo và rời phòng
  internal static var dialogRoomReportedAndLeft: String { return L10n.tr("Localizable", "dialog_room_reported_and_left") }
  /// Xác nhận
  internal static var dialogTitleConfirmation: String { return L10n.tr("Localizable", "dialog_title_confirmation") }
  /// Lỗi
  internal static var dialogTitleError: String { return L10n.tr("Localizable", "dialog_title_error") }
  /// Thành công
  internal static var dialogTitleSuccess: String { return L10n.tr("Localizable", "dialog_title_success") }
  /// Cảnh báo
  internal static var dialogTitleWarning: String { return L10n.tr("Localizable", "dialog_title_warning") }
  /// Các thay đổi sẽ không được lưu
  internal static var dialogUnsavedChangesDescriptionIos: String { return L10n.tr("Localizable", "dialog_unsaved_changes_description_ios") }
  /// Lưu thay đổi?
  internal static var dialogUnsavedChangesTitle: String { return L10n.tr("Localizable", "dialog_unsaved_changes_title") }
  /// Hoạt động
  internal static var emojiPickerCategoryActivity: String { return L10n.tr("Localizable", "emoji_picker_category_activity") }
  /// Cờ
  internal static var emojiPickerCategoryFlags: String { return L10n.tr("Localizable", "emoji_picker_category_flags") }
  /// Thức ăn & đồ uống
  internal static var emojiPickerCategoryFoods: String { return L10n.tr("Localizable", "emoji_picker_category_foods") }
  /// Động vật & thiên nhiên
  internal static var emojiPickerCategoryNature: String { return L10n.tr("Localizable", "emoji_picker_category_nature") }
  /// Đồ vật
  internal static var emojiPickerCategoryObjects: String { return L10n.tr("Localizable", "emoji_picker_category_objects") }
  /// Mặt cười & con người
  internal static var emojiPickerCategoryPeople: String { return L10n.tr("Localizable", "emoji_picker_category_people") }
  /// Du lịch & địa điểm
  internal static var emojiPickerCategoryPlaces: String { return L10n.tr("Localizable", "emoji_picker_category_places") }
  /// Ký hiệu
  internal static var emojiPickerCategorySymbols: String { return L10n.tr("Localizable", "emoji_picker_category_symbols") }
  /// Homeserver của bạn cần được nâng cấp để hỗ trợ Dịch vụ Xác thực Matrix và tạo tài khoản.
  internal static var errorAccountCreationNotPossible: String { return L10n.tr("Localizable", "error_account_creation_not_possible") }
  /// Tạo liên kết cố định thất bại
  internal static var errorFailedCreatingThePermalink: String { return L10n.tr("Localizable", "error_failed_creating_the_permalink") }
  /// %1$@ không thể tải bản đồ. Vui lòng thử lại sau.
  internal static func errorFailedLoadingMap(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_failed_loading_map", String(describing: p1))
  }
  /// Tải tin nhắn thất bại
  internal static var errorFailedLoadingMessages: String { return L10n.tr("Localizable", "error_failed_loading_messages") }
  /// %1$@ không thể truy cập vị trí của bạn. Vui lòng thử lại sau.
  internal static func errorFailedLocatingUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "error_failed_locating_user", String(describing: p1))
  }
  /// Tải lên tin nhắn thoại thất bại.
  internal static var errorFailedUploadingVoiceMessage: String { return L10n.tr("Localizable", "error_failed_uploading_voice_message") }
  /// Phòng không còn tồn tại hoặc lời mời không còn hợp lệ.
  internal static var errorInvalidInvite: String { return L10n.tr("Localizable", "error_invalid_invite") }
  /// Không tìm thấy tin nhắn
  internal static var errorMessageNotFound: String { return L10n.tr("Localizable", "error_message_not_found") }
  /// Điều này có thể do vấn đề mạng hoặc máy chủ.
  internal static var errorNetworkOrServerIssue: String { return L10n.tr("Localizable", "error_network_or_server_issue") }
  /// Không tìm thấy ứng dụng tương thích để xử lý hành động này.
  internal static var errorNoCompatibleAppFound: String { return L10n.tr("Localizable", "error_no_compatible_app_found") }
  /// Địa chỉ phòng này đã tồn tại. Vui lòng thử chỉnh sửa trường địa chỉ phòng hoặc thay đổi tên phòng
  internal static var errorRoomAddressAlreadyExists: String { return L10n.tr("Localizable", "error_room_address_already_exists") }
  /// Một số ký tự không được phép. Chỉ hỗ trợ chữ cái, chữ số và các ký hiệu sau ! $ & ' ( ) * + / ; = ? @ [ ] - . _
  internal static var errorRoomAddressInvalidSymbols: String { return L10n.tr("Localizable", "error_room_address_invalid_symbols") }
  /// Một số tin nhắn chưa được gửi
  internal static var errorSomeMessagesHaveNotBeenSent: String { return L10n.tr("Localizable", "error_some_messages_have_not_been_sent") }
  /// Xin lỗi, đã xảy ra lỗi
  internal static var errorUnknown: String { return L10n.tr("Localizable", "error_unknown") }
  /// Người gửi sự kiện không khớp với chủ sở hữu thiết bị đã gửi.
  internal static var eventShieldMismatchedSender: String { return L10n.tr("Localizable", "event_shield_mismatched_sender") }
  /// Tính xác thực của tin nhắn mã hóa này không thể được đảm bảo trên thiết bị này.
  internal static var eventShieldReasonAuthenticityNotGuaranteed: String { return L10n.tr("Localizable", "event_shield_reason_authenticity_not_guaranteed") }
  /// Được mã hóa bởi người dùng đã xác minh trước đó.
  internal static var eventShieldReasonPreviouslyVerified: String { return L10n.tr("Localizable", "event_shield_reason_previously_verified") }
  /// Không được mã hóa.
  internal static var eventShieldReasonSentInClear: String { return L10n.tr("Localizable", "event_shield_reason_sent_in_clear") }
  /// Được mã hóa bởi thiết bị không xác định hoặc đã xóa.
  internal static var eventShieldReasonUnknownDevice: String { return L10n.tr("Localizable", "event_shield_reason_unknown_device") }
  /// Được mã hóa bởi thiết bị chưa được chủ sở hữu xác minh.
  internal static var eventShieldReasonUnsignedDevice: String { return L10n.tr("Localizable", "event_shield_reason_unsigned_device") }
  /// Được mã hóa bởi người dùng chưa xác minh.
  internal static var eventShieldReasonUnverifiedIdentity: String { return L10n.tr("Localizable", "event_shield_reason_unverified_identity") }
  /// Để đảm bảo bạn không bao giờ bỏ lỡ cuộc gọi quan trọng, vui lòng thay đổi cài đặt để cho phép thông báo toàn màn hình khi điện thoại bị khóa.
  internal static var fullScreenIntentBannerMessage: String { return L10n.tr("Localizable", "full_screen_intent_banner_message") }
  /// Nâng cao trải nghiệm cuộc gọi
  internal static var fullScreenIntentBannerTitle: String { return L10n.tr("Localizable", "full_screen_intent_banner_title") }
  /// 🔐️ Tham gia cùng tôi trên %1$@
  internal static func inviteFriendsRichTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_rich_title", String(describing: p1))
  }
  /// Này, trò chuyện với tôi trên %1$@: %2$@
  internal static func inviteFriendsText(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "invite_friends_text", String(describing: p1), String(describing: p2))
  }
  /// Bạn có chắc chắn muốn rời cuộc trò chuyện này? Cuộc trò chuyện này không công khai và bạn sẽ không thể tham gia lại nếu không có lời mời.
  internal static var leaveConversationAlertSubtitle: String { return L10n.tr("Localizable", "leave_conversation_alert_subtitle") }
  /// Bạn có chắc chắn muốn rời phòng này? Bạn là người duy nhất ở đây. Nếu bạn rời đi, không ai có thể tham gia trong tương lai, kể cả bạn.
  internal static var leaveRoomAlertEmptySubtitle: String { return L10n.tr("Localizable", "leave_room_alert_empty_subtitle") }
  /// Bạn có chắc chắn muốn rời phòng này? Phòng này không công khai và bạn sẽ không thể tham gia lại nếu không có lời mời.
  internal static var leaveRoomAlertPrivateSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_private_subtitle") }
  /// Bạn có chắc chắn muốn rời phòng?
  internal static var leaveRoomAlertSubtitle: String { return L10n.tr("Localizable", "leave_room_alert_subtitle") }
  /// %1$@ iOS
  internal static func loginInitialDeviceNameIos(_ p1: Any) -> String {
    return L10n.tr("Localizable", "login_initial_device_name_ios", String(describing: p1))
  }
  /// Thông báo
  internal static var notification: String { return L10n.tr("Localizable", "Notification") }
  /// Cuộc gọi
  internal static var notificationChannelCall: String { return L10n.tr("Localizable", "notification_channel_call") }
  /// Đang lắng nghe sự kiện
  internal static var notificationChannelListeningForEvents: String { return L10n.tr("Localizable", "notification_channel_listening_for_events") }
  /// Thông báo có tiếng
  internal static var notificationChannelNoisy: String { return L10n.tr("Localizable", "notification_channel_noisy") }
  /// Cuộc gọi đang đổ chuông
  internal static var notificationChannelRingingCalls: String { return L10n.tr("Localizable", "notification_channel_ringing_calls") }
  /// Thông báo im lặng
  internal static var notificationChannelSilent: String { return L10n.tr("Localizable", "notification_channel_silent") }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationCompatSummaryLineForRoom(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_compat_summary_line_for_room", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationCompatSummaryTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_compat_summary_title", p1)
  }
  /// Bạn có tin nhắn mới.
  internal static var notificationFallbackContent: String { return L10n.tr("Localizable", "notification_fallback_content") }
  /// 📹 Cuộc gọi đến
  internal static var notificationIncomingCall: String { return L10n.tr("Localizable", "notification_incoming_call") }
  /// ** Gửi thất bại - vui lòng mở phòng
  internal static var notificationInlineReplyFailed: String { return L10n.tr("Localizable", "notification_inline_reply_failed") }
  /// Tham gia
  internal static var notificationInvitationActionJoin: String { return L10n.tr("Localizable", "notification_invitation_action_join") }
  /// Từ chối
  internal static var notificationInvitationActionReject: String { return L10n.tr("Localizable", "notification_invitation_action_reject") }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationInvitations(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_invitations", p1)
  }
  /// Mời bạn trò chuyện
  internal static var notificationInviteBody: String { return L10n.tr("Localizable", "notification_invite_body") }
  /// %1$@ mời bạn trò chuyện
  internal static func notificationInviteBodyWithSender(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_invite_body_with_sender", String(describing: p1))
  }
  /// Nhắc đến bạn: %1$@
  internal static func notificationMentionedYouBody(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_mentioned_you_body", String(describing: p1))
  }
  /// Tin nhắn mới
  internal static var notificationNewMessages: String { return L10n.tr("Localizable", "notification_new_messages") }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationNewMessagesForRoom(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_new_messages_for_room", p1)
  }
  /// Phản ứng bằng %1$@
  internal static func notificationReactionBody(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_reaction_body", String(describing: p1))
  }
  /// Đánh dấu đã đọc
  internal static var notificationRoomActionMarkAsRead: String { return L10n.tr("Localizable", "notification_room_action_mark_as_read") }
  /// Trả lời nhanh
  internal static var notificationRoomActionQuickReply: String { return L10n.tr("Localizable", "notification_room_action_quick_reply") }
  /// Mời bạn tham gia phòng
  internal static var notificationRoomInviteBody: String { return L10n.tr("Localizable", "notification_room_invite_body") }
  /// %1$@ mời bạn tham gia phòng
  internal static func notificationRoomInviteBodyWithSender(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_room_invite_body_with_sender", String(describing: p1))
  }
  /// Tôi
  internal static var notificationSenderMe: String { return L10n.tr("Localizable", "notification_sender_me") }
  /// %1$@ đã nhắc đến hoặc trả lời
  internal static func notificationSenderMentionReply(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notification_sender_mention_reply", String(describing: p1))
  }
  /// Bạn đang xem thông báo! Nhấp vào tôi!
  internal static var notificationTestPushNotificationContent: String { return L10n.tr("Localizable", "notification_test_push_notification_content") }
  /// %1$@: %2$@
  internal static func notificationTickerTextDm(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_ticker_text_dm", String(describing: p1), String(describing: p2))
  }
  /// %1$@: %2$@ %3$@
  internal static func notificationTickerTextGroup(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "notification_ticker_text_group", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationUnreadNotifiedMessages(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages", p1)
  }
  /// %1$@ và %2$@
  internal static func notificationUnreadNotifiedMessagesAndInvitation(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_and_invitation", String(describing: p1), String(describing: p2))
  }
  /// %1$@ trong %2$@
  internal static func notificationUnreadNotifiedMessagesInRoom(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room", String(describing: p1), String(describing: p2))
  }
  /// %1$@ trong %2$@ và %3$@
  internal static func notificationUnreadNotifiedMessagesInRoomAndInvitation(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room_and_invitation", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func notificationUnreadNotifiedMessagesInRoomRooms(_ p1: Int) -> String {
    return L10n.tr("Localizable", "notification_unread_notified_messages_in_room_rooms", p1)
  }
  /// Rageshake để báo cáo lỗi
  internal static var preferenceRageshake: String { return L10n.tr("Localizable", "preference_rageshake") }
  /// Có vẻ như bạn đang lắc điện thoại vì bực bội. Bạn có muốn mở màn hình báo cáo lỗi?
  internal static var rageshakeDetectionDialogContent: String { return L10n.tr("Localizable", "rageshake_detection_dialog_content") }
  /// Thêm tệp đính kèm
  internal static var richTextEditorA11yAddAttachment: String { return L10n.tr("Localizable", "rich_text_editor_a11y_add_attachment") }
  /// Bật/tắt danh sách đầu dòng
  internal static var richTextEditorBulletList: String { return L10n.tr("Localizable", "rich_text_editor_bullet_list") }
  /// Hủy và đóng định dạng văn bản
  internal static var richTextEditorCloseFormattingOptions: String { return L10n.tr("Localizable", "rich_text_editor_close_formatting_options") }
  /// Bật/tắt khối mã
  internal static var richTextEditorCodeBlock: String { return L10n.tr("Localizable", "rich_text_editor_code_block") }
  /// Thêm chú thích
  internal static var richTextEditorComposerCaptionPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_composer_caption_placeholder") }
  /// Tin nhắn mã hóa…
  internal static var richTextEditorComposerEncryptedPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_composer_encrypted_placeholder") }
  /// Tin nhắn…
  internal static var richTextEditorComposerPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_composer_placeholder") }
  /// Tin nhắn không mã hóa…
  internal static var richTextEditorComposerUnencryptedPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_composer_unencrypted_placeholder") }
  /// Tạo liên kết
  internal static var richTextEditorCreateLink: String { return L10n.tr("Localizable", "rich_text_editor_create_link") }
  /// Chỉnh sửa liên kết
  internal static var richTextEditorEditLink: String { return L10n.tr("Localizable", "rich_text_editor_edit_link") }
  /// %1$@, trạng thái: %2$@
  internal static func richTextEditorFormatAction(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "rich_text_editor_format_action", String(describing: p1), String(describing: p2))
  }
  /// Áp dụng định dạng đậm
  internal static var richTextEditorFormatBold: String { return L10n.tr("Localizable", "rich_text_editor_format_bold") }
  /// Áp dụng định dạng nghiêng
  internal static var richTextEditorFormatItalic: String { return L10n.tr("Localizable", "rich_text_editor_format_italic") }
  /// đã tắt
  internal static var richTextEditorFormatStateDisabled: String { return L10n.tr("Localizable", "rich_text_editor_format_state_disabled") }
  /// tắt
  internal static var richTextEditorFormatStateOff: String { return L10n.tr("Localizable", "rich_text_editor_format_state_off") }
  /// bật
  internal static var richTextEditorFormatStateOn: String { return L10n.tr("Localizable", "rich_text_editor_format_state_on") }
  /// Áp dụng định dạng gạch ngang
  internal static var richTextEditorFormatStrikethrough: String { return L10n.tr("Localizable", "rich_text_editor_format_strikethrough") }
  /// Áp dụng định dạng gạch chân
  internal static var richTextEditorFormatUnderline: String { return L10n.tr("Localizable", "rich_text_editor_format_underline") }
  /// Bật/tắt chế độ toàn màn hình
  internal static var richTextEditorFullScreenToggle: String { return L10n.tr("Localizable", "rich_text_editor_full_screen_toggle") }
  /// Thụt lề
  internal static var richTextEditorIndent: String { return L10n.tr("Localizable", "rich_text_editor_indent") }
  /// Áp dụng định dạng mã nội tuyến
  internal static var richTextEditorInlineCode: String { return L10n.tr("Localizable", "rich_text_editor_inline_code") }
  /// Đặt liên kết
  internal static var richTextEditorLink: String { return L10n.tr("Localizable", "rich_text_editor_link") }
  /// Bật/tắt danh sách đánh số
  internal static var richTextEditorNumberedList: String { return L10n.tr("Localizable", "rich_text_editor_numbered_list") }
  /// Mở tùy chọn soạn thảo
  internal static var richTextEditorOpenComposeOptions: String { return L10n.tr("Localizable", "rich_text_editor_open_compose_options") }
  /// Bật/tắt trích dẫn
  internal static var richTextEditorQuote: String { return L10n.tr("Localizable", "rich_text_editor_quote") }
  /// Xóa liên kết
  internal static var richTextEditorRemoveLink: String { return L10n.tr("Localizable", "rich_text_editor_remove_link") }
  /// Bỏ thụt lề
  internal static var richTextEditorUnindent: String { return L10n.tr("Localizable", "rich_text_editor_unindent") }
  /// Liên kết
  internal static var richTextEditorUrlPlaceholder: String { return L10n.tr("Localizable", "rich_text_editor_url_placeholder") }
  /// Thay đổi nhà cung cấp tài khoản
  internal static var screenAccountProviderChange: String { return L10n.tr("Localizable", "screen_account_provider_change") }
  /// Địa chỉ Homeserver
  internal static var screenAccountProviderFormHint: String { return L10n.tr("Localizable", "screen_account_provider_form_hint") }
  /// Nhập từ khóa tìm kiếm hoặc địa chỉ domain.
  internal static var screenAccountProviderFormNotice: String { return L10n.tr("Localizable", "screen_account_provider_form_notice") }
  /// Tìm kiếm công ty, cộng đồng hoặc máy chủ riêng.
  internal static var screenAccountProviderFormSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_form_subtitle") }
  /// Tìm nhà cung cấp tài khoản
  internal static var screenAccountProviderFormTitle: String { return L10n.tr("Localizable", "screen_account_provider_form_title") }
  /// Đây là nơi các cuộc trò chuyện sẽ diễn ra — giống như bạn sử dụng nhà cung cấp email để giữ email.
  internal static var screenAccountProviderSigninSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_signin_subtitle") }
  /// Bạn sắp đăng nhập vào %@
  internal static func screenAccountProviderSigninTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_account_provider_signin_title", String(describing: p1))
  }
  /// Đây là nơi các cuộc trò chuyện sẽ diễn ra — giống như bạn sử dụng nhà cung cấp email để giữ email.
  internal static var screenAccountProviderSignupSubtitle: String { return L10n.tr("Localizable", "screen_account_provider_signup_subtitle") }
  /// Bạn sắp tạo tài khoản trên %@
  internal static func screenAccountProviderSignupTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_account_provider_signup_title", String(describing: p1))
  }
  /// Chế độ nhà phát triển
  internal static var screenAdvancedSettingsDeveloperMode: String { return L10n.tr("Localizable", "screen_advanced_settings_developer_mode") }
  /// Bật để có quyền truy cập vào các tính năng và chức năng dành cho nhà phát triển.
  internal static var screenAdvancedSettingsDeveloperModeDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_developer_mode_description") }
  /// URL cơ sở Element Call tùy chỉnh
  internal static var screenAdvancedSettingsElementCallBaseUrl: String { return L10n.tr("Localizable", "screen_advanced_settings_element_call_base_url") }
  /// Đặt URL cơ sở tùy chỉnh cho Element Call.
  internal static var screenAdvancedSettingsElementCallBaseUrlDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_element_call_base_url_description") }
  /// URL không hợp lệ, vui lòng đảm bảo bạn bao gồm giao thức (http/https) và địa chỉ chính xác.
  internal static var screenAdvancedSettingsElementCallBaseUrlValidationError: String { return L10n.tr("Localizable", "screen_advanced_settings_element_call_base_url_validation_error") }
  /// Ẩn avatar trong yêu cầu mời phòng
  internal static var screenAdvancedSettingsHideInviteAvatarsToggleTitle: String { return L10n.tr("Localizable", "screen_advanced_settings_hide_invite_avatars_toggle_title") }
  /// Ẩn xem trước media trong dòng thời gian
  internal static var screenAdvancedSettingsHideTimelineMediaToggleTitle: String { return L10n.tr("Localizable", "screen_advanced_settings_hide_timeline_media_toggle_title") }
  /// Tải lên ảnh và video nhanh hơn và giảm sử dụng dữ liệu
  internal static var screenAdvancedSettingsMediaCompressionDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_media_compression_description") }
  /// Tối ưu hóa chất lượng media
  internal static var screenAdvancedSettingsMediaCompressionTitle: String { return L10n.tr("Localizable", "screen_advanced_settings_media_compression_title") }
  /// Kiểm duyệt và an toàn
  internal static var screenAdvancedSettingsModerationAndSafetySectionTitle: String { return L10n.tr("Localizable", "screen_advanced_settings_moderation_and_safety_section_title") }
  /// Tắt trình soạn thảo văn bản phong phú để nhập Markdown thủ công.
  internal static var screenAdvancedSettingsRichTextEditorDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_rich_text_editor_description") }
  /// Xác nhận đã đọc
  internal static var screenAdvancedSettingsSendReadReceipts: String { return L10n.tr("Localizable", "screen_advanced_settings_send_read_receipts") }
  /// Nếu tắt, xác nhận đã đọc của bạn sẽ không được gửi cho ai. Bạn vẫn sẽ nhận được xác nhận đã đọc từ người dùng khác.
  internal static var screenAdvancedSettingsSendReadReceiptsDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_send_read_receipts_description") }
  /// Chia sẻ trạng thái
  internal static var screenAdvancedSettingsSharePresence: String { return L10n.tr("Localizable", "screen_advanced_settings_share_presence") }
  /// Nếu tắt, bạn sẽ không thể gửi hoặc nhận xác nhận đã đọc hoặc thông báo đang gõ.
  internal static var screenAdvancedSettingsSharePresenceDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_share_presence_description") }
  /// Luôn ẩn
  internal static var screenAdvancedSettingsShowMediaTimelineAlwaysHide: String { return L10n.tr("Localizable", "screen_advanced_settings_show_media_timeline_always_hide") }
  /// Luôn hiển thị
  internal static var screenAdvancedSettingsShowMediaTimelineAlwaysShow: String { return L10n.tr("Localizable", "screen_advanced_settings_show_media_timeline_always_show") }
  /// Trong phòng riêng tư
  internal static var screenAdvancedSettingsShowMediaTimelinePrivateRooms: String { return L10n.tr("Localizable", "screen_advanced_settings_show_media_timeline_private_rooms") }
  /// Media bị ẩn luôn có thể hiển thị bằng cách chạm vào
  internal static var screenAdvancedSettingsShowMediaTimelineSubtitle: String { return L10n.tr("Localizable", "screen_advanced_settings_show_media_timeline_subtitle") }
  /// Hiển thị media trong dòng thời gian
  internal static var screenAdvancedSettingsShowMediaTimelineTitle: String { return L10n.tr("Localizable", "screen_advanced_settings_show_media_timeline_title") }
  /// Bật tùy chọn xem nguồn tin nhắn trong dòng thời gian.
  internal static var screenAdvancedSettingsViewSourceDescription: String { return L10n.tr("Localizable", "screen_advanced_settings_view_source_description") }
  /// Chúng tôi sẽ không ghi lại hoặc lập hồ sơ bất kỳ dữ liệu cá nhân nào
  internal static var screenAnalyticsPromptDataUsage: String { return L10n.tr("Localizable", "screen_analytics_prompt_data_usage") }
  /// Chia sẻ dữ liệu sử dụng ẩn danh để giúp chúng tôi xác định vấn đề.
  internal static var screenAnalyticsPromptHelpUsImprove: String { return L10n.tr("Localizable", "screen_analytics_prompt_help_us_improve") }
  /// Bạn có thể đọc tất cả điều khoản của chúng tôi %1$@.
  internal static func screenAnalyticsPromptReadTerms(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_prompt_read_terms", String(describing: p1))
  }
  /// tại đây
  internal static var screenAnalyticsPromptReadTermsContentLink: String { return L10n.tr("Localizable", "screen_analytics_prompt_read_terms_content_link") }
  /// Bạn có thể tắt điều này bất cứ lúc nào
  internal static var screenAnalyticsPromptSettings: String { return L10n.tr("Localizable", "screen_analytics_prompt_settings") }
  /// Chúng tôi sẽ không chia sẻ dữ liệu của bạn với bên thứ ba
  internal static var screenAnalyticsPromptThirdPartySharing: String { return L10n.tr("Localizable", "screen_analytics_prompt_third_party_sharing") }
  /// Giúp cải thiện %1$@
  internal static func screenAnalyticsPromptTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_prompt_title", String(describing: p1))
  }
  /// Chia sẻ dữ liệu sử dụng ẩn danh để giúp chúng tôi xác định vấn đề.
  internal static var screenAnalyticsSettingsHelpUsImprove: String { return L10n.tr("Localizable", "screen_analytics_settings_help_us_improve") }
  /// Bạn có thể đọc tất cả điều khoản của chúng tôi %1$@.
  internal static func screenAnalyticsSettingsReadTerms(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_analytics_settings_read_terms", String(describing: p1))
  }
  /// tại đây
  internal static var screenAnalyticsSettingsReadTermsContentLink: String { return L10n.tr("Localizable", "screen_analytics_settings_read_terms_content_link") }
  /// Chia sẻ dữ liệu phân tích
  internal static var screenAnalyticsSettingsShareData: String { return L10n.tr("Localizable", "screen_analytics_settings_share_data") }
  /// xác thực sinh trắc học
  internal static var screenAppLockBiometricAuthentication: String { return L10n.tr("Localizable", "screen_app_lock_biometric_authentication") }
  /// mở khóa sinh trắc học
  internal static var screenAppLockBiometricUnlock: String { return L10n.tr("Localizable", "screen_app_lock_biometric_unlock") }
  /// Cần xác thực để truy cập ứng dụng
  internal static var screenAppLockBiometricUnlockReasonIos: String { return L10n.tr("Localizable", "screen_app_lock_biometric_unlock_reason_ios") }
  /// Quên PIN?
  internal static var screenAppLockForgotPin: String { return L10n.tr("Localizable", "screen_app_lock_forgot_pin") }
  /// Đổi mã PIN
  internal static var screenAppLockSettingsChangePin: String { return L10n.tr("Localizable", "screen_app_lock_settings_change_pin") }
  /// Cho phép mở khóa sinh trắc học
  internal static var screenAppLockSettingsEnableBiometricUnlock: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_biometric_unlock") }
  /// Cho phép Face ID
  internal static var screenAppLockSettingsEnableFaceIdIos: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_face_id_ios") }
  /// Cho phép Optic ID
  internal static var screenAppLockSettingsEnableOpticIdIos: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_optic_id_ios") }
  /// Cho phép Touch ID
  internal static var screenAppLockSettingsEnableTouchIdIos: String { return L10n.tr("Localizable", "screen_app_lock_settings_enable_touch_id_ios") }
  /// Xóa PIN
  internal static var screenAppLockSettingsRemovePin: String { return L10n.tr("Localizable", "screen_app_lock_settings_remove_pin") }
  /// Bạn có chắc chắn muốn xóa PIN?
  internal static var screenAppLockSettingsRemovePinAlertMessage: String { return L10n.tr("Localizable", "screen_app_lock_settings_remove_pin_alert_message") }
  /// Xóa PIN?
  internal static var screenAppLockSettingsRemovePinAlertTitle: String { return L10n.tr("Localizable", "screen_app_lock_settings_remove_pin_alert_title") }
  /// Cho phép %1$@
  internal static func screenAppLockSetupBiometricUnlockAllowTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_app_lock_setup_biometric_unlock_allow_title", String(describing: p1))
  }
  /// Tôi muốn sử dụng PIN
  internal static var screenAppLockSetupBiometricUnlockSkip: String { return L10n.tr("Localizable", "screen_app_lock_setup_biometric_unlock_skip") }
  /// Tiết kiệm thời gian và sử dụng %1$@ để mở khóa ứng dụng mỗi lần
  internal static func screenAppLockSetupBiometricUnlockSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_app_lock_setup_biometric_unlock_subtitle", String(describing: p1))
  }
  /// Chọn PIN
  internal static var screenAppLockSetupChoosePin: String { return L10n.tr("Localizable", "screen_app_lock_setup_choose_pin") }
  /// Xác nhận PIN
  internal static var screenAppLockSetupConfirmPin: String { return L10n.tr("Localizable", "screen_app_lock_setup_confirm_pin") }
  /// Khóa %1$@ để thêm bảo mật cho cuộc trò chuyện.
  /// 
  /// Chọn thứ gì đó dễ nhớ. Nếu bạn quên PIN này, bạn sẽ bị đăng xuất khỏi ứng dụng.
  internal static func screenAppLockSetupPinContext(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_app_lock_setup_pin_context", String(describing: p1))
  }
  /// Bạn không thể chọn điều này làm mã PIN vì lý do bảo mật
  internal static var screenAppLockSetupPinForbiddenDialogContent: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_forbidden_dialog_content") }
  /// Chọn PIN khác
  internal static var screenAppLockSetupPinForbiddenDialogTitle: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_forbidden_dialog_title") }
  /// Vui lòng nhập cùng một PIN hai lần
  internal static var screenAppLockSetupPinMismatchDialogContent: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_mismatch_dialog_content") }
  /// PIN không khớp
  internal static var screenAppLockSetupPinMismatchDialogTitle: String { return L10n.tr("Localizable", "screen_app_lock_setup_pin_mismatch_dialog_title") }
  /// Bạn sẽ cần đăng nhập lại và tạo PIN mới để tiếp tục
  internal static var screenAppLockSignoutAlertMessage: String { return L10n.tr("Localizable", "screen_app_lock_signout_alert_message") }
  /// Bạn đang bị đăng xuất
  internal static var screenAppLockSignoutAlertTitle: String { return L10n.tr("Localizable", "screen_app_lock_signout_alert_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenAppLockSubtitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_app_lock_subtitle", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenAppLockSubtitleWrongPin(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_app_lock_subtitle_wrong_pin", p1)
  }
  /// Bạn không có người dùng bị chặn
  internal static var screenBlockedUsersEmpty: String { return L10n.tr("Localizable", "screen_blocked_users_empty") }
  /// Bỏ chặn
  internal static var screenBlockedUsersUnblockAlertAction: String { return L10n.tr("Localizable", "screen_blocked_users_unblock_alert_action") }
  /// Bạn sẽ có thể thấy lại tất cả tin nhắn từ họ.
  internal static var screenBlockedUsersUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_blocked_users_unblock_alert_description") }
  /// Bỏ chặn người dùng
  internal static var screenBlockedUsersUnblockAlertTitle: String { return L10n.tr("Localizable", "screen_blocked_users_unblock_alert_title") }
  /// Đang bỏ chặn…
  internal static var screenBlockedUsersUnblocking: String { return L10n.tr("Localizable", "screen_blocked_users_unblocking") }
  /// Gửi lời mời
  internal static var screenBottomSheetCreateDmConfirmationButtonTitle: String { return L10n.tr("Localizable", "screen_bottom_sheet_create_dm_confirmation_button_title") }
  /// Bạn có muốn bắt đầu trò chuyện với %1$@?
  internal static func screenBottomSheetCreateDmMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bottom_sheet_create_dm_message", String(describing: p1))
  }
  /// Gửi lời mời?
  internal static var screenBottomSheetCreateDmTitle: String { return L10n.tr("Localizable", "screen_bottom_sheet_create_dm_title") }
  /// Cấm khỏi phòng
  internal static var screenBottomSheetManageRoomMemberBan: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_ban") }
  /// Cấm
  internal static var screenBottomSheetManageRoomMemberBanMemberConfirmationAction: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_ban_member_confirmation_action") }
  /// Họ sẽ không thể tham gia phòng này lại nếu được mời.
  internal static var screenBottomSheetManageRoomMemberBanMemberConfirmationDescription: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_ban_member_confirmation_description") }
  /// Bạn có chắc chắn muốn cấm thành viên này?
  internal static var screenBottomSheetManageRoomMemberBanMemberConfirmationTitle: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_ban_member_confirmation_title") }
  /// Đang cấm %1$@
  internal static func screenBottomSheetManageRoomMemberBanningUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_banning_user", String(describing: p1))
  }
  /// Xóa
  internal static var screenBottomSheetManageRoomMemberKickMemberConfirmationAction: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_kick_member_confirmation_action") }
  /// Họ sẽ có thể tham gia phòng này lại nếu được mời.
  internal static var screenBottomSheetManageRoomMemberKickMemberConfirmationDescription: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_kick_member_confirmation_description") }
  /// Bạn có chắc chắn muốn xóa thành viên này?
  internal static var screenBottomSheetManageRoomMemberKickMemberConfirmationTitle: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_kick_member_confirmation_title") }
  /// Xem hồ sơ
  internal static var screenBottomSheetManageRoomMemberMemberUserInfo: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_member_user_info") }
  /// Xóa khỏi phòng
  internal static var screenBottomSheetManageRoomMemberRemove: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_remove") }
  /// Xóa thành viên và cấm tham gia trong tương lai?
  internal static var screenBottomSheetManageRoomMemberRemoveConfirmationTitle: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_remove_confirmation_title") }
  /// Đang xóa %1$@…
  internal static func screenBottomSheetManageRoomMemberRemovingUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_removing_user", String(describing: p1))
  }
  /// Bỏ cấm khỏi phòng
  internal static var screenBottomSheetManageRoomMemberUnban: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_unban") }
  /// Bỏ cấm
  internal static var screenBottomSheetManageRoomMemberUnbanMemberConfirmationAction: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_unban_member_confirmation_action") }
  /// Họ sẽ có thể tham gia phòng lại nếu được mời
  internal static var screenBottomSheetManageRoomMemberUnbanMemberConfirmationDescription: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_unban_member_confirmation_description") }
  /// Bạn có chắc chắn muốn bỏ cấm thành viên này?
  internal static var screenBottomSheetManageRoomMemberUnbanMemberConfirmationTitle: String { return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_unban_member_confirmation_title") }
  /// Đang bỏ cấm %1$@
  internal static func screenBottomSheetManageRoomMemberUnbanningUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bottom_sheet_manage_room_member_unbanning_user", String(describing: p1))
  }
  /// Ảnh chụp màn hình
  internal static var screenBugReportA11yScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_a11y_screenshot") }
  /// Đính kèm ảnh chụp màn hình
  internal static var screenBugReportAttachScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_attach_screenshot") }
  /// Bạn có thể liên hệ với tôi nếu có câu hỏi nào khác.
  internal static var screenBugReportContactMe: String { return L10n.tr("Localizable", "screen_bug_report_contact_me") }
  /// Liên hệ với tôi
  internal static var screenBugReportContactMeTitle: String { return L10n.tr("Localizable", "screen_bug_report_contact_me_title") }
  /// Chỉnh sửa ảnh chụp màn hình
  internal static var screenBugReportEditScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_edit_screenshot") }
  /// Vui lòng mô tả vấn đề. Bạn đã làm gì? Bạn mong đợi điều gì xảy ra? Điều gì thực sự đã xảy ra. Vui lòng cung cấp càng nhiều chi tiết càng tốt.
  internal static var screenBugReportEditorDescription: String { return L10n.tr("Localizable", "screen_bug_report_editor_description") }
  /// Mô tả vấn đề…
  internal static var screenBugReportEditorPlaceholder: String { return L10n.tr("Localizable", "screen_bug_report_editor_placeholder") }
  /// Nếu có thể, vui lòng viết mô tả bằng tiếng Anh.
  internal static var screenBugReportEditorSupporting: String { return L10n.tr("Localizable", "screen_bug_report_editor_supporting") }
  /// Mô tả quá ngắn, vui lòng cung cấp thêm chi tiết về những gì đã xảy ra. Cảm ơn!
  internal static var screenBugReportErrorDescriptionTooShort: String { return L10n.tr("Localizable", "screen_bug_report_error_description_too_short") }
  /// Gửi nhật ký sự cố
  internal static var screenBugReportIncludeCrashLogs: String { return L10n.tr("Localizable", "screen_bug_report_include_crash_logs") }
  /// Cho phép nhật ký
  internal static var screenBugReportIncludeLogs: String { return L10n.tr("Localizable", "screen_bug_report_include_logs") }
  /// Nhật ký của bạn quá lớn nên không thể đưa vào báo cáo này, vui lòng gửi chúng cho chúng tôi theo cách khác.
  internal static var screenBugReportIncludeLogsError: String { return L10n.tr("Localizable", "screen_bug_report_include_logs_error") }
  /// Gửi ảnh chụp màn hình
  internal static var screenBugReportIncludeScreenshot: String { return L10n.tr("Localizable", "screen_bug_report_include_screenshot") }
  /// Nhật ký sẽ được đưa vào tin nhắn để đảm bảo mọi thứ hoạt động đúng cách. Để gửi tin nhắn mà không có nhật ký, hãy tắt cài đặt này.
  internal static var screenBugReportLogsDescription: String { return L10n.tr("Localizable", "screen_bug_report_logs_description") }
  /// %1$@ đã gặp sự cố lần cuối sử dụng. Bạn có muốn chia sẻ báo cáo sự cố với chúng tôi?
  internal static func screenBugReportRashLogsAlertTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_bug_report_rash_logs_alert_title", String(describing: p1))
  }
  /// Xem nhật ký
  internal static var screenBugReportViewLogs: String { return L10n.tr("Localizable", "screen_bug_report_view_logs") }
  /// Matrix.org là máy chủ lớn, miễn phí trên mạng Matrix công cộng cho giao tiếp bảo mật, phi tập trung, được điều hành bởi Matrix.org Foundation.
  internal static var screenChangeAccountProviderMatrixOrgSubtitle: String { return L10n.tr("Localizable", "screen_change_account_provider_matrix_org_subtitle") }
  /// Khác
  internal static var screenChangeAccountProviderOther: String { return L10n.tr("Localizable", "screen_change_account_provider_other") }
  /// Sử dụng nhà cung cấp tài khoản khác, chẳng hạn như máy chủ riêng hoặc tài khoản công việc.
  internal static var screenChangeAccountProviderSubtitle: String { return L10n.tr("Localizable", "screen_change_account_provider_subtitle") }
  /// Thay đổi nhà cung cấp tài khoản
  internal static var screenChangeAccountProviderTitle: String { return L10n.tr("Localizable", "screen_change_account_provider_title") }
  /// App Store
  internal static var screenChangeServerErrorElementProRequiredActionIos: String { return L10n.tr("Localizable", "screen_change_server_error_element_pro_required_action_ios") }
  /// Ứng dụng Element Pro được yêu cầu trên %1$@. Vui lòng tải xuống từ cửa hàng.
  internal static func screenChangeServerErrorElementProRequiredMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_element_pro_required_message", String(describing: p1))
  }
  /// Yêu cầu Element Pro
  internal static var screenChangeServerErrorElementProRequiredTitle: String { return L10n.tr("Localizable", "screen_change_server_error_element_pro_required_title") }
  /// Chúng tôi không thể kết nối đến homeserver này. Vui lòng kiểm tra bạn đã nhập URL homeserver chính xác. Nếu URL đúng, liên hệ quản trị viên homeserver để được trợ giúp thêm.
  internal static var screenChangeServerErrorInvalidHomeserver: String { return L10n.tr("Localizable", "screen_change_server_error_invalid_homeserver") }
  /// Máy chủ không khả dụng do vấn đề trong tệp .well-known:
  /// %1$@
  internal static func screenChangeServerErrorInvalidWellKnown(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_invalid_well_known", String(describing: p1))
  }
  /// Nhà cung cấp tài khoản đã chọn không hỗ trợ sliding sync. Cần nâng cấp máy chủ để sử dụng %1$@.
  internal static func screenChangeServerErrorNoSlidingSyncMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_no_sliding_sync_message", String(describing: p1))
  }
  /// %1$@ không được phép kết nối đến %2$@.
  internal static func screenChangeServerErrorUnauthorizedHomeserver(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_unauthorized_homeserver", String(describing: p1), String(describing: p2))
  }
  /// Ứng dụng này đã được cấu hình để cho phép: %1$@.
  internal static func screenChangeServerErrorUnauthorizedHomeserverContent(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_unauthorized_homeserver_content", String(describing: p1))
  }
  /// Nhà cung cấp tài khoản %1$@ không được phép.
  internal static func screenChangeServerErrorUnauthorizedHomeserverTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_change_server_error_unauthorized_homeserver_title", String(describing: p1))
  }
  /// URL Homeserver
  internal static var screenChangeServerFormHeader: String { return L10n.tr("Localizable", "screen_change_server_form_header") }
  /// Nhập địa chỉ domain.
  internal static var screenChangeServerFormNotice: String { return L10n.tr("Localizable", "screen_change_server_form_notice") }
  /// Địa chỉ máy chủ của bạn là gì?
  internal static var screenChangeServerSubtitle: String { return L10n.tr("Localizable", "screen_change_server_subtitle") }
  /// Chọn máy chủ của bạn
  internal static var screenChangeServerTitle: String { return L10n.tr("Localizable", "screen_change_server_title") }
  /// Xóa kho lưu trữ khóa
  internal static var screenChatBackupKeyBackupActionDisable: String { return L10n.tr("Localizable", "screen_chat_backup_key_backup_action_disable") }
  /// Bật sao lưu
  internal static var screenChatBackupKeyBackupActionEnable: String { return L10n.tr("Localizable", "screen_chat_backup_key_backup_action_enable") }
  /// Lưu trữ danh tính mã hóa và khóa tin nhắn một cách an toàn trên máy chủ. Điều này sẽ cho phép bạn xem lịch sử tin nhắn trên bất kỳ thiết bị mới nào. %1$@.
  internal static func screenChatBackupKeyBackupDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_chat_backup_key_backup_description", String(describing: p1))
  }
  /// Kho lưu trữ khóa
  internal static var screenChatBackupKeyBackupTitle: String { return L10n.tr("Localizable", "screen_chat_backup_key_backup_title") }
  /// Kho lưu trữ khóa phải được bật để thiết lập khôi phục.
  internal static var screenChatBackupKeyStorageDisabledError: String { return L10n.tr("Localizable", "screen_chat_backup_key_storage_disabled_error") }
  /// Tải lên khóa từ thiết bị này
  internal static var screenChatBackupKeyStorageToggleDescription: String { return L10n.tr("Localizable", "screen_chat_backup_key_storage_toggle_description") }
  /// Cho phép lưu trữ khóa
  internal static var screenChatBackupKeyStorageToggleTitle: String { return L10n.tr("Localizable", "screen_chat_backup_key_storage_toggle_title") }
  /// Thay đổi khóa khôi phục
  internal static var screenChatBackupRecoveryActionChange: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_change") }
  /// Khôi phục danh tính mã hóa và lịch sử tin nhắn bằng khóa khôi phục nếu bạn mất tất cả thiết bị hiện có.
  internal static var screenChatBackupRecoveryActionChangeDescription: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_change_description") }
  /// Nhập khóa khôi phục
  internal static var screenChatBackupRecoveryActionConfirm: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_confirm") }
  /// Kho lưu trữ khóa của bạn hiện không đồng bộ.
  internal static var screenChatBackupRecoveryActionConfirmDescription: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_confirm_description") }
  /// Thiết lập khôi phục
  internal static var screenChatBackupRecoveryActionSetup: String { return L10n.tr("Localizable", "screen_chat_backup_recovery_action_setup") }
  /// Có quyền truy cập vào tin nhắn mã hóa nếu bạn mất tất cả thiết bị hoặc bị đăng xuất khỏi %1$@ ở mọi nơi.
  internal static func screenChatBackupRecoveryActionSetupDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_chat_backup_recovery_action_setup_description", String(describing: p1))
  }
  /// Tạo tài khoản
  internal static var screenCreateAccountTitle: String { return L10n.tr("Localizable", "screen_create_account_title") }
  /// Mở %1$@ trên thiết bị desktop
  internal static func screenCreateNewRecoveryKeyListItem1(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_1", String(describing: p1))
  }
  /// Đăng nhập vào tài khoản lại
  internal static var screenCreateNewRecoveryKeyListItem2: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_2") }
  /// Khi được yêu cầu xác minh thiết bị, chọn %1$@
  internal static func screenCreateNewRecoveryKeyListItem3(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_3", String(describing: p1))
  }
  /// "Đặt lại tất cả"
  internal static var screenCreateNewRecoveryKeyListItem3ResetAll: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_3_reset_all") }
  /// Làm theo hướng dẫn để tạo khóa khôi phục mới
  internal static var screenCreateNewRecoveryKeyListItem4: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_4") }
  /// Lưu khóa khôi phục mới trong trình quản lý mật khẩu hoặc ghi chú mã hóa
  internal static var screenCreateNewRecoveryKeyListItem5: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_list_item_5") }
  /// Đặt lại mã hóa cho tài khoản bằng thiết bị khác
  internal static var screenCreateNewRecoveryKeyTitle: String { return L10n.tr("Localizable", "screen_create_new_recovery_key_title") }
  /// Thêm tùy chọn
  internal static var screenCreatePollAddOptionBtn: String { return L10n.tr("Localizable", "screen_create_poll_add_option_btn") }
  /// Chỉ hiển thị kết quả sau khi kết thúc bình chọn
  internal static var screenCreatePollAnonymousDesc: String { return L10n.tr("Localizable", "screen_create_poll_anonymous_desc") }
  /// Ẩn phiếu bầu
  internal static var screenCreatePollAnonymousHeadline: String { return L10n.tr("Localizable", "screen_create_poll_anonymous_headline") }
  /// Tùy chọn %1$d
  internal static func screenCreatePollAnswerHint(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_create_poll_answer_hint", p1)
  }
  /// Các thay đổi sẽ không được lưu
  internal static var screenCreatePollCancelConfirmationContentIos: String { return L10n.tr("Localizable", "screen_create_poll_cancel_confirmation_content_ios") }
  /// Hủy bình chọn
  internal static var screenCreatePollCancelConfirmationTitleIos: String { return L10n.tr("Localizable", "screen_create_poll_cancel_confirmation_title_ios") }
  /// Xóa tùy chọn %1$@
  internal static func screenCreatePollDeleteOptionA11y(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_create_poll_delete_option_a11y", String(describing: p1))
  }
  /// %1$@: %2$@
  internal static func screenCreatePollOptionAccessibilityLabel(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_create_poll_option_accessibility_label", String(describing: p1), String(describing: p2))
  }
  /// Tùy chọn
  internal static var screenCreatePollOptionsSectionTitle: String { return L10n.tr("Localizable", "screen_create_poll_options_section_title") }
  /// Câu hỏi hoặc chủ đề
  internal static var screenCreatePollQuestionDesc: String { return L10n.tr("Localizable", "screen_create_poll_question_desc") }
  /// Cuộc bình chọn về điều gì?
  internal static var screenCreatePollQuestionHint: String { return L10n.tr("Localizable", "screen_create_poll_question_hint") }
  /// Xóa %1$@
  internal static func screenCreatePollRemoveAccessibilityLabel(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_create_poll_remove_accessibility_label", String(describing: p1))
  }
  /// Cài đặt
  internal static var screenCreatePollSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_create_poll_settings_section_title") }
  /// Tạo bình chọn
  internal static var screenCreatePollTitle: String { return L10n.tr("Localizable", "screen_create_poll_title") }
  /// Phòng mới
  internal static var screenCreateRoomActionCreateRoom: String { return L10n.tr("Localizable", "screen_create_room_action_create_room") }
  /// Mời mọi người
  internal static var screenCreateRoomAddPeopleTitle: String { return L10n.tr("Localizable", "screen_create_room_add_people_title") }
  /// Đã xảy ra lỗi khi tạo phòng
  internal static var screenCreateRoomErrorCreatingRoom: String { return L10n.tr("Localizable", "screen_create_room_error_creating_room") }
  /// Chỉ những người được mời mới có thể truy cập phòng này. Tất cả tin nhắn đều được mã hóa đầu cuối.
  internal static var screenCreateRoomPrivateOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_private_option_description") }
  /// Phòng riêng tư
  internal static var screenCreateRoomPrivateOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_private_option_title") }
  /// Bất kỳ ai cũng có thể tìm thấy phòng này.
  /// Bạn có thể thay đổi điều này bất cứ lúc nào trong cài đặt phòng.
  internal static var screenCreateRoomPublicOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_public_option_description") }
  /// Phòng công cộng
  internal static var screenCreateRoomPublicOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_public_option_title") }
  /// Bất kỳ ai cũng có thể tham gia phòng này
  internal static var screenCreateRoomRoomAccessSectionAnyoneOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_room_access_section_anyone_option_description") }
  /// Bất kỳ ai
  internal static var screenCreateRoomRoomAccessSectionAnyoneOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_room_access_section_anyone_option_title") }
  /// Quyền truy cập phòng
  internal static var screenCreateRoomRoomAccessSectionHeader: String { return L10n.tr("Localizable", "screen_create_room_room_access_section_header") }
  /// Bất kỳ ai cũng có thể xin tham gia phòng nhưng quản trị viên hoặc điều hành viên sẽ phải chấp nhận yêu cầu
  internal static var screenCreateRoomRoomAccessSectionKnockingOptionDescription: String { return L10n.tr("Localizable", "screen_create_room_room_access_section_knocking_option_description") }
  /// Xin tham gia
  internal static var screenCreateRoomRoomAccessSectionKnockingOptionTitle: String { return L10n.tr("Localizable", "screen_create_room_room_access_section_knocking_option_title") }
  /// Để phòng này hiển thị trong thư mục phòng công cộng, bạn sẽ cần một địa chỉ phòng.
  internal static var screenCreateRoomRoomAddressSectionFooter: String { return L10n.tr("Localizable", "screen_create_room_room_address_section_footer") }
  /// Địa chỉ phòng
  internal static var screenCreateRoomRoomAddressSectionTitle: String { return L10n.tr("Localizable", "screen_create_room_room_address_section_title") }
  /// Tên phòng
  internal static var screenCreateRoomRoomNameLabel: String { return L10n.tr("Localizable", "screen_create_room_room_name_label") }
  /// Khả năng hiển thị phòng
  internal static var screenCreateRoomRoomVisibilitySectionTitle: String { return L10n.tr("Localizable", "screen_create_room_room_visibility_section_title") }
  /// Tạo phòng
  internal static var screenCreateRoomTitle: String { return L10n.tr("Localizable", "screen_create_room_title") }
  /// Chủ đề (tùy chọn)
  internal static var screenCreateRoomTopicLabel: String { return L10n.tr("Localizable", "screen_create_room_topic_label") }
  /// Vui lòng xác nhận rằng bạn muốn vô hiệu hóa tài khoản. Hành động này không thể hoàn tác.
  internal static var screenDeactivateAccountConfirmationDialogContent: String { return L10n.tr("Localizable", "screen_deactivate_account_confirmation_dialog_content") }
  /// Xóa tất cả tin nhắn của tôi
  internal static var screenDeactivateAccountDeleteAllMessages: String { return L10n.tr("Localizable", "screen_deactivate_account_delete_all_messages") }
  /// Cảnh báo: Người dùng tương lai có thể thấy cuộc trò chuyện không đầy đủ.
  internal static var screenDeactivateAccountDeleteAllMessagesNotice: String { return L10n.tr("Localizable", "screen_deactivate_account_delete_all_messages_notice") }
  /// Vô hiệu hóa tài khoản là %1$@, nó sẽ:
  internal static func screenDeactivateAccountDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_deactivate_account_description", String(describing: p1))
  }
  /// không thể đảo ngược
  internal static var screenDeactivateAccountDescriptionBoldPart: String { return L10n.tr("Localizable", "screen_deactivate_account_description_bold_part") }
  /// %1$@ tài khoản của bạn (bạn không thể đăng nhập lại và ID của bạn không thể tái sử dụng).
  internal static func screenDeactivateAccountListItem1(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_deactivate_account_list_item_1", String(describing: p1))
  }
  /// Vô hiệu hóa vĩnh viễn
  internal static var screenDeactivateAccountListItem1BoldPart: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_1_bold_part") }
  /// Xóa bạn khỏi tất cả phòng trò chuyện.
  internal static var screenDeactivateAccountListItem2: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_2") }
  /// Xóa thông tin tài khoản khỏi máy chủ nhận dạng.
  internal static var screenDeactivateAccountListItem3: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_3") }
  /// Tin nhắn của bạn vẫn sẽ hiển thị với người dùng đã đăng ký nhưng sẽ không có sẵn cho người dùng mới hoặc chưa đăng ký nếu bạn chọn xóa chúng.
  internal static var screenDeactivateAccountListItem4: String { return L10n.tr("Localizable", "screen_deactivate_account_list_item_4") }
  /// Vô hiệu hóa tài khoản
  internal static var screenDeactivateAccountTitle: String { return L10n.tr("Localizable", "screen_deactivate_account_title") }
  /// Bạn sẽ không thấy bất kỳ tin nhắn hoặc lời mời phòng nào từ người dùng này
  internal static var screenDeclineAndBlockBlockUserOptionDescription: String { return L10n.tr("Localizable", "screen_decline_and_block_block_user_option_description") }
  /// Chặn người dùng
  internal static var screenDeclineAndBlockBlockUserOptionTitle: String { return L10n.tr("Localizable", "screen_decline_and_block_block_user_option_title") }
  /// Báo cáo phòng này cho nhà cung cấp tài khoản.
  internal static var screenDeclineAndBlockReportUserOptionDescription: String { return L10n.tr("Localizable", "screen_decline_and_block_report_user_option_description") }
  /// Mô tả lý do báo cáo…
  internal static var screenDeclineAndBlockReportUserReasonPlaceholder: String { return L10n.tr("Localizable", "screen_decline_and_block_report_user_reason_placeholder") }
  /// Từ chối và chặn
  internal static var screenDeclineAndBlockTitle: String { return L10n.tr("Localizable", "screen_decline_and_block_title") }
  /// Chặn
  internal static var screenDmDetailsBlockAlertAction: String { return L10n.tr("Localizable", "screen_dm_details_block_alert_action") }
  /// Người dùng bị chặn sẽ không thể gửi tin nhắn cho bạn và tất cả tin nhắn của họ sẽ bị ẩn. Bạn có thể bỏ chặn họ bất cứ lúc nào.
  internal static var screenDmDetailsBlockAlertDescription: String { return L10n.tr("Localizable", "screen_dm_details_block_alert_description") }
  /// Chặn người dùng
  internal static var screenDmDetailsBlockUser: String { return L10n.tr("Localizable", "screen_dm_details_block_user") }
  /// Bỏ chặn
  internal static var screenDmDetailsUnblockAlertAction: String { return L10n.tr("Localizable", "screen_dm_details_unblock_alert_action") }
  /// Bạn sẽ có thể thấy lại tất cả tin nhắn từ họ.
  internal static var screenDmDetailsUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_dm_details_unblock_alert_description") }
  /// Bỏ chặn người dùng
  internal static var screenDmDetailsUnblockUser: String { return L10n.tr("Localizable", "screen_dm_details_unblock_user") }
  /// Bạn có chắc chắn muốn xóa cuộc bình chọn này?
  internal static var screenEditPollDeleteConfirmation: String { return L10n.tr("Localizable", "screen_edit_poll_delete_confirmation") }
  /// Xóa bình chọn
  internal static var screenEditPollDeleteConfirmationTitle: String { return L10n.tr("Localizable", "screen_edit_poll_delete_confirmation_title") }
  /// Chỉnh sửa bình chọn
  internal static var screenEditPollTitle: String { return L10n.tr("Localizable", "screen_edit_poll_title") }
  /// Tên hiển thị
  internal static var screenEditProfileDisplayName: String { return L10n.tr("Localizable", "screen_edit_profile_display_name") }
  /// Tên hiển thị của bạn
  internal static var screenEditProfileDisplayNamePlaceholder: String { return L10n.tr("Localizable", "screen_edit_profile_display_name_placeholder") }
  /// Gặp lỗi không xác định và thông tin không thể thay đổi.
  internal static var screenEditProfileError: String { return L10n.tr("Localizable", "screen_edit_profile_error") }
  /// Không thể cập nhật hồ sơ
  internal static var screenEditProfileErrorTitle: String { return L10n.tr("Localizable", "screen_edit_profile_error_title") }
  /// Chỉnh sửa hồ sơ
  internal static var screenEditProfileTitle: String { return L10n.tr("Localizable", "screen_edit_profile_title") }
  /// Đang cập nhật hồ sơ…
  internal static var screenEditProfileUpdatingDetails: String { return L10n.tr("Localizable", "screen_edit_profile_updating_details") }
  /// Bạn sẽ cần một địa chỉ phòng để làm cho nó hiển thị trong thư mục.
  internal static var screenEditRoomAddressRoomAddressSectionFooter: String { return L10n.tr("Localizable", "screen_edit_room_address_room_address_section_footer") }
  /// Địa chỉ phòng
  internal static var screenEditRoomAddressTitle: String { return L10n.tr("Localizable", "screen_edit_room_address_title") }
  /// Tiếp tục đặt lại
  internal static var screenEncryptionResetActionContinueReset: String { return L10n.tr("Localizable", "screen_encryption_reset_action_continue_reset") }
  /// Chi tiết tài khoản, danh bạ, tùy chọn và danh sách trò chuyện sẽ được giữ
  internal static var screenEncryptionResetBullet1: String { return L10n.tr("Localizable", "screen_encryption_reset_bullet_1") }
  /// Bạn sẽ mất lịch sử tin nhắn chỉ được lưu trữ trên máy chủ
  internal static var screenEncryptionResetBullet2: String { return L10n.tr("Localizable", "screen_encryption_reset_bullet_2") }
  /// Bạn sẽ cần xác minh lại tất cả thiết bị và liên hệ hiện có
  internal static var screenEncryptionResetBullet3: String { return L10n.tr("Localizable", "screen_encryption_reset_bullet_3") }
  /// Chỉ đặt lại danh tính nếu bạn không có quyền truy cập vào thiết bị đã đăng nhập khác và đã mất khóa khôi phục.
  internal static var screenEncryptionResetFooter: String { return L10n.tr("Localizable", "screen_encryption_reset_footer") }
  /// Không thể xác nhận? Bạn sẽ cần đặt lại danh tính.
  internal static var screenEncryptionResetTitle: String { return L10n.tr("Localizable", "screen_encryption_reset_title") }
  /// Cuộc trò chuyện
  internal static var screenHomeTabChats: String { return L10n.tr("Localizable", "screen_home_tab_chats") }
  /// Không gian
  internal static var screenHomeTabSpaces: String { return L10n.tr("Localizable", "screen_home_tab_spaces") }
  /// Không thể xác nhận?
  internal static var screenIdentityConfirmationCannotConfirm: String { return L10n.tr("Localizable", "screen_identity_confirmation_cannot_confirm") }
  /// Tạo khóa khôi phục mới
  internal static var screenIdentityConfirmationCreateNewRecoveryKey: String { return L10n.tr("Localizable", "screen_identity_confirmation_create_new_recovery_key") }
  /// Xác minh thiết bị này để thiết lập nhắn tin bảo mật.
  internal static var screenIdentityConfirmationSubtitle: String { return L10n.tr("Localizable", "screen_identity_confirmation_subtitle") }
  /// Xác nhận danh tính của bạn
  internal static var screenIdentityConfirmationTitle: String { return L10n.tr("Localizable", "screen_identity_confirmation_title") }
  /// Sử dụng thiết bị khác
  internal static var screenIdentityConfirmationUseAnotherDevice: String { return L10n.tr("Localizable", "screen_identity_confirmation_use_another_device") }
  /// Sử dụng khóa khôi phục
  internal static var screenIdentityConfirmationUseRecoveryKey: String { return L10n.tr("Localizable", "screen_identity_confirmation_use_recovery_key") }
  /// Giờ bạn có thể đọc hoặc gửi tin nhắn một cách an toàn, và bất kỳ ai bạn trò chuyện cũng có thể tin tưởng thiết bị này.
  internal static var screenIdentityConfirmedSubtitle: String { return L10n.tr("Localizable", "screen_identity_confirmed_subtitle") }
  /// Thiết bị đã xác minh
  internal static var screenIdentityConfirmedTitle: String { return L10n.tr("Localizable", "screen_identity_confirmed_title") }
  /// Sử dụng thiết bị khác
  internal static var screenIdentityUseAnotherDevice: String { return L10n.tr("Localizable", "screen_identity_use_another_device") }
  /// Đang chờ thiết bị khác…
  internal static var screenIdentityWaitingOnOtherDevice: String { return L10n.tr("Localizable", "screen_identity_waiting_on_other_device") }
  /// Bạn có chắc chắn muốn từ chối lời mời tham gia %1$@?
  internal static func screenInvitesDeclineChatMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_decline_chat_message", String(describing: p1))
  }
  /// Từ chối lời mời
  internal static var screenInvitesDeclineChatTitle: String { return L10n.tr("Localizable", "screen_invites_decline_chat_title") }
  /// Bạn có chắc chắn muốn từ chối cuộc trò chuyện riêng này với %1$@?
  internal static func screenInvitesDeclineDirectChatMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_decline_direct_chat_message", String(describing: p1))
  }
  /// Từ chối trò chuyện
  internal static var screenInvitesDeclineDirectChatTitle: String { return L10n.tr("Localizable", "screen_invites_decline_direct_chat_title") }
  /// Không có lời mời
  internal static var screenInvitesEmptyList: String { return L10n.tr("Localizable", "screen_invites_empty_list") }
  /// %1$@ (%2$@) đã mời bạn
  internal static func screenInvitesInvitedYou(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_invites_invited_you", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã bị cấm khỏi phòng này bởi %1$@.
  internal static func screenJoinRoomBanByMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_join_room_ban_by_message", String(describing: p1))
  }
  /// Bạn đã bị cấm khỏi phòng này
  internal static var screenJoinRoomBanMessage: String { return L10n.tr("Localizable", "screen_join_room_ban_message") }
  /// Lý do: %1$@.
  internal static func screenJoinRoomBanReason(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_join_room_ban_reason", String(describing: p1))
  }
  /// Hủy yêu cầu
  internal static var screenJoinRoomCancelKnockAction: String { return L10n.tr("Localizable", "screen_join_room_cancel_knock_action") }
  /// Có, hủy
  internal static var screenJoinRoomCancelKnockAlertConfirmation: String { return L10n.tr("Localizable", "screen_join_room_cancel_knock_alert_confirmation") }
  /// Bạn có chắc chắn muốn hủy yêu cầu tham gia phòng này?
  internal static var screenJoinRoomCancelKnockAlertDescription: String { return L10n.tr("Localizable", "screen_join_room_cancel_knock_alert_description") }
  /// Hủy yêu cầu tham gia
  internal static var screenJoinRoomCancelKnockAlertTitle: String { return L10n.tr("Localizable", "screen_join_room_cancel_knock_alert_title") }
  /// Có, từ chối & chặn
  internal static var screenJoinRoomDeclineAndBlockAlertConfirmation: String { return L10n.tr("Localizable", "screen_join_room_decline_and_block_alert_confirmation") }
  /// Bạn có chắc chắn muốn từ chối lời mời tham gia phòng này? Điều này cũng sẽ ngăn %1$@ liên hệ với bạn hoặc mời bạn vào phòng.
  internal static func screenJoinRoomDeclineAndBlockAlertMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_join_room_decline_and_block_alert_message", String(describing: p1))
  }
  /// Từ chối lời mời & chặn
  internal static var screenJoinRoomDeclineAndBlockAlertTitle: String { return L10n.tr("Localizable", "screen_join_room_decline_and_block_alert_title") }
  /// Từ chối và chặn
  internal static var screenJoinRoomDeclineAndBlockButtonTitle: String { return L10n.tr("Localizable", "screen_join_room_decline_and_block_button_title") }
  /// Tham gia phòng thất bại.
  internal static var screenJoinRoomFailMessage: String { return L10n.tr("Localizable", "screen_join_room_fail_message") }
  /// Phòng này chỉ được mời hoặc có thể có hạn chế truy cập ở cấp không gian.
  internal static var screenJoinRoomFailReason: String { return L10n.tr("Localizable", "screen_join_room_fail_reason") }
  /// Quên phòng này
  internal static var screenJoinRoomForgetAction: String { return L10n.tr("Localizable", "screen_join_room_forget_action") }
  /// Bạn cần lời mời để tham gia phòng này
  internal static var screenJoinRoomInviteRequiredMessage: String { return L10n.tr("Localizable", "screen_join_room_invite_required_message") }
  /// Tham gia phòng
  internal static var screenJoinRoomJoinAction: String { return L10n.tr("Localizable", "screen_join_room_join_action") }
  /// Bạn có thể cần được mời hoặc là thành viên của không gian để tham gia.
  internal static var screenJoinRoomJoinRestrictedMessage: String { return L10n.tr("Localizable", "screen_join_room_join_restricted_message") }
  /// Gửi yêu cầu tham gia
  internal static var screenJoinRoomKnockAction: String { return L10n.tr("Localizable", "screen_join_room_knock_action") }
  /// Ký tự cho phép %1$d trong %2$d
  internal static func screenJoinRoomKnockMessageCharactersCount(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "screen_join_room_knock_message_characters_count", p1, p2)
  }
  /// Tin nhắn (tùy chọn)
  internal static var screenJoinRoomKnockMessageDescription: String { return L10n.tr("Localizable", "screen_join_room_knock_message_description") }
  /// Bạn sẽ nhận được lời mời tham gia phòng nếu yêu cầu được chấp nhận.
  internal static var screenJoinRoomKnockSentDescription: String { return L10n.tr("Localizable", "screen_join_room_knock_sent_description") }
  /// Yêu cầu tham gia đã gửi
  internal static var screenJoinRoomKnockSentTitle: String { return L10n.tr("Localizable", "screen_join_room_knock_sent_title") }
  /// Chúng tôi không thể hiển thị xem trước phòng. Điều này có thể do vấn đề mạng hoặc máy chủ.
  internal static var screenJoinRoomLoadingAlertMessage: String { return L10n.tr("Localizable", "screen_join_room_loading_alert_message") }
  /// Chúng tôi không thể hiển thị xem trước phòng này
  internal static var screenJoinRoomLoadingAlertTitle: String { return L10n.tr("Localizable", "screen_join_room_loading_alert_title") }
  /// %1$@ chưa hỗ trợ không gian. Bạn có thể truy cập không gian trên web.
  internal static func screenJoinRoomSpaceNotSupportedDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_join_room_space_not_supported_description", String(describing: p1))
  }
  /// Không gian chưa được hỗ trợ
  internal static var screenJoinRoomSpaceNotSupportedTitle: String { return L10n.tr("Localizable", "screen_join_room_space_not_supported_title") }
  /// Nhấp nút bên dưới và quản trị viên phòng sẽ được thông báo. Bạn sẽ có thể tham gia cuộc trò chuyện khi được phê duyệt.
  internal static var screenJoinRoomSubtitleKnock: String { return L10n.tr("Localizable", "screen_join_room_subtitle_knock") }
  /// Bạn phải là thành viên của phòng này để xem lịch sử tin nhắn.
  internal static var screenJoinRoomSubtitleNoPreview: String { return L10n.tr("Localizable", "screen_join_room_subtitle_no_preview") }
  /// Muốn tham gia phòng này?
  internal static var screenJoinRoomTitleKnock: String { return L10n.tr("Localizable", "screen_join_room_title_knock") }
  /// Xem trước không khả dụng
  internal static var screenJoinRoomTitleNoPreview: String { return L10n.tr("Localizable", "screen_join_room_title_no_preview") }
  /// Tắt
  internal static var screenKeyBackupDisableConfirmationActionTurnOff: String { return L10n.tr("Localizable", "screen_key_backup_disable_confirmation_action_turn_off") }
  /// Bạn sẽ mất tin nhắn mã hóa nếu bị đăng xuất khỏi tất cả thiết bị.
  internal static var screenKeyBackupDisableConfirmationDescription: String { return L10n.tr("Localizable", "screen_key_backup_disable_confirmation_description") }
  /// Bạn có chắc chắn muốn tắt sao lưu?
  internal static var screenKeyBackupDisableConfirmationTitle: String { return L10n.tr("Localizable", "screen_key_backup_disable_confirmation_title") }
  /// Xóa kho lưu trữ khóa sẽ xóa danh tính mã hóa và khóa tin nhắn khỏi máy chủ và tắt các tính năng bảo mật sau:
  internal static var screenKeyBackupDisableDescription: String { return L10n.tr("Localizable", "screen_key_backup_disable_description") }
  /// Bạn sẽ không có lịch sử tin nhắn mã hóa trên thiết bị mới
  internal static var screenKeyBackupDisableDescriptionPoint1: String { return L10n.tr("Localizable", "screen_key_backup_disable_description_point_1") }
  /// Bạn sẽ mất quyền truy cập vào tin nhắn mã hóa nếu bị đăng xuất khỏi %1$@ ở mọi nơi
  internal static func screenKeyBackupDisableDescriptionPoint2(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_key_backup_disable_description_point_2", String(describing: p1))
  }
  /// Bạn có chắc chắn muốn tắt kho lưu trữ khóa và xóa nó?
  internal static var screenKeyBackupDisableTitle: String { return L10n.tr("Localizable", "screen_key_backup_disable_title") }
  /// Có, chấp nhận tất cả
  internal static var screenKnockRequestsListAcceptAllAlertConfirmButtonTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_alert_confirm_button_title") }
  /// Bạn có chắc chắn muốn chấp nhận tất cả yêu cầu tham gia?
  internal static var screenKnockRequestsListAcceptAllAlertDescription: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_alert_description") }
  /// Chấp nhận tất cả yêu cầu
  internal static var screenKnockRequestsListAcceptAllAlertTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_alert_title") }
  /// Chấp nhận tất cả
  internal static var screenKnockRequestsListAcceptAllButtonTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_button_title") }
  /// Chúng tôi không thể chấp nhận tất cả yêu cầu. Bạn có muốn thử lại?
  internal static var screenKnockRequestsListAcceptAllFailedAlertDescription: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_failed_alert_description") }
  /// Chấp nhận tất cả yêu cầu thất bại
  internal static var screenKnockRequestsListAcceptAllFailedAlertTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_failed_alert_title") }
  /// Đang chấp nhận tất cả yêu cầu tham gia
  internal static var screenKnockRequestsListAcceptAllLoadingTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_all_loading_title") }
  /// Chúng tôi không thể chấp nhận yêu cầu này. Bạn có muốn thử lại?
  internal static var screenKnockRequestsListAcceptFailedAlertDescription: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_failed_alert_description") }
  /// Chấp nhận yêu cầu thất bại
  internal static var screenKnockRequestsListAcceptFailedAlertTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_failed_alert_title") }
  /// Đang chấp nhận yêu cầu tham gia
  internal static var screenKnockRequestsListAcceptLoadingTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_accept_loading_title") }
  /// Có, từ chối và cấm
  internal static var screenKnockRequestsListBanAlertConfirmButtonTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_ban_alert_confirm_button_title") }
  /// Bạn có chắc chắn muốn từ chối và cấm %1$@? Người dùng này sẽ không thể yêu cầu quyền truy cập tham gia phòng này lại.
  internal static func screenKnockRequestsListBanAlertDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_knock_requests_list_ban_alert_description", String(describing: p1))
  }
  /// Từ chối và cấm truy cập
  internal static var screenKnockRequestsListBanAlertTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_ban_alert_title") }
  /// Đang từ chối và cấm truy cập
  internal static var screenKnockRequestsListBanLoadingTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_ban_loading_title") }
  /// Có, từ chối
  internal static var screenKnockRequestsListDeclineAlertConfirmButtonTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_decline_alert_confirm_button_title") }
  /// Bạn có chắc chắn muốn từ chối yêu cầu tham gia phòng này của %1$@?
  internal static func screenKnockRequestsListDeclineAlertDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_knock_requests_list_decline_alert_description", String(describing: p1))
  }
  /// Từ chối truy cập
  internal static var screenKnockRequestsListDeclineAlertTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_decline_alert_title") }
  /// Từ chối và cấm
  internal static var screenKnockRequestsListDeclineAndBanActionTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_decline_and_ban_action_title") }
  /// Chúng tôi không thể từ chối yêu cầu này. Bạn có muốn thử lại?
  internal static var screenKnockRequestsListDeclineFailedAlertDescription: String { return L10n.tr("Localizable", "screen_knock_requests_list_decline_failed_alert_description") }
  /// Từ chối yêu cầu thất bại
  internal static var screenKnockRequestsListDeclineFailedAlertTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_decline_failed_alert_title") }
  /// Đang từ chối yêu cầu tham gia
  internal static var screenKnockRequestsListDeclineLoadingTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_decline_loading_title") }
  /// Khi ai đó yêu cầu tham gia phòng, bạn sẽ có thể thấy yêu cầu của họ ở đây.
  internal static var screenKnockRequestsListEmptyStateDescription: String { return L10n.tr("Localizable", "screen_knock_requests_list_empty_state_description") }
  /// Không có yêu cầu tham gia đang chờ
  internal static var screenKnockRequestsListEmptyStateTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_empty_state_title") }
  /// Đang tải yêu cầu tham gia…
  internal static var screenKnockRequestsListInitialLoadingTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_initial_loading_title") }
  /// Yêu cầu tham gia
  internal static var screenKnockRequestsListTitle: String { return L10n.tr("Localizable", "screen_knock_requests_list_title") }
  /// Liên kết được chia sẻ trong phòng này sẽ hiển thị ở đây.
  internal static var screenLinksTimelineEmptyDescription: String { return L10n.tr("Localizable", "screen_links_timeline_empty_description") }
  /// Chưa có liên kết nào được chia sẻ
  internal static var screenLinksTimelineEmptyTitle: String { return L10n.tr("Localizable", "screen_links_timeline_empty_title") }
  /// Lọc theo người gửi
  internal static var screenLinksTimelineFilterBySender: String { return L10n.tr("Localizable", "screen_links_timeline_filter_by_sender") }
  /// Liên kết
  internal static var screenLinksTimelineTitle: String { return L10n.tr("Localizable", "screen_links_timeline_title") }
  /// Tài khoản này đã bị vô hiệu hóa.
  internal static var screenLoginErrorDeactivatedAccount: String { return L10n.tr("Localizable", "screen_login_error_deactivated_account") }
  /// Tên người dùng và/hoặc mật khẩu không chính xác
  internal static var screenLoginErrorInvalidCredentials: String { return L10n.tr("Localizable", "screen_login_error_invalid_credentials") }
  /// Đây không phải là định danh người dùng hợp lệ. Định dạng mong đợi: '@user:homeserver.org'
  internal static var screenLoginErrorInvalidUserId: String { return L10n.tr("Localizable", "screen_login_error_invalid_user_id") }
  /// Máy chủ này được cấu hình để sử dụng token làm mới. Điều này không được hỗ trợ khi sử dụng đăng nhập bằng mật khẩu.
  internal static var screenLoginErrorRefreshTokens: String { return L10n.tr("Localizable", "screen_login_error_refresh_tokens") }
  /// Homeserver đã chọn không hỗ trợ đăng nhập bằng mật khẩu hoặc OIDC. Vui lòng liên hệ quản trị viên hoặc chọn homeserver khác.
  internal static var screenLoginErrorUnsupportedAuthentication: String { return L10n.tr("Localizable", "screen_login_error_unsupported_authentication") }
  /// Nhập chi tiết của bạn
  internal static var screenLoginFormHeader: String { return L10n.tr("Localizable", "screen_login_form_header") }
  /// Matrix là mạng mở cho giao tiếp bảo mật, phi tập trung.
  internal static var screenLoginSubtitle: String { return L10n.tr("Localizable", "screen_login_subtitle") }
  /// Chào mừng bạn trở lại!
  internal static var screenLoginTitle: String { return L10n.tr("Localizable", "screen_login_title") }
  /// Đăng nhập vào %1$@
  internal static func screenLoginTitleWithHomeserver(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_login_title_with_homeserver", String(describing: p1))
  }
  /// Tệp này sẽ bị xóa khỏi phòng và thành viên sẽ không có quyền truy cập.
  internal static var screenMediaBrowserDeleteConfirmationSubtitle: String { return L10n.tr("Localizable", "screen_media_browser_delete_confirmation_subtitle") }
  /// Xóa tệp?
  internal static var screenMediaBrowserDeleteConfirmationTitle: String { return L10n.tr("Localizable", "screen_media_browser_delete_confirmation_title") }
  /// Kiểm tra kết nối internet và thử lại.
  internal static var screenMediaBrowserDownloadErrorMessage: String { return L10n.tr("Localizable", "screen_media_browser_download_error_message") }
  /// Tài liệu, tệp âm thanh và tin nhắn thoại được tải lên phòng này sẽ hiển thị ở đây.
  internal static var screenMediaBrowserFilesEmptyStateSubtitle: String { return L10n.tr("Localizable", "screen_media_browser_files_empty_state_subtitle") }
  /// Chưa có tệp nào được tải lên
  internal static var screenMediaBrowserFilesEmptyStateTitle: String { return L10n.tr("Localizable", "screen_media_browser_files_empty_state_title") }
  /// Đang tải tệp…
  internal static var screenMediaBrowserListLoadingFiles: String { return L10n.tr("Localizable", "screen_media_browser_list_loading_files") }
  /// Đang tải media…
  internal static var screenMediaBrowserListLoadingMedia: String { return L10n.tr("Localizable", "screen_media_browser_list_loading_media") }
  /// Tệp
  internal static var screenMediaBrowserListModeFiles: String { return L10n.tr("Localizable", "screen_media_browser_list_mode_files") }
  /// Media
  internal static var screenMediaBrowserListModeMedia: String { return L10n.tr("Localizable", "screen_media_browser_list_mode_media") }
  /// Hình ảnh và video được tải lên phòng này sẽ hiển thị ở đây.
  internal static var screenMediaBrowserMediaEmptyStateSubtitle: String { return L10n.tr("Localizable", "screen_media_browser_media_empty_state_subtitle") }
  /// Chưa có media nào được tải lên
  internal static var screenMediaBrowserMediaEmptyStateTitle: String { return L10n.tr("Localizable", "screen_media_browser_media_empty_state_title") }
  /// Media và tệp
  internal static var screenMediaBrowserTitle: String { return L10n.tr("Localizable", "screen_media_browser_title") }
  /// Định dạng tệp
  internal static var screenMediaDetailsFileFormat: String { return L10n.tr("Localizable", "screen_media_details_file_format") }
  /// Tên tệp
  internal static var screenMediaDetailsFilename: String { return L10n.tr("Localizable", "screen_media_details_filename") }
  /// Không còn tệp nào để hiển thị
  internal static var screenMediaDetailsNoMoreFilesToShow: String { return L10n.tr("Localizable", "screen_media_details_no_more_files_to_show") }
  /// Không còn media nào để hiển thị
  internal static var screenMediaDetailsNoMoreMediaToShow: String { return L10n.tr("Localizable", "screen_media_details_no_more_media_to_show") }
  /// Tải lên bởi
  internal static var screenMediaDetailsUploadedBy: String { return L10n.tr("Localizable", "screen_media_details_uploaded_by") }
  /// Tải lên vào
  internal static var screenMediaDetailsUploadedOn: String { return L10n.tr("Localizable", "screen_media_details_uploaded_on") }
  /// Chọn media thất bại, vui lòng thử lại.
  internal static var screenMediaPickerErrorFailedSelection: String { return L10n.tr("Localizable", "screen_media_picker_error_failed_selection") }
  /// Chú thích có thể không hiển thị với những người sử dụng ứng dụng cũ.
  internal static var screenMediaUploadPreviewCaptionWarning: String { return L10n.tr("Localizable", "screen_media_upload_preview_caption_warning") }
  /// Tệp không thể tải lên.
  internal static var screenMediaUploadPreviewErrorCouldNotBeUploaded: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_could_not_be_uploaded") }
  /// Xử lý media để tải lên thất bại, vui lòng thử lại.
  internal static var screenMediaUploadPreviewErrorFailedProcessing: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_failed_processing") }
  /// Tải lên media thất bại, vui lòng thử lại.
  internal static var screenMediaUploadPreviewErrorFailedSending: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_failed_sending") }
  /// Kích thước tệp tối đa cho phép là %1$@.
  internal static func screenMediaUploadPreviewErrorTooLargeMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_media_upload_preview_error_too_large_message", String(describing: p1))
  }
  /// Tệp quá lớn để tải lên
  internal static var screenMediaUploadPreviewErrorTooLargeTitle: String { return L10n.tr("Localizable", "screen_media_upload_preview_error_too_large_title") }
  /// Đây là quá trình một lần, cảm ơn bạn đã chờ đợi.
  internal static var screenMigrationMessage: String { return L10n.tr("Localizable", "screen_migration_message") }
  /// Đang thiết lập tài khoản của bạn.
  internal static var screenMigrationTitle: String { return L10n.tr("Localizable", "screen_migration_title") }
  /// Bạn có thể thay đổi cài đặt sau.
  internal static var screenNotificationOptinSubtitle: String { return L10n.tr("Localizable", "screen_notification_optin_subtitle") }
  /// Cho phép thông báo và không bao giờ bỏ lỡ tin nhắn
  internal static var screenNotificationOptinTitle: String { return L10n.tr("Localizable", "screen_notification_optin_title") }
  /// Cài đặt bổ sung
  internal static var screenNotificationSettingsAdditionalSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_additional_settings_section_title") }
  /// Cuộc gọi âm thanh và video
  internal static var screenNotificationSettingsCallsLabel: String { return L10n.tr("Localizable", "screen_notification_settings_calls_label") }
  /// Cấu hình không khớp
  internal static var screenNotificationSettingsConfigurationMismatch: String { return L10n.tr("Localizable", "screen_notification_settings_configuration_mismatch") }
  /// Chúng tôi đã đơn giản hóa cài đặt thông báo để tùy chọn dễ tìm hơn. Một số cài đặt tùy chỉnh bạn đã chọn trước đây không hiển thị ở đây, nhưng vẫn đang hoạt động.
  /// 
  /// Nếu bạn tiếp tục, một số cài đặt có thể thay đổi.
  internal static var screenNotificationSettingsConfigurationMismatchDescription: String { return L10n.tr("Localizable", "screen_notification_settings_configuration_mismatch_description") }
  /// Trò chuyện trực tiếp
  internal static var screenNotificationSettingsDirectChats: String { return L10n.tr("Localizable", "screen_notification_settings_direct_chats") }
  /// Cài đặt tùy chỉnh cho từng cuộc trò chuyện
  internal static var screenNotificationSettingsEditCustomSettingsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_edit_custom_settings_section_title") }
  /// Đã xảy ra lỗi khi cập nhật cài đặt thông báo.
  internal static var screenNotificationSettingsEditFailedUpdatingDefaultMode: String { return L10n.tr("Localizable", "screen_notification_settings_edit_failed_updating_default_mode") }
  /// Tất cả tin nhắn
  internal static var screenNotificationSettingsEditModeAllMessages: String { return L10n.tr("Localizable", "screen_notification_settings_edit_mode_all_messages") }
  /// Chỉ nhắc đến và từ khóa
  internal static var screenNotificationSettingsEditModeMentionsAndKeywords: String { return L10n.tr("Localizable", "screen_notification_settings_edit_mode_mentions_and_keywords") }
  /// Trong trò chuyện trực tiếp, thông báo cho tôi khi có
  internal static var screenNotificationSettingsEditScreenDirectSectionHeader: String { return L10n.tr("Localizable", "screen_notification_settings_edit_screen_direct_section_header") }
  /// Trong trò chuyện nhóm, thông báo cho tôi khi có
  internal static var screenNotificationSettingsEditScreenGroupSectionHeader: String { return L10n.tr("Localizable", "screen_notification_settings_edit_screen_group_section_header") }
  /// Bật thông báo trên thiết bị này
  internal static var screenNotificationSettingsEnableNotifications: String { return L10n.tr("Localizable", "screen_notification_settings_enable_notifications") }
  /// Cấu hình chưa được sửa, vui lòng thử lại.
  internal static var screenNotificationSettingsFailedFixingConfiguration: String { return L10n.tr("Localizable", "screen_notification_settings_failed_fixing_configuration") }
  /// Trò chuyện nhóm
  internal static var screenNotificationSettingsGroupChats: String { return L10n.tr("Localizable", "screen_notification_settings_group_chats") }
  /// Lời mời
  internal static var screenNotificationSettingsInviteForMeLabel: String { return L10n.tr("Localizable", "screen_notification_settings_invite_for_me_label") }
  /// Homeserver của bạn không hỗ trợ tùy chọn này trong phòng mã hóa, bạn có thể không được thông báo trong một số phòng.
  internal static var screenNotificationSettingsMentionsOnlyDisclaimer: String { return L10n.tr("Localizable", "screen_notification_settings_mentions_only_disclaimer") }
  /// Nhắc đến
  internal static var screenNotificationSettingsMentionsSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_mentions_section_title") }
  /// Tất cả
  internal static var screenNotificationSettingsModeAll: String { return L10n.tr("Localizable", "screen_notification_settings_mode_all") }
  /// Nhắc đến
  internal static var screenNotificationSettingsModeMentions: String { return L10n.tr("Localizable", "screen_notification_settings_mode_mentions") }
  /// Thông báo cho tôi khi có
  internal static var screenNotificationSettingsNotificationSectionTitle: String { return L10n.tr("Localizable", "screen_notification_settings_notification_section_title") }
  /// Thông báo cho tôi về @room
  internal static var screenNotificationSettingsRoomMentionLabel: String { return L10n.tr("Localizable", "screen_notification_settings_room_mention_label") }
  /// Để nhận thông báo, vui lòng thay đổi %1$@.
  internal static func screenNotificationSettingsSystemNotificationsActionRequired(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_notification_settings_system_notifications_action_required", String(describing: p1))
  }
  /// cài đặt hệ thống
  internal static var screenNotificationSettingsSystemNotificationsActionRequiredContentLink: String { return L10n.tr("Localizable", "screen_notification_settings_system_notifications_action_required_content_link") }
  /// Thông báo hệ thống đã tắt
  internal static var screenNotificationSettingsSystemNotificationsTurnedOff: String { return L10n.tr("Localizable", "screen_notification_settings_system_notifications_turned_off") }
  /// Thông báo
  internal static var screenNotificationSettingsTitle: String { return L10n.tr("Localizable", "screen_notification_settings_title") }
  /// Phiên bản %1$@
  internal static func screenOnboardingAppVersion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_app_version", String(describing: p1))
  }
  /// Đăng nhập thủ công
  internal static var screenOnboardingSignInManually: String { return L10n.tr("Localizable", "screen_onboarding_sign_in_manually") }
  /// Đăng nhập vào %1$@
  internal static func screenOnboardingSignInTo(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_sign_in_to", String(describing: p1))
  }
  /// Đăng nhập bằng mã QR
  internal static var screenOnboardingSignInWithQrCode: String { return L10n.tr("Localizable", "screen_onboarding_sign_in_with_qr_code") }
  /// Tạo tài khoản
  internal static var screenOnboardingSignUp: String { return L10n.tr("Localizable", "screen_onboarding_sign_up") }
  /// Chào mừng đến với %1$@ nhanh nhất từ trước đến nay. Siêu mạnh cho tốc độ và sự đơn giản.
  internal static func screenOnboardingWelcomeMessage(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_welcome_message", String(describing: p1))
  }
  /// Chào mừng đến với %1$@. Siêu mạnh, cho tốc độ và sự đơn giản.
  internal static func screenOnboardingWelcomeSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_onboarding_welcome_subtitle", String(describing: p1))
  }
  /// Hãy là chính mình
  internal static var screenOnboardingWelcomeTitle: String { return L10n.tr("Localizable", "screen_onboarding_welcome_title") }
  /// Nhấn vào tin nhắn và chọn "%1$@" để bao gồm ở đây.
  internal static func screenPinnedTimelineEmptyStateDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_pinned_timeline_empty_state_description", String(describing: p1))
  }
  /// Ghim tin nhắn quan trọng để có thể dễ dàng tìm thấy
  internal static var screenPinnedTimelineEmptyStateHeadline: String { return L10n.tr("Localizable", "screen_pinned_timeline_empty_state_headline") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenPinnedTimelineScreenTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_pinned_timeline_screen_title", p1)
  }
  /// Tin nhắn đã ghim
  internal static var screenPinnedTimelineScreenTitleEmpty: String { return L10n.tr("Localizable", "screen_pinned_timeline_screen_title_empty") }
  /// Không tìm thấy cuộc bình chọn nào đang diễn ra.
  internal static var screenPollsHistoryEmptyOngoing: String { return L10n.tr("Localizable", "screen_polls_history_empty_ongoing") }
  /// Không tìm thấy cuộc bình chọn nào đã kết thúc.
  internal static var screenPollsHistoryEmptyPast: String { return L10n.tr("Localizable", "screen_polls_history_empty_past") }
  /// Đang diễn ra
  internal static var screenPollsHistoryFilterOngoing: String { return L10n.tr("Localizable", "screen_polls_history_filter_ongoing") }
  /// Đã kết thúc
  internal static var screenPollsHistoryFilterPast: String { return L10n.tr("Localizable", "screen_polls_history_filter_past") }
  /// Bình chọn
  internal static var screenPollsHistoryTitle: String { return L10n.tr("Localizable", "screen_polls_history_title") }
  /// Lịch sử push
  internal static var screenPushHistoryTitle: String { return L10n.tr("Localizable", "screen_push_history_title") }
  /// Đang thiết lập kết nối an toàn
  internal static var screenQrCodeLoginConnectingSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_connecting_subtitle") }
  /// Không thể tạo kết nối an toàn đến thiết bị mới. Các thiết bị hiện có của bạn vẫn an toàn và bạn không cần lo lắng về chúng.
  internal static var screenQrCodeLoginConnectionNoteSecureStateDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_description") }
  /// Giờ phải làm gì?
  internal static var screenQrCodeLoginConnectionNoteSecureStateListHeader: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_header") }
  /// Thử đăng nhập lại bằng mã QR phòng trường hợp đây là vấn đề mạng
  internal static var screenQrCodeLoginConnectionNoteSecureStateListItem1: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_item_1") }
  /// Nếu gặp vấn đề tương tự, thử mạng wifi khác hoặc sử dụng dữ liệu di động thay vì wifi
  internal static var screenQrCodeLoginConnectionNoteSecureStateListItem2: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_item_2") }
  /// Nếu không được, hãy đăng nhập thủ công
  internal static var screenQrCodeLoginConnectionNoteSecureStateListItem3: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_list_item_3") }
  /// Kết nối không an toàn
  internal static var screenQrCodeLoginConnectionNoteSecureStateTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_connection_note_secure_state_title") }
  /// Bạn sẽ được yêu cầu nhập hai chữ số hiển thị trên thiết bị này.
  internal static var screenQrCodeLoginDeviceCodeSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_device_code_subtitle") }
  /// Nhập số bên dưới trên thiết bị khác
  internal static var screenQrCodeLoginDeviceCodeTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_device_code_title") }
  /// Đăng nhập vào thiết bị khác và thử lại, hoặc sử dụng thiết bị khác đã đăng nhập.
  internal static var screenQrCodeLoginDeviceNotSignedInScanStateDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_device_not_signed_in_scan_state_description") }
  /// Thiết bị khác chưa đăng nhập
  internal static var screenQrCodeLoginDeviceNotSignedInScanStateSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_device_not_signed_in_scan_state_subtitle") }
  /// Đăng nhập đã bị hủy trên thiết bị khác.
  internal static var screenQrCodeLoginErrorCancelledSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_cancelled_subtitle") }
  /// Yêu cầu đăng nhập đã hủy
  internal static var screenQrCodeLoginErrorCancelledTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_cancelled_title") }
  /// Đăng nhập đã bị từ chối trên thiết bị khác.
  internal static var screenQrCodeLoginErrorDeclinedSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_declined_subtitle") }
  /// Đăng nhập bị từ chối
  internal static var screenQrCodeLoginErrorDeclinedTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_declined_title") }
  /// Đăng nhập đã hết hạn. Vui lòng thử lại.
  internal static var screenQrCodeLoginErrorExpiredSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_expired_subtitle") }
  /// Đăng nhập không hoàn thành kịp thời
  internal static var screenQrCodeLoginErrorExpiredTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_expired_title") }
  /// Thiết bị khác không hỗ trợ đăng nhập vào %@ bằng mã QR.
  /// 
  /// Thử đăng nhập thủ công hoặc quét mã QR bằng thiết bị khác.
  internal static func screenQrCodeLoginErrorLinkingNotSuportedSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_error_linking_not_suported_subtitle", String(describing: p1))
  }
  /// Mã QR không được hỗ trợ
  internal static var screenQrCodeLoginErrorLinkingNotSuportedTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_error_linking_not_suported_title") }
  /// Nhà cung cấp tài khoản không hỗ trợ %1$@.
  internal static func screenQrCodeLoginErrorSlidingSyncNotSupportedSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_error_sliding_sync_not_supported_subtitle", String(describing: p1))
  }
  /// %1$@ không được hỗ trợ
  internal static func screenQrCodeLoginErrorSlidingSyncNotSupportedTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_error_sliding_sync_not_supported_title", String(describing: p1))
  }
  /// Sẵn sàng quét
  internal static var screenQrCodeLoginInitialStateButtonTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_button_title") }
  /// Mở %1$@ trên thiết bị desktop
  internal static func screenQrCodeLoginInitialStateItem1(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_1", String(describing: p1))
  }
  /// Nhấp vào avatar của bạn
  internal static var screenQrCodeLoginInitialStateItem2: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_2") }
  /// Chọn %1$@
  internal static func screenQrCodeLoginInitialStateItem3(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_3", String(describing: p1))
  }
  /// "Liên kết thiết bị mới"
  internal static var screenQrCodeLoginInitialStateItem3Action: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_3_action") }
  /// Quét mã QR bằng thiết bị này
  internal static var screenQrCodeLoginInitialStateItem4: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_item_4") }
  /// Chỉ khả dụng nếu nhà cung cấp tài khoản hỗ trợ.
  internal static var screenQrCodeLoginInitialStateSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_initial_state_subtitle") }
  /// Mở %1$@ trên thiết bị khác để lấy mã QR
  internal static func screenQrCodeLoginInitialStateTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_initial_state_title", String(describing: p1))
  }
  /// Sử dụng mã QR hiển thị trên thiết bị khác.
  internal static var screenQrCodeLoginInvalidScanStateDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_invalid_scan_state_description") }
  /// Thử lại
  internal static var screenQrCodeLoginInvalidScanStateRetryButton: String { return L10n.tr("Localizable", "screen_qr_code_login_invalid_scan_state_retry_button") }
  /// Mã QR sai
  internal static var screenQrCodeLoginInvalidScanStateSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_invalid_scan_state_subtitle") }
  /// Đi đến cài đặt camera
  internal static var screenQrCodeLoginNoCameraPermissionButton: String { return L10n.tr("Localizable", "screen_qr_code_login_no_camera_permission_button") }
  /// Bạn cần cấp quyền cho %1$@ sử dụng camera thiết bị để tiếp tục.
  internal static func screenQrCodeLoginNoCameraPermissionStateDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_qr_code_login_no_camera_permission_state_description", String(describing: p1))
  }
  /// Cho phép truy cập camera để quét mã QR
  internal static var screenQrCodeLoginNoCameraPermissionStateTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_no_camera_permission_state_title") }
  /// Quét mã QR
  internal static var screenQrCodeLoginScanningStateTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_scanning_state_title") }
  /// Bắt đầu lại
  internal static var screenQrCodeLoginStartOverButton: String { return L10n.tr("Localizable", "screen_qr_code_login_start_over_button") }
  /// Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.
  internal static var screenQrCodeLoginUnknownErrorDescription: String { return L10n.tr("Localizable", "screen_qr_code_login_unknown_error_description") }
  /// Đang chờ thiết bị khác
  internal static var screenQrCodeLoginVerifyCodeLoading: String { return L10n.tr("Localizable", "screen_qr_code_login_verify_code_loading") }
  /// Nhà cung cấp tài khoản có thể yêu cầu mã sau để xác minh đăng nhập.
  internal static var screenQrCodeLoginVerifyCodeSubtitle: String { return L10n.tr("Localizable", "screen_qr_code_login_verify_code_subtitle") }
  /// Mã xác minh của bạn
  internal static var screenQrCodeLoginVerifyCodeTitle: String { return L10n.tr("Localizable", "screen_qr_code_login_verify_code_title") }
  /// Tạo khóa khôi phục mới nếu bạn đã mất khóa hiện có. Sau khi thay đổi khóa khôi phục, khóa cũ sẽ không còn hoạt động.
  internal static var screenRecoveryKeyChangeDescription: String { return L10n.tr("Localizable", "screen_recovery_key_change_description") }
  /// Tạo khóa khôi phục mới
  internal static var screenRecoveryKeyChangeGenerateKey: String { return L10n.tr("Localizable", "screen_recovery_key_change_generate_key") }
  /// Không chia sẻ điều này với bất kỳ ai!
  internal static var screenRecoveryKeyChangeGenerateKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_change_generate_key_description") }
  /// Đã thay đổi khóa khôi phục
  internal static var screenRecoveryKeyChangeSuccess: String { return L10n.tr("Localizable", "screen_recovery_key_change_success") }
  /// Thay đổi khóa khôi phục?
  internal static var screenRecoveryKeyChangeTitle: String { return L10n.tr("Localizable", "screen_recovery_key_change_title") }
  /// Tạo khóa khôi phục mới
  internal static var screenRecoveryKeyConfirmCreateNewRecoveryKey: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_create_new_recovery_key") }
  /// Đảm bảo không ai có thể thấy màn hình này!
  internal static var screenRecoveryKeyConfirmDescription: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_description") }
  /// Vui lòng thử lại để xác nhận quyền truy cập vào kho lưu trữ khóa.
  internal static var screenRecoveryKeyConfirmErrorContent: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_error_content") }
  /// Khóa khôi phục không chính xác
  internal static var screenRecoveryKeyConfirmErrorTitle: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_error_title") }
  /// Nếu bạn có khóa bảo mật hoặc cụm từ bảo mật, điều này cũng sẽ hoạt động.
  internal static var screenRecoveryKeyConfirmKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_key_description") }
  /// Nhập…
  internal static var screenRecoveryKeyConfirmKeyPlaceholder: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_key_placeholder") }
  /// Mất khóa khôi phục?
  internal static var screenRecoveryKeyConfirmLostRecoveryKey: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_lost_recovery_key") }
  /// Đã xác nhận khóa khôi phục
  internal static var screenRecoveryKeyConfirmSuccess: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_success") }
  /// Nhập khóa khôi phục
  internal static var screenRecoveryKeyConfirmTitle: String { return L10n.tr("Localizable", "screen_recovery_key_confirm_title") }
  /// Đã sao chép khóa khôi phục
  internal static var screenRecoveryKeyCopiedToClipboard: String { return L10n.tr("Localizable", "screen_recovery_key_copied_to_clipboard") }
  /// Đang tạo…
  internal static var screenRecoveryKeyGeneratingKey: String { return L10n.tr("Localizable", "screen_recovery_key_generating_key") }
  /// Lưu khóa khôi phục
  internal static var screenRecoveryKeySaveAction: String { return L10n.tr("Localizable", "screen_recovery_key_save_action") }
  /// Viết khóa khôi phục này vào nơi an toàn, như trình quản lý mật khẩu, ghi chú mã hóa hoặc két sắt vật lý.
  internal static var screenRecoveryKeySaveDescription: String { return L10n.tr("Localizable", "screen_recovery_key_save_description") }
  /// Chạm để sao chép khóa khôi phục
  internal static var screenRecoveryKeySaveKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_save_key_description") }
  /// Lưu khóa khôi phục ở nơi an toàn
  internal static var screenRecoveryKeySaveTitle: String { return L10n.tr("Localizable", "screen_recovery_key_save_title") }
  /// Bạn sẽ không thể truy cập khóa khôi phục mới sau bước này.
  internal static var screenRecoveryKeySetupConfirmationDescription: String { return L10n.tr("Localizable", "screen_recovery_key_setup_confirmation_description") }
  /// Bạn đã lưu khóa khôi phục chưa?
  internal static var screenRecoveryKeySetupConfirmationTitle: String { return L10n.tr("Localizable", "screen_recovery_key_setup_confirmation_title") }
  /// Kho lưu trữ khóa được bảo vệ bằng khóa khôi phục. Nếu cần khóa khôi phục mới sau khi thiết lập, bạn có thể tạo lại bằng cách chọn 'Thay đổi khóa khôi phục'.
  internal static var screenRecoveryKeySetupDescription: String { return L10n.tr("Localizable", "screen_recovery_key_setup_description") }
  /// Tạo khóa khôi phục
  internal static var screenRecoveryKeySetupGenerateKey: String { return L10n.tr("Localizable", "screen_recovery_key_setup_generate_key") }
  /// Không chia sẻ điều này với bất kỳ ai!
  internal static var screenRecoveryKeySetupGenerateKeyDescription: String { return L10n.tr("Localizable", "screen_recovery_key_setup_generate_key_description") }
  /// Thiết lập khôi phục thành công
  internal static var screenRecoveryKeySetupSuccess: String { return L10n.tr("Localizable", "screen_recovery_key_setup_success") }
  /// Thiết lập khôi phục
  internal static var screenRecoveryKeySetupTitle: String { return L10n.tr("Localizable", "screen_recovery_key_setup_title") }
  /// Chặn người dùng
  internal static var screenReportContentBlockUser: String { return L10n.tr("Localizable", "screen_report_content_block_user") }
  /// Đánh dấu nếu bạn muốn ẩn tất cả tin nhắn hiện tại và tương lai từ người dùng này
  internal static var screenReportContentBlockUserHint: String { return L10n.tr("Localizable", "screen_report_content_block_user_hint") }
  /// Tin nhắn này sẽ được báo cáo cho quản trị viên homeserver. Họ sẽ không thể đọc bất kỳ tin nhắn mã hóa nào.
  internal static var screenReportContentExplanation: String { return L10n.tr("Localizable", "screen_report_content_explanation") }
  /// Lý do báo cáo nội dung này
  internal static var screenReportContentHint: String { return L10n.tr("Localizable", "screen_report_content_hint") }
  /// Báo cáo của bạn đã được gửi thành công, nhưng chúng tôi gặp vấn đề khi cố gắng rời khỏi phòng. Vui lòng thử lại.
  internal static var screenReportRoomLeaveFailedAlertMessage: String { return L10n.tr("Localizable", "screen_report_room_leave_failed_alert_message") }
  /// Không thể rời phòng
  internal static var screenReportRoomLeaveFailedAlertTitle: String { return L10n.tr("Localizable", "screen_report_room_leave_failed_alert_title") }
  /// Báo cáo phòng này cho quản trị viên. Nếu tin nhắn được mã hóa, quản trị viên sẽ không thể đọc chúng.
  internal static var screenReportRoomReasonFooter: String { return L10n.tr("Localizable", "screen_report_room_reason_footer") }
  /// Mô tả lý do báo cáo…
  internal static var screenReportRoomReasonPlaceholder: String { return L10n.tr("Localizable", "screen_report_room_reason_placeholder") }
  /// Báo cáo phòng
  internal static var screenReportRoomTitle: String { return L10n.tr("Localizable", "screen_report_room_title") }
  /// Có, đặt lại ngay
  internal static var screenResetEncryptionConfirmationAlertAction: String { return L10n.tr("Localizable", "screen_reset_encryption_confirmation_alert_action") }
  /// Quá trình này không thể đảo ngược.
  internal static var screenResetEncryptionConfirmationAlertSubtitle: String { return L10n.tr("Localizable", "screen_reset_encryption_confirmation_alert_subtitle") }
  /// Bạn có chắc chắn muốn đặt lại danh tính?
  internal static var screenResetEncryptionConfirmationAlertTitle: String { return L10n.tr("Localizable", "screen_reset_encryption_confirmation_alert_title") }
  /// Đã xảy ra lỗi không xác định. Vui lòng kiểm tra mật khẩu tài khoản và thử lại.
  internal static var screenResetEncryptionPasswordError: String { return L10n.tr("Localizable", "screen_reset_encryption_password_error") }
  /// Nhập…
  internal static var screenResetEncryptionPasswordPlaceholder: String { return L10n.tr("Localizable", "screen_reset_encryption_password_placeholder") }
  /// Xác nhận rằng bạn muốn đặt lại danh tính.
  internal static var screenResetEncryptionPasswordSubtitle: String { return L10n.tr("Localizable", "screen_reset_encryption_password_subtitle") }
  /// Nhập mật khẩu tài khoản để tiếp tục
  internal static var screenResetEncryptionPasswordTitle: String { return L10n.tr("Localizable", "screen_reset_encryption_password_title") }
  /// Bạn sắp đi đến tài khoản %1$@ để đặt lại danh tính. Sau đó bạn sẽ được đưa trở lại ứng dụng.
  internal static func screenResetIdentityConfirmationSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_reset_identity_confirmation_subtitle", String(describing: p1))
  }
  /// Không thể xác nhận? Đi đến tài khoản để đặt lại danh tính.
  internal static var screenResetIdentityConfirmationTitle: String { return L10n.tr("Localizable", "screen_reset_identity_confirmation_title") }
  /// Rút xác minh và gửi
  internal static var screenResolveSendFailureChangedIdentityPrimaryButtonTitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_changed_identity_primary_button_title") }
  /// Bạn có thể rút xác minh và gửi tin nhắn này, hoặc hủy bây giờ và thử lại sau khi xác minh lại %1$@.
  internal static func screenResolveSendFailureChangedIdentitySubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_changed_identity_subtitle", String(describing: p1))
  }
  /// Tin nhắn của bạn không được gửi vì danh tính đã xác minh của %1$@ đã được đặt lại
  internal static func screenResolveSendFailureChangedIdentityTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_changed_identity_title", String(describing: p1))
  }
  /// Gửi tin nhắn
  internal static var screenResolveSendFailureUnsignedDevicePrimaryButtonTitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_unsigned_device_primary_button_title") }
  /// %1$@ đang sử dụng một hoặc nhiều thiết bị chưa xác minh. Bạn có thể gửi tin nhắn, hoặc hủy bây giờ và thử lại sau khi %2$@ đã xác minh tất cả thiết bị.
  internal static func screenResolveSendFailureUnsignedDeviceSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_unsigned_device_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Tin nhắn của bạn không được gửi vì %1$@ chưa xác minh tất cả thiết bị
  internal static func screenResolveSendFailureUnsignedDeviceTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_resolve_send_failure_unsigned_device_title", String(describing: p1))
  }
  /// Một hoặc nhiều thiết bị của bạn chưa được xác minh. Bạn có thể gửi tin nhắn, hoặc hủy bây giờ và thử lại sau khi bạn đã xác minh tất cả thiết bị.
  internal static var screenResolveSendFailureYouUnsignedDeviceSubtitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_you_unsigned_device_subtitle") }
  /// Tin nhắn của bạn không được gửi vì bạn chưa xác minh một hoặc nhiều thiết bị
  internal static var screenResolveSendFailureYouUnsignedDeviceTitle: String { return L10n.tr("Localizable", "screen_resolve_send_failure_you_unsigned_device_title") }
  /// Giải quyết bí danh phòng thất bại.
  internal static var screenRoomAliasResolverResolveAliasFailure: String { return L10n.tr("Localizable", "screen_room_alias_resolver_resolve_alias_failure") }
  /// Camera
  internal static var screenRoomAttachmentSourceCamera: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera") }
  /// Chụp ảnh
  internal static var screenRoomAttachmentSourceCameraPhoto: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera_photo") }
  /// Quay video
  internal static var screenRoomAttachmentSourceCameraVideo: String { return L10n.tr("Localizable", "screen_room_attachment_source_camera_video") }
  /// Tệp đính kèm
  internal static var screenRoomAttachmentSourceFiles: String { return L10n.tr("Localizable", "screen_room_attachment_source_files") }
  /// Thư viện ảnh & video
  internal static var screenRoomAttachmentSourceGallery: String { return L10n.tr("Localizable", "screen_room_attachment_source_gallery") }
  /// Vị trí
  internal static var screenRoomAttachmentSourceLocation: String { return L10n.tr("Localizable", "screen_room_attachment_source_location") }
  /// Bình chọn
  internal static var screenRoomAttachmentSourcePoll: String { return L10n.tr("Localizable", "screen_room_attachment_source_poll") }
  /// Định dạng văn bản
  internal static var screenRoomAttachmentTextFormatting: String { return L10n.tr("Localizable", "screen_room_attachment_text_formatting") }
  /// Chỉ quản trị viên
  internal static var screenRoomChangePermissionsAdministrators: String { return L10n.tr("Localizable", "screen_room_change_permissions_administrators") }
  /// Cấm mọi người
  internal static var screenRoomChangePermissionsBanPeople: String { return L10n.tr("Localizable", "screen_room_change_permissions_ban_people") }
  /// Xóa tin nhắn
  internal static var screenRoomChangePermissionsDeleteMessages: String { return L10n.tr("Localizable", "screen_room_change_permissions_delete_messages") }
  /// Mọi người
  internal static var screenRoomChangePermissionsEveryone: String { return L10n.tr("Localizable", "screen_room_change_permissions_everyone") }
  /// Mời mọi người và chấp nhận yêu cầu tham gia
  internal static var screenRoomChangePermissionsInvitePeople: String { return L10n.tr("Localizable", "screen_room_change_permissions_invite_people") }
  /// Kiểm duyệt thành viên
  internal static var screenRoomChangePermissionsMemberModeration: String { return L10n.tr("Localizable", "screen_room_change_permissions_member_moderation") }
  /// Tin nhắn và nội dung
  internal static var screenRoomChangePermissionsMessagesAndContent: String { return L10n.tr("Localizable", "screen_room_change_permissions_messages_and_content") }
  /// Quản trị viên và điều hành viên
  internal static var screenRoomChangePermissionsModerators: String { return L10n.tr("Localizable", "screen_room_change_permissions_moderators") }
  /// Xóa mọi người và từ chối yêu cầu tham gia
  internal static var screenRoomChangePermissionsRemovePeople: String { return L10n.tr("Localizable", "screen_room_change_permissions_remove_people") }
  /// Thay đổi avatar phòng
  internal static var screenRoomChangePermissionsRoomAvatar: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_avatar") }
  /// Chi tiết phòng
  internal static var screenRoomChangePermissionsRoomDetails: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_details") }
  /// Thay đổi tên phòng
  internal static var screenRoomChangePermissionsRoomName: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_name") }
  /// Thay đổi chủ đề phòng
  internal static var screenRoomChangePermissionsRoomTopic: String { return L10n.tr("Localizable", "screen_room_change_permissions_room_topic") }
  /// Gửi tin nhắn
  internal static var screenRoomChangePermissionsSendMessages: String { return L10n.tr("Localizable", "screen_room_change_permissions_send_messages") }
  /// Chỉnh sửa quản trị viên
  internal static var screenRoomChangeRoleAdministratorsTitle: String { return L10n.tr("Localizable", "screen_room_change_role_administrators_title") }
  /// Bạn sẽ không thể hoàn tác hành động này. Bạn đang thăng cấp người dùng lên cùng mức quyền lực với bạn.
  internal static var screenRoomChangeRoleConfirmAddAdminDescription: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_add_admin_description") }
  /// Thêm quản trị viên?
  internal static var screenRoomChangeRoleConfirmAddAdminTitle: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_add_admin_title") }
  /// Hạ cấp
  internal static var screenRoomChangeRoleConfirmDemoteSelfAction: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_demote_self_action") }
  /// Bạn sẽ không thể hoàn tác thay đổi này vì bạn đang hạ cấp chính mình, nếu bạn là người dùng có đặc quyền cuối cùng trong phòng sẽ không thể lấy lại đặc quyền.
  internal static var screenRoomChangeRoleConfirmDemoteSelfDescription: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_demote_self_description") }
  /// Hạ cấp bản thân?
  internal static var screenRoomChangeRoleConfirmDemoteSelfTitle: String { return L10n.tr("Localizable", "screen_room_change_role_confirm_demote_self_title") }
  /// %1$@ (Đang chờ)
  internal static func screenRoomChangeRoleInvitedMemberName(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_change_role_invited_member_name", String(describing: p1))
  }
  /// Quản trị viên tự động có đặc quyền điều hành viên
  internal static var screenRoomChangeRoleModeratorsAdminSectionFooter: String { return L10n.tr("Localizable", "screen_room_change_role_moderators_admin_section_footer") }
  /// Chỉnh sửa điều hành viên
  internal static var screenRoomChangeRoleModeratorsTitle: String { return L10n.tr("Localizable", "screen_room_change_role_moderators_title") }
  /// Quản trị viên
  internal static var screenRoomChangeRoleSectionAdministrators: String { return L10n.tr("Localizable", "screen_room_change_role_section_administrators") }
  /// Điều hành viên
  internal static var screenRoomChangeRoleSectionModerators: String { return L10n.tr("Localizable", "screen_room_change_role_section_moderators") }
  /// Thành viên
  internal static var screenRoomChangeRoleSectionUsers: String { return L10n.tr("Localizable", "screen_room_change_role_section_users") }
  /// Bạn có những thay đổi chưa lưu.
  internal static var screenRoomChangeRoleUnsavedChangesDescription: String { return L10n.tr("Localizable", "screen_room_change_role_unsaved_changes_description") }
  /// Lưu thay đổi?
  internal static var screenRoomChangeRoleUnsavedChangesTitle: String { return L10n.tr("Localizable", "screen_room_change_role_unsaved_changes_title") }
  /// Thêm chủ đề
  internal static var screenRoomDetailsAddTopicTitle: String { return L10n.tr("Localizable", "screen_room_details_add_topic_title") }
  /// Đã là thành viên
  internal static var screenRoomDetailsAlreadyAMember: String { return L10n.tr("Localizable", "screen_room_details_already_a_member") }
  /// Đã được mời
  internal static var screenRoomDetailsAlreadyInvited: String { return L10n.tr("Localizable", "screen_room_details_already_invited") }
  /// Đã mã hóa
  internal static var screenRoomDetailsBadgeEncrypted: String { return L10n.tr("Localizable", "screen_room_details_badge_encrypted") }
  /// Chưa mã hóa
  internal static var screenRoomDetailsBadgeNotEncrypted: String { return L10n.tr("Localizable", "screen_room_details_badge_not_encrypted") }
  /// Phòng công cộng
  internal static var screenRoomDetailsBadgePublic: String { return L10n.tr("Localizable", "screen_room_details_badge_public") }
  /// Chỉnh sửa phòng
  internal static var screenRoomDetailsEditRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_edit_room_title") }
  /// Có lỗi không xác định và thông tin không thể thay đổi.
  internal static var screenRoomDetailsEditionError: String { return L10n.tr("Localizable", "screen_room_details_edition_error") }
  /// Không thể cập nhật phòng
  internal static var screenRoomDetailsEditionErrorTitle: String { return L10n.tr("Localizable", "screen_room_details_edition_error_title") }
  /// Tin nhắn được bảo mật bằng khóa. Chỉ bạn và người nhận có khóa duy nhất để mở khóa.
  internal static var screenRoomDetailsEncryptionEnabledSubtitle: String { return L10n.tr("Localizable", "screen_room_details_encryption_enabled_subtitle") }
  /// Đã bật mã hóa tin nhắn
  internal static var screenRoomDetailsEncryptionEnabledTitle: String { return L10n.tr("Localizable", "screen_room_details_encryption_enabled_title") }
  /// Đã xảy ra lỗi khi tải cài đặt thông báo.
  internal static var screenRoomDetailsErrorLoadingNotificationSettings: String { return L10n.tr("Localizable", "screen_room_details_error_loading_notification_settings") }
  /// Tắt tiếng phòng này thất bại, vui lòng thử lại.
  internal static var screenRoomDetailsErrorMuting: String { return L10n.tr("Localizable", "screen_room_details_error_muting") }
  /// Bật tiếng phòng này thất bại, vui lòng thử lại.
  internal static var screenRoomDetailsErrorUnmuting: String { return L10n.tr("Localizable", "screen_room_details_error_unmuting") }
  /// Mời mọi người
  internal static var screenRoomDetailsInvitePeopleTitle: String { return L10n.tr("Localizable", "screen_room_details_invite_people_title") }
  /// Rời cuộc trò chuyện
  internal static var screenRoomDetailsLeaveConversationTitle: String { return L10n.tr("Localizable", "screen_room_details_leave_conversation_title") }
  /// Rời phòng
  internal static var screenRoomDetailsLeaveRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_leave_room_title") }
  /// Media và tệp
  internal static var screenRoomDetailsMediaGalleryTitle: String { return L10n.tr("Localizable", "screen_room_details_media_gallery_title") }
  /// Tùy chỉnh
  internal static var screenRoomDetailsNotificationModeCustom: String { return L10n.tr("Localizable", "screen_room_details_notification_mode_custom") }
  /// Mặc định
  internal static var screenRoomDetailsNotificationModeDefault: String { return L10n.tr("Localizable", "screen_room_details_notification_mode_default") }
  /// Thông báo
  internal static var screenRoomDetailsNotificationTitle: String { return L10n.tr("Localizable", "screen_room_details_notification_title") }
  /// Tin nhắn đã ghim
  internal static var screenRoomDetailsPinnedEventsRowTitle: String { return L10n.tr("Localizable", "screen_room_details_pinned_events_row_title") }
  /// Hồ sơ
  internal static var screenRoomDetailsProfileRowTitle: String { return L10n.tr("Localizable", "screen_room_details_profile_row_title") }
  /// Yêu cầu tham gia
  internal static var screenRoomDetailsRequestsToJoinTitle: String { return L10n.tr("Localizable", "screen_room_details_requests_to_join_title") }
  /// Vai trò và quyền hạn
  internal static var screenRoomDetailsRolesAndPermissions: String { return L10n.tr("Localizable", "screen_room_details_roles_and_permissions") }
  /// Tên phòng
  internal static var screenRoomDetailsRoomNameLabel: String { return L10n.tr("Localizable", "screen_room_details_room_name_label") }
  /// Bảo mật & riêng tư
  internal static var screenRoomDetailsSecurityAndPrivacyTitle: String { return L10n.tr("Localizable", "screen_room_details_security_and_privacy_title") }
  /// Bảo mật
  internal static var screenRoomDetailsSecurityTitle: String { return L10n.tr("Localizable", "screen_room_details_security_title") }
  /// Chia sẻ phòng
  internal static var screenRoomDetailsShareRoomTitle: String { return L10n.tr("Localizable", "screen_room_details_share_room_title") }
  /// Thông tin phòng
  internal static var screenRoomDetailsTitle: String { return L10n.tr("Localizable", "screen_room_details_title") }
  /// Chủ đề
  internal static var screenRoomDetailsTopicTitle: String { return L10n.tr("Localizable", "screen_room_details_topic_title") }
  /// Đang cập nhật phòng…
  internal static var screenRoomDetailsUpdatingRoom: String { return L10n.tr("Localizable", "screen_room_details_updating_room") }
  /// Tải thất bại
  internal static var screenRoomDirectorySearchLoadingError: String { return L10n.tr("Localizable", "screen_room_directory_search_loading_error") }
  /// Thư mục phòng
  internal static var screenRoomDirectorySearchTitle: String { return L10n.tr("Localizable", "screen_room_directory_search_title") }
  /// Lịch sử tin nhắn hiện không khả dụng.
  internal static var screenRoomEncryptedHistoryBanner: String { return L10n.tr("Localizable", "screen_room_encrypted_history_banner") }
  /// Lịch sử tin nhắn không khả dụng trong phòng này. Xác minh thiết bị này để xem lịch sử tin nhắn.
  internal static var screenRoomEncryptedHistoryBannerUnverified: String { return L10n.tr("Localizable", "screen_room_encrypted_history_banner_unverified") }
  /// Xử lý media để tải lên thất bại, vui lòng thử lại.
  internal static var screenRoomErrorFailedProcessingMedia: String { return L10n.tr("Localizable", "screen_room_error_failed_processing_media") }
  /// Không thể lấy chi tiết người dùng
  internal static var screenRoomErrorFailedRetrievingUserDetails: String { return L10n.tr("Localizable", "screen_room_error_failed_retrieving_user_details") }
  /// Tin nhắn trong %1$@
  internal static func screenRoomEventPill(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_event_pill", String(describing: p1))
  }
  /// Mở rộng
  internal static var screenRoomGroupedStateEventsExpand: String { return L10n.tr("Localizable", "screen_room_grouped_state_events_expand") }
  /// Thu gọn
  internal static var screenRoomGroupedStateEventsReduce: String { return L10n.tr("Localizable", "screen_room_grouped_state_events_reduce") }
  /// Bạn có muốn mời họ trở lại?
  internal static var screenRoomInviteAgainAlertMessage: String { return L10n.tr("Localizable", "screen_room_invite_again_alert_message") }
  /// Bạn đang một mình trong cuộc trò chuyện này
  internal static var screenRoomInviteAgainAlertTitle: String { return L10n.tr("Localizable", "screen_room_invite_again_alert_title") }
  /// Chặn
  internal static var screenRoomMemberDetailsBlockAlertAction: String { return L10n.tr("Localizable", "screen_room_member_details_block_alert_action") }
  /// Người dùng bị chặn sẽ không thể gửi tin nhắn cho bạn và tất cả tin nhắn của họ sẽ bị ẩn. Bạn có thể bỏ chặn họ bất cứ lúc nào.
  internal static var screenRoomMemberDetailsBlockAlertDescription: String { return L10n.tr("Localizable", "screen_room_member_details_block_alert_description") }
  /// Chặn người dùng
  internal static var screenRoomMemberDetailsBlockUser: String { return L10n.tr("Localizable", "screen_room_member_details_block_user") }
  /// Hồ sơ
  internal static var screenRoomMemberDetailsTitle: String { return L10n.tr("Localizable", "screen_room_member_details_title") }
  /// Bỏ chặn
  internal static var screenRoomMemberDetailsUnblockAlertAction: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_alert_action") }
  /// Bạn sẽ có thể thấy lại tất cả tin nhắn từ họ.
  internal static var screenRoomMemberDetailsUnblockAlertDescription: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_alert_description") }
  /// Bỏ chặn người dùng
  internal static var screenRoomMemberDetailsUnblockUser: String { return L10n.tr("Localizable", "screen_room_member_details_unblock_user") }
  /// Sử dụng ứng dụng web để xác minh người dùng này.
  internal static var screenRoomMemberDetailsVerifyButtonSubtitle: String { return L10n.tr("Localizable", "screen_room_member_details_verify_button_subtitle") }
  /// Xác minh %1$@
  internal static func screenRoomMemberDetailsVerifyButtonTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_member_details_verify_button_title", String(describing: p1))
  }
  /// Không có người dùng bị cấm trong phòng này.
  internal static var screenRoomMemberListBannedEmpty: String { return L10n.tr("Localizable", "screen_room_member_list_banned_empty") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomMemberListHeaderTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_header_title", p1)
  }
  /// Cấm khỏi phòng
  internal static var screenRoomMemberListManageMemberRemoveConfirmationBan: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_remove_confirmation_ban") }
  /// Chỉ xóa thành viên
  internal static var screenRoomMemberListManageMemberRemoveConfirmationKick: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_remove_confirmation_kick") }
  /// Bỏ cấm
  internal static var screenRoomMemberListManageMemberUnbanAction: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_unban_action") }
  /// Họ sẽ có thể tham gia phòng này lại nếu được mời.
  internal static var screenRoomMemberListManageMemberUnbanMessage: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_unban_message") }
  /// Bỏ cấm người dùng
  internal static var screenRoomMemberListManageMemberUnbanTitle: String { return L10n.tr("Localizable", "screen_room_member_list_manage_member_unban_title") }
  /// Bị cấm
  internal static var screenRoomMemberListModeBanned: String { return L10n.tr("Localizable", "screen_room_member_list_mode_banned") }
  /// Thành viên
  internal static var screenRoomMemberListModeMembers: String { return L10n.tr("Localizable", "screen_room_member_list_mode_members") }
  /// Đang chờ
  internal static var screenRoomMemberListPendingHeaderTitle: String { return L10n.tr("Localizable", "screen_room_member_list_pending_header_title") }
  /// Quản trị viên
  internal static var screenRoomMemberListRoleAdministrator: String { return L10n.tr("Localizable", "screen_room_member_list_role_administrator") }
  /// Điều hành viên
  internal static var screenRoomMemberListRoleModerator: String { return L10n.tr("Localizable", "screen_room_member_list_role_moderator") }
  /// Chủ sở hữu
  internal static var screenRoomMemberListRoleOwner: String { return L10n.tr("Localizable", "screen_room_member_list_role_owner") }
  /// Thành viên phòng
  internal static var screenRoomMemberListRoomMembersHeaderTitle: String { return L10n.tr("Localizable", "screen_room_member_list_room_members_header_title") }
  /// Đang bỏ cấm %1$@
  internal static func screenRoomMemberListUnbanningUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_member_list_unbanning_user", String(describing: p1))
  }
  /// Thông báo toàn bộ phòng
  internal static var screenRoomMentionsAtRoomSubtitle: String { return L10n.tr("Localizable", "screen_room_mentions_at_room_subtitle") }
  /// Mọi người
  internal static var screenRoomMentionsAtRoomTitle: String { return L10n.tr("Localizable", "screen_room_mentions_at_room_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomMultipleKnockRequestsTitle(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_multiple_knock_requests_title", p1)
  }
  /// Xem tất cả
  internal static var screenRoomMultipleKnockRequestsViewAllButtonTitle: String { return L10n.tr("Localizable", "screen_room_multiple_knock_requests_view_all_button_title") }
  /// Cho phép cài đặt tùy chỉnh
  internal static var screenRoomNotificationSettingsAllowCustom: String { return L10n.tr("Localizable", "screen_room_notification_settings_allow_custom") }
  /// Bật tính năng này sẽ ghi đè cài đặt mặc định
  internal static var screenRoomNotificationSettingsAllowCustomFootnote: String { return L10n.tr("Localizable", "screen_room_notification_settings_allow_custom_footnote") }
  /// Thông báo cho tôi trong cuộc trò chuyện này khi có
  internal static var screenRoomNotificationSettingsCustomSettingsTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_custom_settings_title") }
  /// Bạn có thể thay đổi trong %1$@.
  internal static func screenRoomNotificationSettingsDefaultSettingFootnote(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_footnote", String(describing: p1))
  }
  /// cài đặt toàn cục
  internal static var screenRoomNotificationSettingsDefaultSettingFootnoteContentLink: String { return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_footnote_content_link") }
  /// Cài đặt mặc định
  internal static var screenRoomNotificationSettingsDefaultSettingTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_default_setting_title") }
  /// Xóa cài đặt tùy chỉnh
  internal static var screenRoomNotificationSettingsEditRemoveSetting: String { return L10n.tr("Localizable", "screen_room_notification_settings_edit_remove_setting") }
  /// Đã xảy ra lỗi khi tải cài đặt thông báo.
  internal static var screenRoomNotificationSettingsErrorLoadingSettings: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_loading_settings") }
  /// Khôi phục chế độ mặc định thất bại, vui lòng thử lại.
  internal static var screenRoomNotificationSettingsErrorRestoringDefault: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_restoring_default") }
  /// Đặt chế độ thất bại, vui lòng thử lại.
  internal static var screenRoomNotificationSettingsErrorSettingMode: String { return L10n.tr("Localizable", "screen_room_notification_settings_error_setting_mode") }
  /// Homeserver của bạn không hỗ trợ tùy chọn này trong phòng mã hóa, bạn sẽ không được thông báo trong phòng này.
  internal static var screenRoomNotificationSettingsMentionsOnlyDisclaimer: String { return L10n.tr("Localizable", "screen_room_notification_settings_mentions_only_disclaimer") }
  /// Tất cả tin nhắn
  internal static var screenRoomNotificationSettingsModeAllMessages: String { return L10n.tr("Localizable", "screen_room_notification_settings_mode_all_messages") }
  /// Chỉ nhắc đến và từ khóa
  internal static var screenRoomNotificationSettingsModeMentionsAndKeywords: String { return L10n.tr("Localizable", "screen_room_notification_settings_mode_mentions_and_keywords") }
  /// Trong phòng này, thông báo cho tôi khi có
  internal static var screenRoomNotificationSettingsRoomCustomSettingsTitle: String { return L10n.tr("Localizable", "screen_room_notification_settings_room_custom_settings_title") }
  /// %1$@ trong %2$@
  internal static func screenRoomPinnedBannerIndicator(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_room_pinned_banner_indicator", String(describing: p1), String(describing: p2))
  }
  /// %1$@ Tin nhắn đã ghim
  internal static func screenRoomPinnedBannerIndicatorDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_pinned_banner_indicator_description", String(describing: p1))
  }
  /// Đang tải tin nhắn…
  internal static var screenRoomPinnedBannerLoadingDescription: String { return L10n.tr("Localizable", "screen_room_pinned_banner_loading_description") }
  /// Xem tất cả
  internal static var screenRoomPinnedBannerViewAllButtonTitle: String { return L10n.tr("Localizable", "screen_room_pinned_banner_view_all_button_title") }
  /// Gửi lại
  internal static var screenRoomRetrySendMenuSendAgainAction: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_send_again_action") }
  /// Tin nhắn của bạn gửi thất bại
  internal static var screenRoomRetrySendMenuTitle: String { return L10n.tr("Localizable", "screen_room_retry_send_menu_title") }
  /// Quản trị viên
  internal static var screenRoomRolesAndPermissionsAdmins: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_admins") }
  /// Thay đổi vai trò của tôi
  internal static var screenRoomRolesAndPermissionsChangeMyRole: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_change_my_role") }
  /// Hạ cấp xuống thành viên
  internal static var screenRoomRolesAndPermissionsChangeRoleDemoteToMember: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_change_role_demote_to_member") }
  /// Hạ cấp xuống điều hành viên
  internal static var screenRoomRolesAndPermissionsChangeRoleDemoteToModerator: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_change_role_demote_to_moderator") }
  /// Kiểm duyệt thành viên
  internal static var screenRoomRolesAndPermissionsMemberModeration: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_member_moderation") }
  /// Tin nhắn và nội dung
  internal static var screenRoomRolesAndPermissionsMessagesAndContent: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_messages_and_content") }
  /// Điều hành viên
  internal static var screenRoomRolesAndPermissionsModerators: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_moderators") }
  /// Quyền hạn
  internal static var screenRoomRolesAndPermissionsPermissionsHeader: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_permissions_header") }
  /// Đặt lại quyền hạn
  internal static var screenRoomRolesAndPermissionsReset: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_reset") }
  /// Khi bạn đặt lại quyền hạn, bạn sẽ mất cài đặt hiện tại.
  internal static var screenRoomRolesAndPermissionsResetConfirmDescription: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_reset_confirm_description") }
  /// Đặt lại quyền hạn?
  internal static var screenRoomRolesAndPermissionsResetConfirmTitle: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_reset_confirm_title") }
  /// Vai trò
  internal static var screenRoomRolesAndPermissionsRolesHeader: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_roles_header") }
  /// Chi tiết phòng
  internal static var screenRoomRolesAndPermissionsRoomDetails: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_room_details") }
  /// Vai trò và quyền hạn
  internal static var screenRoomRolesAndPermissionsTitle: String { return L10n.tr("Localizable", "screen_room_roles_and_permissions_title") }
  /// Chấp nhận
  internal static var screenRoomSingleKnockRequestAcceptButtonTitle: String { return L10n.tr("Localizable", "screen_room_single_knock_request_accept_button_title") }
  /// %1$@ muốn tham gia phòng này
  internal static func screenRoomSingleKnockRequestTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_single_knock_request_title", String(describing: p1))
  }
  /// Xem
  internal static var screenRoomSingleKnockRequestViewButtonTitle: String { return L10n.tr("Localizable", "screen_room_single_knock_request_view_button_title") }
  /// Thêm phản ứng
  internal static var screenRoomTimelineAddReaction: String { return L10n.tr("Localizable", "screen_room_timeline_add_reaction") }
  /// Đây là khởi đầu của %1$@.
  internal static func screenRoomTimelineBeginningOfRoom(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_beginning_of_room", String(describing: p1))
  }
  /// Đây là khởi đầu của cuộc trò chuyện này.
  internal static var screenRoomTimelineBeginningOfRoomNoName: String { return L10n.tr("Localizable", "screen_room_timeline_beginning_of_room_no_name") }
  /// Cuộc gọi không được hỗ trợ. Hỏi người gọi xem có thể sử dụng ứng dụng Element X mới không.
  internal static var screenRoomTimelineLegacyCall: String { return L10n.tr("Localizable", "screen_room_timeline_legacy_call") }
  /// Hiển thị ít hơn
  internal static var screenRoomTimelineLessReactions: String { return L10n.tr("Localizable", "screen_room_timeline_less_reactions") }
  /// Đã sao chép tin nhắn
  internal static var screenRoomTimelineMessageCopied: String { return L10n.tr("Localizable", "screen_room_timeline_message_copied") }
  /// Bạn không có quyền đăng trong phòng này
  internal static var screenRoomTimelineNoPermissionToPost: String { return L10n.tr("Localizable", "screen_room_timeline_no_permission_to_post") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTimelineReactionA11y(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_reaction_a11y", p1)
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTimelineReactionIncludingYouA11y(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_reaction_including_you_a11y", p1)
  }
  /// Bạn đã phản ứng bằng %1$@
  internal static func screenRoomTimelineReactionYouA11y(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_reaction_you_a11y", String(describing: p1))
  }
  /// Hiển thị ít hơn
  internal static var screenRoomTimelineReactionsShowLess: String { return L10n.tr("Localizable", "screen_room_timeline_reactions_show_less") }
  /// Hiển thị thêm
  internal static var screenRoomTimelineReactionsShowMore: String { return L10n.tr("Localizable", "screen_room_timeline_reactions_show_more") }
  /// Hiển thị tóm tắt phản ứng
  internal static var screenRoomTimelineReactionsShowReactionsSummary: String { return L10n.tr("Localizable", "screen_room_timeline_reactions_show_reactions_summary") }
  /// Mới
  internal static var screenRoomTimelineReadMarkerTitle: String { return L10n.tr("Localizable", "screen_room_timeline_read_marker_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTimelineStateChanges(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_timeline_state_changes", p1)
  }
  /// Chuyển đến phòng mới
  internal static var screenRoomTimelineTombstonedRoomAction: String { return L10n.tr("Localizable", "screen_room_timeline_tombstoned_room_action") }
  /// Phòng này đã được thay thế và không còn hoạt động
  internal static var screenRoomTimelineTombstonedRoomMessage: String { return L10n.tr("Localizable", "screen_room_timeline_tombstoned_room_message") }
  /// Xem tin nhắn cũ
  internal static var screenRoomTimelineUpgradedRoomAction: String { return L10n.tr("Localizable", "screen_room_timeline_upgraded_room_action") }
  /// Phòng này là sự tiếp nối của phòng khác
  internal static var screenRoomTimelineUpgradedRoomMessage: String { return L10n.tr("Localizable", "screen_room_timeline_upgraded_room_message") }
  /// Trò chuyện
  internal static var screenRoomTitle: String { return L10n.tr("Localizable", "screen_room_title") }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTypingManyMembers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_typing_many_members", p1)
  }
  /// %1$@, %2$@ và 
  internal static func screenRoomTypingManyMembersFirstComponentIos(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_room_typing_many_members_first_component_ios", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@COUNT@"
  internal static func screenRoomTypingNotification(_ p1: Int) -> String {
    return L10n.tr("Localizable", "screen_room_typing_notification", p1)
  }
  ///  đang gõ…
  internal static var screenRoomTypingNotificationPluralIos: String { return L10n.tr("Localizable", "screen_room_typing_notification_plural_ios") }
  ///  đang gõ…
  internal static var screenRoomTypingNotificationSingularIos: String { return L10n.tr("Localizable", "screen_room_typing_notification_singular_ios") }
  /// %1$@ và %2$@
  internal static func screenRoomTypingTwoMembers(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "screen_room_typing_two_members", String(describing: p1), String(describing: p2))
  }
  /// Giữ để ghi âm
  internal static var screenRoomVoiceMessageTooltip: String { return L10n.tr("Localizable", "screen_room_voice_message_tooltip") }
  /// Tạo cuộc trò chuyện hoặc phòng mới
  internal static var screenRoomlistA11yCreateMessage: String { return L10n.tr("Localizable", "screen_roomlist_a11y_create_message") }
  /// Xóa bộ lọc
  internal static var screenRoomlistClearFilters: String { return L10n.tr("Localizable", "screen_roomlist_clear_filters") }
  /// Bắt đầu bằng cách nhắn tin với ai đó.
  internal static var screenRoomlistEmptyMessage: String { return L10n.tr("Localizable", "screen_roomlist_empty_message") }
  /// Chưa có cuộc trò chuyện.
  internal static var screenRoomlistEmptyTitle: String { return L10n.tr("Localizable", "screen_roomlist_empty_title") }
  /// Yêu thích
  internal static var screenRoomlistFilterFavourites: String { return L10n.tr("Localizable", "screen_roomlist_filter_favourites") }
  /// Bạn có thể thêm cuộc trò chuyện vào mục yêu thích trong cài đặt trò chuyện.
  /// Bây giờ, bạn có thể bỏ chọn bộ lọc để xem các cuộc trò chuyện khác
  internal static var screenRoomlistFilterFavouritesEmptyStateSubtitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_favourites_empty_state_subtitle") }
  /// Bạn chưa có cuộc trò chuyện yêu thích
  internal static var screenRoomlistFilterFavouritesEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_favourites_empty_state_title") }
  /// Lời mời
  internal static var screenRoomlistFilterInvites: String { return L10n.tr("Localizable", "screen_roomlist_filter_invites") }
  /// Bạn không có lời mời đang chờ.
  internal static var screenRoomlistFilterInvitesEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_invites_empty_state_title") }
  /// Mức độ ưu tiên thấp
  internal static var screenRoomlistFilterLowPriority: String { return L10n.tr("Localizable", "screen_roomlist_filter_low_priority") }
  /// Bạn có thể bỏ chọn bộ lọc để xem các cuộc trò chuyện khác
  internal static var screenRoomlistFilterMixedEmptyStateSubtitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_mixed_empty_state_subtitle") }
  /// Bạn không có cuộc trò chuyện cho lựa chọn này
  internal static var screenRoomlistFilterMixedEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_mixed_empty_state_title") }
  /// Mọi người
  internal static var screenRoomlistFilterPeople: String { return L10n.tr("Localizable", "screen_roomlist_filter_people") }
  /// Bạn chưa có tin nhắn trực tiếp nào
  internal static var screenRoomlistFilterPeopleEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_people_empty_state_title") }
  /// Phòng
  internal static var screenRoomlistFilterRooms: String { return L10n.tr("Localizable", "screen_roomlist_filter_rooms") }
  /// Bạn chưa ở trong phòng nào
  internal static var screenRoomlistFilterRoomsEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_rooms_empty_state_title") }
  /// Chưa đọc
  internal static var screenRoomlistFilterUnreads: String { return L10n.tr("Localizable", "screen_roomlist_filter_unreads") }
  /// Chúc mừng!
  /// Bạn không có tin nhắn chưa đọc!
  internal static var screenRoomlistFilterUnreadsEmptyStateTitle: String { return L10n.tr("Localizable", "screen_roomlist_filter_unreads_empty_state_title") }
  /// Yêu cầu tham gia đã gửi
  internal static var screenRoomlistKnockEventSentDescription: String { return L10n.tr("Localizable", "screen_roomlist_knock_event_sent_description") }
  /// Cuộc trò chuyện
  internal static var screenRoomlistMainSpaceTitle: String { return L10n.tr("Localizable", "screen_roomlist_main_space_title") }
  /// Đánh dấu đã đọc
  internal static var screenRoomlistMarkAsRead: String { return L10n.tr("Localizable", "screen_roomlist_mark_as_read") }
  /// Đánh dấu chưa đọc
  internal static var screenRoomlistMarkAsUnread: String { return L10n.tr("Localizable", "screen_roomlist_mark_as_unread") }
  /// Phòng này đã được nâng cấp
  internal static var screenRoomlistTombstonedRoomDescription: String { return L10n.tr("Localizable", "screen_roomlist_tombstoned_room_description") }
  /// Không tìm thấy kết quả
  internal static var screenSearchNoResults: String { return L10n.tr("Localizable", "screen_search_no_results") }
  /// Thử tìm kiếm với từ khóa khác
  internal static var screenSearchNoResultsDescription: String { return L10n.tr("Localizable", "screen_search_no_results_description") }
  /// Tìm kiếm tin nhắn
  internal static var screenSearchPlaceholder: String { return L10n.tr("Localizable", "screen_search_placeholder") }
  /// Nhập từ khóa để tìm kiếm tin nhắn trong phòng này
  internal static var screenSearchPlaceholderDescription: String { return L10n.tr("Localizable", "screen_search_placeholder_description") }
  /// Đang tìm kiếm tin nhắn...
  internal static var screenSearchSearchingMessages: String { return L10n.tr("Localizable", "screen_search_searching_messages") }
  /// Thêm địa chỉ phòng
  internal static var screenSecurityAndPrivacyAddRoomAddressAction: String { return L10n.tr("Localizable", "screen_security_and_privacy_add_room_address_action") }
  /// Bất kỳ ai cũng có thể xin tham gia phòng nhưng quản trị viên hoặc điều hành viên sẽ phải chấp nhận yêu cầu.
  internal static var screenSecurityAndPrivacyAskToJoinOptionDescription: String { return L10n.tr("Localizable", "screen_security_and_privacy_ask_to_join_option_description") }
  /// Xin tham gia
  internal static var screenSecurityAndPrivacyAskToJoinOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_ask_to_join_option_title") }
  /// Có, bật mã hóa
  internal static var screenSecurityAndPrivacyEnableEncryptionAlertConfirmButtonTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_enable_encryption_alert_confirm_button_title") }
  /// Khi đã bật, mã hóa cho phòng không thể tắt. Lịch sử tin nhắn sẽ chỉ hiển thị cho thành viên phòng kể từ khi họ được mời hoặc kể từ khi họ tham gia phòng.
  /// Không ai ngoài thành viên phòng có thể đọc tin nhắn. Điều này có thể ngăn bot và cầu nối hoạt động đúng cách.
  /// Chúng tôi không khuyến nghị bật mã hóa cho phòng mà bất kỳ ai cũng có thể tìm thấy và tham gia.
  internal static var screenSecurityAndPrivacyEnableEncryptionAlertDescription: String { return L10n.tr("Localizable", "screen_security_and_privacy_enable_encryption_alert_description") }
  /// Bật mã hóa?
  internal static var screenSecurityAndPrivacyEnableEncryptionAlertTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_enable_encryption_alert_title") }
  /// Khi đã bật, mã hóa không thể tắt.
  internal static var screenSecurityAndPrivacyEncryptionSectionFooter: String { return L10n.tr("Localizable", "screen_security_and_privacy_encryption_section_footer") }
  /// Mã hóa
  internal static var screenSecurityAndPrivacyEncryptionSectionHeader: String { return L10n.tr("Localizable", "screen_security_and_privacy_encryption_section_header") }
  /// Bật mã hóa đầu cuối
  internal static var screenSecurityAndPrivacyEncryptionToggleTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_encryption_toggle_title") }
  /// Bất kỳ ai cũng có thể tìm thấy và tham gia
  internal static var screenSecurityAndPrivacyRoomAccessAnyoneOptionDescription: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_anyone_option_description") }
  /// Bất kỳ ai
  internal static var screenSecurityAndPrivacyRoomAccessAnyoneOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_anyone_option_title") }
  /// Mọi người chỉ có thể tham gia nếu được mời
  internal static var screenSecurityAndPrivacyRoomAccessInviteOnlyOptionDescription: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_invite_only_option_description") }
  /// Chỉ mời
  internal static var screenSecurityAndPrivacyRoomAccessInviteOnlyOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_invite_only_option_title") }
  /// Quyền truy cập phòng
  internal static var screenSecurityAndPrivacyRoomAccessSectionHeader: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_section_header") }
  /// Không gian hiện không được hỗ trợ
  internal static var screenSecurityAndPrivacyRoomAccessSpaceMembersOptionDescription: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_space_members_option_description") }
  /// Thành viên không gian
  internal static var screenSecurityAndPrivacyRoomAccessSpaceMembersOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_access_space_members_option_title") }
  /// Bạn sẽ cần một địa chỉ phòng để làm cho nó hiển thị trong thư mục phòng.
  internal static var screenSecurityAndPrivacyRoomAddressSectionFooter: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_address_section_footer") }
  /// Địa chỉ phòng
  internal static var screenSecurityAndPrivacyRoomAddressSectionHeader: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_address_section_header") }
  /// Cho phép phòng này được tìm thấy bằng cách tìm kiếm thư mục phòng công cộng %1$@
  internal static func screenSecurityAndPrivacyRoomDirectoryVisibilitySectionFooter(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_security_and_privacy_room_directory_visibility_section_footer", String(describing: p1))
  }
  /// Hiển thị trong thư mục phòng công cộng
  internal static var screenSecurityAndPrivacyRoomDirectoryVisibilityToggleTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_directory_visibility_toggle_title") }
  /// Bất kỳ ai
  internal static var screenSecurityAndPrivacyRoomHistoryAnyoneOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_history_anyone_option_title") }
  /// Ai có thể đọc lịch sử
  internal static var screenSecurityAndPrivacyRoomHistorySectionHeader: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_history_section_header") }
  /// Chỉ thành viên kể từ khi được mời
  internal static var screenSecurityAndPrivacyRoomHistorySinceInviteOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_history_since_invite_option_title") }
  /// Chỉ thành viên kể từ khi chọn tùy chọn này
  internal static var screenSecurityAndPrivacyRoomHistorySinceSelectingOptionTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_history_since_selecting_option_title") }
  /// Địa chỉ phòng là cách để tìm và truy cập phòng. Điều này cũng đảm bảo bạn có thể dễ dàng chia sẻ phòng với người khác.
  /// Bạn có thể chọn xuất bản phòng trong thư mục phòng công cộng của homeserver.
  internal static var screenSecurityAndPrivacyRoomPublishingSectionFooter: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_publishing_section_footer") }
  /// Xuất bản phòng
  internal static var screenSecurityAndPrivacyRoomPublishingSectionHeader: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_publishing_section_header") }
  /// Địa chỉ phòng là cách để tìm và truy cập phòng. Điều này cũng đảm bảo bạn có thể dễ dàng chia sẻ phòng với người khác.
  /// Địa chỉ cũng cần thiết để làm cho phòng hiển thị trong thư mục phòng công cộng %1$@.
  internal static func screenSecurityAndPrivacyRoomVisibilitySectionFooter(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_security_and_privacy_room_visibility_section_footer", String(describing: p1))
  }
  /// Khả năng hiển thị phòng
  internal static var screenSecurityAndPrivacyRoomVisibilitySectionHeader: String { return L10n.tr("Localizable", "screen_security_and_privacy_room_visibility_section_header") }
  /// Bảo mật & riêng tư
  internal static var screenSecurityAndPrivacyTitle: String { return L10n.tr("Localizable", "screen_security_and_privacy_title") }
  /// Thay đổi nhà cung cấp tài khoản
  internal static var screenServerConfirmationChangeServer: String { return L10n.tr("Localizable", "screen_server_confirmation_change_server") }
  /// Máy chủ riêng cho nhân viên Element.
  internal static var screenServerConfirmationMessageLoginElementDotIo: String { return L10n.tr("Localizable", "screen_server_confirmation_message_login_element_dot_io") }
  /// Matrix là mạng mở cho giao tiếp bảo mật, phi tập trung.
  internal static var screenServerConfirmationMessageLoginMatrixDotOrg: String { return L10n.tr("Localizable", "screen_server_confirmation_message_login_matrix_dot_org") }
  /// Đây là nơi các cuộc trò chuyện sẽ diễn ra — giống như bạn sử dụng nhà cung cấp email để giữ email.
  internal static var screenServerConfirmationMessageRegister: String { return L10n.tr("Localizable", "screen_server_confirmation_message_register") }
  /// Bạn sắp đăng nhập vào %1$@
  internal static func screenServerConfirmationTitleLogin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_server_confirmation_title_login", String(describing: p1))
  }
  /// Chọn nhà cung cấp tài khoản
  internal static var screenServerConfirmationTitlePickerMode: String { return L10n.tr("Localizable", "screen_server_confirmation_title_picker_mode") }
  /// Bạn sắp tạo tài khoản trên %1$@
  internal static func screenServerConfirmationTitleRegister(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_server_confirmation_title_register", String(describing: p1))
  }
  /// Có gì đó không đúng. Yêu cầu đã hết thời gian hoặc bị từ chối.
  internal static var screenSessionVerificationCancelledSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_cancelled_subtitle") }
  /// Xác nhận rằng các emoji bên dưới khớp với những emoji hiển thị trên phiên khác.
  internal static var screenSessionVerificationCompareEmojisSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_subtitle") }
  /// So sánh emoji
  internal static var screenSessionVerificationCompareEmojisTitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_title") }
  /// Xác nhận rằng các emoji bên dưới khớp với những emoji hiển thị trên thiết bị của người dùng khác.
  internal static var screenSessionVerificationCompareEmojisUserSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_emojis_user_subtitle") }
  /// Xác nhận rằng các số bên dưới khớp với những số hiển thị trên phiên khác.
  internal static var screenSessionVerificationCompareNumbersSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_numbers_subtitle") }
  /// So sánh số
  internal static var screenSessionVerificationCompareNumbersTitle: String { return L10n.tr("Localizable", "screen_session_verification_compare_numbers_title") }
  /// Phiên mới của bạn đã được xác minh. Nó có quyền truy cập vào tin nhắn mã hóa và người dùng khác sẽ thấy nó đáng tin cậy.
  internal static var screenSessionVerificationCompleteSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_complete_subtitle") }
  /// Giờ bạn có thể tin tưởng danh tính của người dùng này khi gửi hoặc nhận tin nhắn.
  internal static var screenSessionVerificationCompleteUserSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_complete_user_subtitle") }
  /// Nhập khóa khôi phục
  internal static var screenSessionVerificationEnterRecoveryKey: String { return L10n.tr("Localizable", "screen_session_verification_enter_recovery_key") }
  /// Yêu cầu đã hết thời gian, bị từ chối hoặc có sự không khớp trong xác minh.
  internal static var screenSessionVerificationFailedSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_failed_subtitle") }
  /// Chứng minh đó là bạn để truy cập lịch sử tin nhắn mã hóa.
  internal static var screenSessionVerificationOpenExistingSessionSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_open_existing_session_subtitle") }
  /// Mở phiên hiện có
  internal static var screenSessionVerificationOpenExistingSessionTitle: String { return L10n.tr("Localizable", "screen_session_verification_open_existing_session_title") }
  /// Thử lại xác minh
  internal static var screenSessionVerificationPositiveButtonCanceled: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_canceled") }
  /// Tôi đã sẵn sàng
  internal static var screenSessionVerificationPositiveButtonInitial: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_initial") }
  /// Đang chờ khớp…
  internal static var screenSessionVerificationPositiveButtonVerifyingOngoing: String { return L10n.tr("Localizable", "screen_session_verification_positive_button_verifying_ongoing") }
  /// So sánh bộ emoji duy nhất.
  internal static var screenSessionVerificationReadySubtitle: String { return L10n.tr("Localizable", "screen_session_verification_ready_subtitle") }
  /// So sánh emoji duy nhất, đảm bảo chúng xuất hiện theo cùng thứ tự.
  internal static var screenSessionVerificationRequestAcceptedSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_request_accepted_subtitle") }
  /// Đã đăng nhập
  internal static var screenSessionVerificationRequestDetailsTimestamp: String { return L10n.tr("Localizable", "screen_session_verification_request_details_timestamp") }
  /// Yêu cầu đã hết thời gian, bị từ chối hoặc có sự không khớp trong xác minh.
  internal static var screenSessionVerificationRequestFailureSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_request_failure_subtitle") }
  /// Xác minh thất bại
  internal static var screenSessionVerificationRequestFailureTitle: String { return L10n.tr("Localizable", "screen_session_verification_request_failure_title") }
  /// Chỉ tiếp tục nếu bạn đã khởi tạo xác minh này.
  internal static var screenSessionVerificationRequestFooter: String { return L10n.tr("Localizable", "screen_session_verification_request_footer") }
  /// Xác minh thiết bị khác để giữ lịch sử tin nhắn an toàn.
  internal static var screenSessionVerificationRequestSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_request_subtitle") }
  /// Giờ bạn có thể đọc hoặc gửi tin nhắn an toàn trên thiết bị khác.
  internal static var screenSessionVerificationRequestSuccessSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_request_success_subtitle") }
  /// Thiết bị đã xác minh
  internal static var screenSessionVerificationRequestSuccessTitle: String { return L10n.tr("Localizable", "screen_session_verification_request_success_title") }
  /// Đã yêu cầu xác minh
  internal static var screenSessionVerificationRequestTitle: String { return L10n.tr("Localizable", "screen_session_verification_request_title") }
  /// Chúng không khớp
  internal static var screenSessionVerificationTheyDontMatch: String { return L10n.tr("Localizable", "screen_session_verification_they_dont_match") }
  /// Chúng khớp
  internal static var screenSessionVerificationTheyMatch: String { return L10n.tr("Localizable", "screen_session_verification_they_match") }
  /// Đảm bảo bạn đã mở ứng dụng trên thiết bị khác trước khi bắt đầu xác minh từ đây.
  internal static var screenSessionVerificationUseAnotherDeviceSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_use_another_device_subtitle") }
  /// Mở ứng dụng trên thiết bị đã xác minh khác
  internal static var screenSessionVerificationUseAnotherDeviceTitle: String { return L10n.tr("Localizable", "screen_session_verification_use_another_device_title") }
  /// Để tăng cường bảo mật, xác minh người dùng này bằng cách so sánh bộ emoji trên thiết bị. Thực hiện điều này bằng cách sử dụng phương thức giao tiếp đáng tin cậy.
  internal static var screenSessionVerificationUserInitiatorSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_user_initiator_subtitle") }
  /// Xác minh người dùng này?
  internal static var screenSessionVerificationUserInitiatorTitle: String { return L10n.tr("Localizable", "screen_session_verification_user_initiator_title") }
  /// Để tăng cường bảo mật, người dùng khác muốn xác minh danh tính của bạn. Bạn sẽ được hiển thị bộ emoji để so sánh.
  internal static var screenSessionVerificationUserResponderSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_user_responder_subtitle") }
  /// Bạn sẽ thấy popup trên thiết bị khác. Bắt đầu xác minh từ đó ngay.
  internal static var screenSessionVerificationWaitingAnotherDeviceSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_another_device_subtitle") }
  /// Bắt đầu xác minh trên thiết bị khác
  internal static var screenSessionVerificationWaitingAnotherDeviceTitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_another_device_title") }
  /// Đang chờ thiết bị khác
  internal static var screenSessionVerificationWaitingOtherDeviceTitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_other_device_title") }
  /// Đang chờ người dùng khác
  internal static var screenSessionVerificationWaitingOtherUserTitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_other_user_title") }
  /// Khi được chấp nhận, bạn sẽ có thể tiếp tục xác minh.
  internal static var screenSessionVerificationWaitingSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_subtitle") }
  /// Chấp nhận yêu cầu để bắt đầu quá trình xác minh trong phiên khác để tiếp tục.
  internal static var screenSessionVerificationWaitingToAcceptSubtitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_to_accept_subtitle") }
  /// Đang chờ chấp nhận yêu cầu
  internal static var screenSessionVerificationWaitingToAcceptTitle: String { return L10n.tr("Localizable", "screen_session_verification_waiting_to_accept_title") }
  /// Chia sẻ vị trí
  internal static var screenShareLocationTitle: String { return L10n.tr("Localizable", "screen_share_location_title") }
  /// Chia sẻ vị trí của tôi
  internal static var screenShareMyLocationAction: String { return L10n.tr("Localizable", "screen_share_my_location_action") }
  /// Mở trong Apple Maps
  internal static var screenShareOpenAppleMaps: String { return L10n.tr("Localizable", "screen_share_open_apple_maps") }
  /// Mở trong Google Maps
  internal static var screenShareOpenGoogleMaps: String { return L10n.tr("Localizable", "screen_share_open_google_maps") }
  /// Mở trong OpenStreetMap
  internal static var screenShareOpenOsmMaps: String { return L10n.tr("Localizable", "screen_share_open_osm_maps") }
  /// Chia sẻ vị trí này
  internal static var screenShareThisLocationAction: String { return L10n.tr("Localizable", "screen_share_this_location_action") }
  /// Bạn đã thay đổi mật khẩu trên phiên khác
  internal static var screenSignedOutReason1: String { return L10n.tr("Localizable", "screen_signed_out_reason_1") }
  /// Bạn đã xóa phiên từ phiên khác
  internal static var screenSignedOutReason2: String { return L10n.tr("Localizable", "screen_signed_out_reason_2") }
  /// Quản trị viên máy chủ đã vô hiệu hóa quyền truy cập của bạn
  internal static var screenSignedOutReason3: String { return L10n.tr("Localizable", "screen_signed_out_reason_3") }
  /// Bạn có thể đã bị đăng xuất vì một trong những lý do được liệt kê bên dưới. Vui lòng đăng nhập lại để tiếp tục sử dụng %@.
  internal static func screenSignedOutSubtitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_signed_out_subtitle", String(describing: p1))
  }
  /// Bạn đã bị đăng xuất
  internal static var screenSignedOutTitle: String { return L10n.tr("Localizable", "screen_signed_out_title") }
  /// Bạn có chắc chắn muốn đăng xuất?
  internal static var screenSignoutConfirmationDialogContent: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_content") }
  /// Đăng xuất
  internal static var screenSignoutConfirmationDialogSubmit: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_submit") }
  /// Đăng xuất
  internal static var screenSignoutConfirmationDialogTitle: String { return L10n.tr("Localizable", "screen_signout_confirmation_dialog_title") }
  /// Đang đăng xuất…
  internal static var screenSignoutInProgressDialogContent: String { return L10n.tr("Localizable", "screen_signout_in_progress_dialog_content") }
  /// Bạn sắp đăng xuất khỏi phiên cuối cùng. Nếu đăng xuất ngay, bạn sẽ mất quyền truy cập vào tin nhắn mã hóa.
  internal static var screenSignoutKeyBackupDisabledSubtitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_disabled_subtitle") }
  /// Bạn đã tắt sao lưu
  internal static var screenSignoutKeyBackupDisabledTitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_disabled_title") }
  /// Khóa của bạn vẫn đang được sao lưu khi bạn ngoại tuyến. Kết nối lại để khóa có thể được sao lưu trước khi đăng xuất.
  internal static var screenSignoutKeyBackupOfflineSubtitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_offline_subtitle") }
  /// Khóa của bạn vẫn đang được sao lưu
  internal static var screenSignoutKeyBackupOfflineTitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_offline_title") }
  /// Vui lòng chờ hoàn thành trước khi đăng xuất.
  internal static var screenSignoutKeyBackupOngoingSubtitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_ongoing_subtitle") }
  /// Khóa của bạn vẫn đang được sao lưu
  internal static var screenSignoutKeyBackupOngoingTitle: String { return L10n.tr("Localizable", "screen_signout_key_backup_ongoing_title") }
  /// Đăng xuất
  internal static var screenSignoutPreferenceItem: String { return L10n.tr("Localizable", "screen_signout_preference_item") }
  /// Bạn sắp đăng xuất khỏi phiên cuối cùng. Nếu đăng xuất ngay, bạn sẽ mất quyền truy cập vào tin nhắn mã hóa.
  internal static var screenSignoutRecoveryDisabledSubtitle: String { return L10n.tr("Localizable", "screen_signout_recovery_disabled_subtitle") }
  /// Chưa thiết lập khôi phục
  internal static var screenSignoutRecoveryDisabledTitle: String { return L10n.tr("Localizable", "screen_signout_recovery_disabled_title") }
  /// Bạn sắp đăng xuất khỏi phiên cuối cùng. Nếu đăng xuất ngay, bạn có thể mất quyền truy cập vào tin nhắn mã hóa.
  internal static var screenSignoutSaveRecoveryKeySubtitle: String { return L10n.tr("Localizable", "screen_signout_save_recovery_key_subtitle") }
  /// Bạn đã lưu khóa khôi phục chưa?
  internal static var screenSignoutSaveRecoveryKeyTitle: String { return L10n.tr("Localizable", "screen_signout_save_recovery_key_title") }
  /// Đã xảy ra lỗi khi cố gắng bắt đầu trò chuyện
  internal static var screenStartChatErrorStartingChat: String { return L10n.tr("Localizable", "screen_start_chat_error_starting_chat") }
  /// Tham gia phòng theo địa chỉ
  internal static var screenStartChatJoinRoomByAddressAction: String { return L10n.tr("Localizable", "screen_start_chat_join_room_by_address_action") }
  /// Địa chỉ không hợp lệ
  internal static var screenStartChatJoinRoomByAddressInvalidAddress: String { return L10n.tr("Localizable", "screen_start_chat_join_room_by_address_invalid_address") }
  /// Nhập...
  internal static var screenStartChatJoinRoomByAddressPlaceholder: String { return L10n.tr("Localizable", "screen_start_chat_join_room_by_address_placeholder") }
  /// Tìm thấy phòng khớp
  internal static var screenStartChatJoinRoomByAddressRoomFound: String { return L10n.tr("Localizable", "screen_start_chat_join_room_by_address_room_found") }
  /// Không tìm thấy phòng
  internal static var screenStartChatJoinRoomByAddressRoomNotFound: String { return L10n.tr("Localizable", "screen_start_chat_join_room_by_address_room_not_found") }
  /// ví dụ: #room-name:sevenchat.space
  internal static var screenStartChatJoinRoomByAddressSupportingText: String { return L10n.tr("Localizable", "screen_start_chat_join_room_by_address_supporting_text") }
  /// Tin nhắn không được gửi vì danh tính đã xác minh của %1$@ đã được đặt lại.
  internal static func screenTimelineItemMenuSendFailureChangedIdentity(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_timeline_item_menu_send_failure_changed_identity", String(describing: p1))
  }
  /// Tin nhắn không được gửi vì %1$@ chưa xác minh tất cả thiết bị.
  internal static func screenTimelineItemMenuSendFailureUnsignedDevice(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_timeline_item_menu_send_failure_unsigned_device", String(describing: p1))
  }
  /// Tin nhắn không được gửi vì bạn chưa xác minh một hoặc nhiều thiết bị.
  internal static var screenTimelineItemMenuSendFailureYouUnsignedDevice: String { return L10n.tr("Localizable", "screen_timeline_item_menu_send_failure_you_unsigned_device") }
  /// Vị trí
  internal static var screenViewLocationTitle: String { return L10n.tr("Localizable", "screen_view_location_title") }
  /// Cuộc gọi, bình chọn, tìm kiếm và nhiều tính năng khác sẽ được thêm vào cuối năm nay.
  internal static var screenWelcomeBullet1: String { return L10n.tr("Localizable", "screen_welcome_bullet_1") }
  /// Lịch sử tin nhắn cho phòng mã hóa chưa khả dụng.
  internal static var screenWelcomeBullet2: String { return L10n.tr("Localizable", "screen_welcome_bullet_2") }
  /// Chúng tôi rất muốn nghe từ bạn, hãy cho chúng tôi biết suy nghĩ qua trang cài đặt.
  internal static var screenWelcomeBullet3: String { return L10n.tr("Localizable", "screen_welcome_bullet_3") }
  /// Bắt đầu thôi!
  internal static var screenWelcomeButton: String { return L10n.tr("Localizable", "screen_welcome_button") }
  /// Đây là những gì bạn cần biết:
  internal static var screenWelcomeSubtitle: String { return L10n.tr("Localizable", "screen_welcome_subtitle") }
  /// Chào mừng đến với %1$@!
  internal static func screenWelcomeTitle(_ p1: Any) -> String {
    return L10n.tr("Localizable", "screen_welcome_title", String(describing: p1))
  }
  /// Có vẻ như bạn đang sử dụng thiết bị mới. Xác minh với thiết bị khác để truy cập tin nhắn mã hóa.
  internal static var sessionVerificationBannerMessage: String { return L10n.tr("Localizable", "session_verification_banner_message") }
  /// Xác minh đó là bạn
  internal static var sessionVerificationBannerTitle: String { return L10n.tr("Localizable", "session_verification_banner_title") }
  /// Rageshake
  internal static var settingsRageshake: String { return L10n.tr("Localizable", "settings_rageshake") }
  /// Ngưỡng phát hiện
  internal static var settingsRageshakeDetectionThreshold: String { return L10n.tr("Localizable", "settings_rageshake_detection_threshold") }
  /// Phiên bản: %1$@ (%2$@)
  internal static func settingsVersionNumber(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "settings_version_number", String(describing: p1), String(describing: p2))
  }
  /// (avatar cũng đã thay đổi)
  internal static var stateEventAvatarChangedToo: String { return L10n.tr("Localizable", "state_event_avatar_changed_too") }
  /// %1$@ đã thay đổi avatar
  internal static func stateEventAvatarUrlChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_avatar_url_changed", String(describing: p1))
  }
  /// Bạn đã thay đổi avatar
  internal static var stateEventAvatarUrlChangedByYou: String { return L10n.tr("Localizable", "state_event_avatar_url_changed_by_you") }
  /// %1$@ đã bị hạ cấp xuống thành viên
  internal static func stateEventDemotedToMember(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_demoted_to_member", String(describing: p1))
  }
  /// %1$@ đã bị hạ cấp xuống điều hành viên
  internal static func stateEventDemotedToModerator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_demoted_to_moderator", String(describing: p1))
  }
  /// %1$@ đã thay đổi tên hiển thị từ %2$@ thành %3$@
  internal static func stateEventDisplayNameChangedFrom(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_changed_from", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Bạn đã thay đổi tên hiển thị từ %1$@ thành %2$@
  internal static func stateEventDisplayNameChangedFromByYou(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_changed_from_by_you", String(describing: p1), String(describing: p2))
  }
  /// %1$@ đã xóa tên hiển thị (trước đó là %2$@)
  internal static func stateEventDisplayNameRemoved(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_removed", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã xóa tên hiển thị (trước đó là %1$@)
  internal static func stateEventDisplayNameRemovedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_removed_by_you", String(describing: p1))
  }
  /// %1$@ đã đặt tên hiển thị thành %2$@
  internal static func stateEventDisplayNameSet(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_set", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã đặt tên hiển thị thành %1$@
  internal static func stateEventDisplayNameSetByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_display_name_set_by_you", String(describing: p1))
  }
  /// %1$@ đã được thăng cấp lên quản trị viên
  internal static func stateEventPromotedToAdministrator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_promoted_to_administrator", String(describing: p1))
  }
  /// %1$@ đã được thăng cấp lên điều hành viên
  internal static func stateEventPromotedToModerator(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_promoted_to_moderator", String(describing: p1))
  }
  /// %1$@ đã thay đổi avatar phòng
  internal static func stateEventRoomAvatarChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_avatar_changed", String(describing: p1))
  }
  /// Bạn đã thay đổi avatar phòng
  internal static var stateEventRoomAvatarChangedByYou: String { return L10n.tr("Localizable", "state_event_room_avatar_changed_by_you") }
  /// %1$@ đã xóa avatar phòng
  internal static func stateEventRoomAvatarRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_avatar_removed", String(describing: p1))
  }
  /// Bạn đã xóa avatar phòng
  internal static var stateEventRoomAvatarRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_avatar_removed_by_you") }
  /// %1$@ đã cấm %2$@
  internal static func stateEventRoomBan(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã cấm %1$@
  internal static func stateEventRoomBanByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban_by_you", String(describing: p1))
  }
  /// Bạn đã cấm %1$@: %2$@
  internal static func stateEventRoomBanByYouWithReason(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban_by_you_with_reason", String(describing: p1), String(describing: p2))
  }
  /// %1$@ đã cấm %2$@: %3$@
  internal static func stateEventRoomBanWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_ban_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// %1$@ đã tạo phòng
  internal static func stateEventRoomCreated(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_created", String(describing: p1))
  }
  /// Bạn đã tạo phòng
  internal static var stateEventRoomCreatedByYou: String { return L10n.tr("Localizable", "state_event_room_created_by_you") }
  /// %1$@ đã mời %2$@
  internal static func stateEventRoomInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite", String(describing: p1), String(describing: p2))
  }
  /// %1$@ đã chấp nhận lời mời
  internal static func stateEventRoomInviteAccepted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_accepted", String(describing: p1))
  }
  /// Bạn đã chấp nhận lời mời
  internal static var stateEventRoomInviteAcceptedByYou: String { return L10n.tr("Localizable", "state_event_room_invite_accepted_by_you") }
  /// Bạn đã mời %1$@
  internal static func stateEventRoomInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_by_you", String(describing: p1))
  }
  /// %1$@ đã mời bạn
  internal static func stateEventRoomInviteYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_invite_you", String(describing: p1))
  }
  /// %1$@ đã tham gia phòng
  internal static func stateEventRoomJoin(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_join", String(describing: p1))
  }
  /// Bạn đã tham gia phòng
  internal static var stateEventRoomJoinByYou: String { return L10n.tr("Localizable", "state_event_room_join_by_you") }
  /// %1$@ đang yêu cầu tham gia
  internal static func stateEventRoomKnock(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock", String(describing: p1))
  }
  /// %1$@ đã cấp quyền truy cập cho %2$@
  internal static func stateEventRoomKnockAccepted(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_accepted", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã cho phép %1$@ tham gia
  internal static func stateEventRoomKnockAcceptedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_accepted_by_you", String(describing: p1))
  }
  /// Bạn đã yêu cầu tham gia
  internal static var stateEventRoomKnockByYou: String { return L10n.tr("Localizable", "state_event_room_knock_by_you") }
  /// %1$@ đã từ chối yêu cầu tham gia của %2$@
  internal static func stateEventRoomKnockDenied(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã từ chối yêu cầu tham gia của %1$@
  internal static func stateEventRoomKnockDeniedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied_by_you", String(describing: p1))
  }
  /// %1$@ đã từ chối yêu cầu tham gia của bạn
  internal static func stateEventRoomKnockDeniedYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_denied_you", String(describing: p1))
  }
  /// %1$@ không còn muốn tham gia nữa
  internal static func stateEventRoomKnockRetracted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_knock_retracted", String(describing: p1))
  }
  /// Bạn đã hủy yêu cầu tham gia
  internal static var stateEventRoomKnockRetractedByYou: String { return L10n.tr("Localizable", "state_event_room_knock_retracted_by_you") }
  /// %1$@ đã rời phòng
  internal static func stateEventRoomLeave(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_leave", String(describing: p1))
  }
  /// Bạn đã rời phòng
  internal static var stateEventRoomLeaveByYou: String { return L10n.tr("Localizable", "state_event_room_leave_by_you") }
  /// %1$@ đã thay đổi tên phòng thành: %2$@
  internal static func stateEventRoomNameChanged(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_changed", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã thay đổi tên phòng thành: %1$@
  internal static func stateEventRoomNameChangedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_changed_by_you", String(describing: p1))
  }
  /// %1$@ đã xóa tên phòng
  internal static func stateEventRoomNameRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_name_removed", String(describing: p1))
  }
  /// Bạn đã xóa tên phòng
  internal static var stateEventRoomNameRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_name_removed_by_you") }
  /// %1$@ không thay đổi gì
  internal static func stateEventRoomNone(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_none", String(describing: p1))
  }
  /// Bạn không thay đổi gì
  internal static var stateEventRoomNoneByYou: String { return L10n.tr("Localizable", "state_event_room_none_by_you") }
  /// %1$@ đã thay đổi tin nhắn đã ghim
  internal static func stateEventRoomPinnedEventsChanged(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_pinned_events_changed", String(describing: p1))
  }
  /// Bạn đã thay đổi tin nhắn đã ghim
  internal static var stateEventRoomPinnedEventsChangedByYou: String { return L10n.tr("Localizable", "state_event_room_pinned_events_changed_by_you") }
  /// %1$@ đã ghim tin nhắn
  internal static func stateEventRoomPinnedEventsPinned(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_pinned_events_pinned", String(describing: p1))
  }
  /// Bạn đã ghim tin nhắn
  internal static var stateEventRoomPinnedEventsPinnedByYou: String { return L10n.tr("Localizable", "state_event_room_pinned_events_pinned_by_you") }
  /// %1$@ đã bỏ ghim tin nhắn
  internal static func stateEventRoomPinnedEventsUnpinned(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_pinned_events_unpinned", String(describing: p1))
  }
  /// Bạn đã bỏ ghim tin nhắn
  internal static var stateEventRoomPinnedEventsUnpinnedByYou: String { return L10n.tr("Localizable", "state_event_room_pinned_events_unpinned_by_you") }
  /// %1$@ đã từ chối lời mời
  internal static func stateEventRoomReject(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_reject", String(describing: p1))
  }
  /// Bạn đã từ chối lời mời
  internal static var stateEventRoomRejectByYou: String { return L10n.tr("Localizable", "state_event_room_reject_by_you") }
  /// %1$@ đã xóa %2$@
  internal static func stateEventRoomRemove(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã xóa %1$@
  internal static func stateEventRoomRemoveByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove_by_you", String(describing: p1))
  }
  /// Bạn đã xóa %1$@: %2$@
  internal static func stateEventRoomRemoveByYouWithReason(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove_by_you_with_reason", String(describing: p1), String(describing: p2))
  }
  /// %1$@ đã xóa %2$@: %3$@
  internal static func stateEventRoomRemoveWithReason(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_remove_with_reason", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// %1$@ đã gửi lời mời cho %2$@ tham gia phòng
  internal static func stateEventRoomThirdPartyInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_invite", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã gửi lời mời cho %1$@ tham gia phòng
  internal static func stateEventRoomThirdPartyInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_invite_by_you", String(describing: p1))
  }
  /// %1$@ đã thu hồi lời mời cho %2$@ tham gia phòng
  internal static func stateEventRoomThirdPartyRevokedInvite(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_revoked_invite", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã thu hồi lời mời cho %1$@ tham gia phòng
  internal static func stateEventRoomThirdPartyRevokedInviteByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_third_party_revoked_invite_by_you", String(describing: p1))
  }
  /// %1$@ đã thay đổi chủ đề thành: %2$@
  internal static func stateEventRoomTopicChanged(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_changed", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã thay đổi chủ đề thành: %1$@
  internal static func stateEventRoomTopicChangedByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_changed_by_you", String(describing: p1))
  }
  /// %1$@ đã xóa chủ đề phòng
  internal static func stateEventRoomTopicRemoved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_topic_removed", String(describing: p1))
  }
  /// Bạn đã xóa chủ đề phòng
  internal static var stateEventRoomTopicRemovedByYou: String { return L10n.tr("Localizable", "state_event_room_topic_removed_by_you") }
  /// %1$@ đã bỏ cấm %2$@
  internal static func stateEventRoomUnban(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unban", String(describing: p1), String(describing: p2))
  }
  /// Bạn đã bỏ cấm %1$@
  internal static func stateEventRoomUnbanByYou(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unban_by_you", String(describing: p1))
  }
  /// %1$@ đã thực hiện thay đổi không xác định đối với tư cách thành viên
  internal static func stateEventRoomUnknownMembershipChange(_ p1: Any) -> String {
    return L10n.tr("Localizable", "state_event_room_unknown_membership_change", String(describing: p1))
  }
  /// vi
  internal static var testLanguageIdentifier: String { return L10n.tr("Localizable", "test_language_identifier") }
  /// en
  internal static var testUntranslatedDefaultLanguageIdentifier: String { return L10n.tr("Localizable", "test_untranslated_default_language_identifier") }
  /// Tin nhắn lịch sử không khả dụng trên thiết bị này
  internal static var timelineDecryptionFailureHistoricalEventNoKeyBackup: String { return L10n.tr("Localizable", "timeline_decryption_failure_historical_event_no_key_backup") }
  /// Bạn cần xác minh thiết bị này để truy cập tin nhắn lịch sử
  internal static var timelineDecryptionFailureHistoricalEventUnverifiedDevice: String { return L10n.tr("Localizable", "timeline_decryption_failure_historical_event_unverified_device") }
  /// Bạn không có quyền truy cập tin nhắn này
  internal static var timelineDecryptionFailureHistoricalEventUserNotJoined: String { return L10n.tr("Localizable", "timeline_decryption_failure_historical_event_user_not_joined") }
  /// Không thể giải mã tin nhắn
  internal static var timelineDecryptionFailureUnableToDecrypt: String { return L10n.tr("Localizable", "timeline_decryption_failure_unable_to_decrypt") }
  /// Tin nhắn này đã bị chặn vì bạn không xác minh thiết bị hoặc người gửi cần xác minh danh tính của bạn.
  internal static var timelineDecryptionFailureWithheldUnverified: String { return L10n.tr("Localizable", "timeline_decryption_failure_withheld_unverified") }
  /// Lịch sử push
  internal static var troubleshootNotificationsEntryPointPushHistoryTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_entry_point_push_history_title") }
  /// Khắc phục sự cố
  internal static var troubleshootNotificationsEntryPointSection: String { return L10n.tr("Localizable", "troubleshoot_notifications_entry_point_section") }
  /// Khắc phục sự cố thông báo
  internal static var troubleshootNotificationsEntryPointTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_entry_point_title") }
  /// Chạy thử nghiệm
  internal static var troubleshootNotificationsScreenAction: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_action") }
  /// Chạy thử nghiệm lại
  internal static var troubleshootNotificationsScreenActionAgain: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_action_again") }
  /// Một số thử nghiệm thất bại. Vui lòng kiểm tra chi tiết.
  internal static var troubleshootNotificationsScreenFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_failure") }
  /// Chạy thử nghiệm để phát hiện vấn đề trong cấu hình có thể khiến thông báo không hoạt động như mong đợi.
  internal static var troubleshootNotificationsScreenNotice: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_notice") }
  /// Cố gắng sửa
  internal static var troubleshootNotificationsScreenQuickFixAction: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_quick_fix_action") }
  /// Tất cả thử nghiệm đã thành công.
  internal static var troubleshootNotificationsScreenSuccess: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_success") }
  /// Khắc phục sự cố thông báo
  internal static var troubleshootNotificationsScreenTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_title") }
  /// Một số thử nghiệm cần sự chú ý của bạn. Vui lòng kiểm tra chi tiết.
  internal static var troubleshootNotificationsScreenWaiting: String { return L10n.tr("Localizable", "troubleshoot_notifications_screen_waiting") }
  /// Kiểm tra ứng dụng có thể hiển thị thông báo.
  internal static var troubleshootNotificationsTestCheckPermissionDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_check_permission_description") }
  /// Kiểm tra quyền
  internal static var troubleshootNotificationsTestCheckPermissionTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_check_permission_title") }
  /// Lấy tên nhà cung cấp hiện tại.
  internal static var troubleshootNotificationsTestCurrentPushProviderDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_description") }
  /// Không có nhà cung cấp push được chọn.
  internal static var troubleshootNotificationsTestCurrentPushProviderFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_failure") }
  /// Nhà cung cấp push hiện tại: %1$@.
  internal static func troubleshootNotificationsTestCurrentPushProviderSuccess(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_success", String(describing: p1))
  }
  /// Nhà cung cấp push hiện tại
  internal static var troubleshootNotificationsTestCurrentPushProviderTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_current_push_provider_title") }
  /// Đảm bảo ứng dụng hỗ trợ ít nhất một nhà cung cấp push.
  internal static var troubleshootNotificationsTestDetectPushProviderDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_description") }
  /// Không tìm thấy hỗ trợ nhà cung cấp push.
  internal static var troubleshootNotificationsTestDetectPushProviderFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_failure") }
  /// Plural format key: "%#@COUNT@"
  internal static func troubleshootNotificationsTestDetectPushProviderSuccess(_ p1: Int) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_success", p1)
  }
  /// Ứng dụng được xây dựng với hỗ trợ cho: %1$@
  internal static func troubleshootNotificationsTestDetectPushProviderSuccess2(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_success_2", String(describing: p1))
  }
  /// Hỗ trợ nhà cung cấp push
  internal static var troubleshootNotificationsTestDetectPushProviderTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_detect_push_provider_title") }
  /// Kiểm tra ứng dụng có thể hiển thị thông báo.
  internal static var troubleshootNotificationsTestDisplayNotificationDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_description") }
  /// Thông báo chưa được nhấp.
  internal static var troubleshootNotificationsTestDisplayNotificationFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_failure") }
  /// Không thể hiển thị thông báo.
  internal static var troubleshootNotificationsTestDisplayNotificationPermissionFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_permission_failure") }
  /// Thông báo đã được nhấp!
  internal static var troubleshootNotificationsTestDisplayNotificationSuccess: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_success") }
  /// Hiển thị thông báo
  internal static var troubleshootNotificationsTestDisplayNotificationTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_title") }
  /// Vui lòng nhấp vào thông báo để tiếp tục thử nghiệm.
  internal static var troubleshootNotificationsTestDisplayNotificationWaiting: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_display_notification_waiting") }
  /// Đảm bảo Firebase khả dụng.
  internal static var troubleshootNotificationsTestFirebaseAvailabilityDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_description") }
  /// Firebase không khả dụng.
  internal static var troubleshootNotificationsTestFirebaseAvailabilityFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_failure") }
  /// Firebase khả dụng.
  internal static var troubleshootNotificationsTestFirebaseAvailabilitySuccess: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_success") }
  /// Kiểm tra Firebase
  internal static var troubleshootNotificationsTestFirebaseAvailabilityTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_availability_title") }
  /// Đảm bảo token Firebase khả dụng.
  internal static var troubleshootNotificationsTestFirebaseTokenDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_description") }
  /// Token Firebase không xác định.
  internal static var troubleshootNotificationsTestFirebaseTokenFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_failure") }
  /// Token Firebase: %1$@.
  internal static func troubleshootNotificationsTestFirebaseTokenSuccess(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_success", String(describing: p1))
  }
  /// Kiểm tra token Firebase
  internal static var troubleshootNotificationsTestFirebaseTokenTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_firebase_token_title") }
  /// Đảm bảo ứng dụng đang nhận push.
  internal static var troubleshootNotificationsTestPushLoopBackDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_description") }
  /// Lỗi: pusher đã từ chối yêu cầu.
  internal static var troubleshootNotificationsTestPushLoopBackFailure1: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_1") }
  /// Lỗi: %1$@.
  internal static func troubleshootNotificationsTestPushLoopBackFailure2(_ p1: Any) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_2", String(describing: p1))
  }
  /// Lỗi, không thể thử nghiệm push.
  internal static var troubleshootNotificationsTestPushLoopBackFailure3: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_3") }
  /// Lỗi, hết thời gian chờ push.
  internal static var troubleshootNotificationsTestPushLoopBackFailure4: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_failure_4") }
  /// Push loop back mất %1$d ms.
  internal static func troubleshootNotificationsTestPushLoopBackSuccess(_ p1: Int) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_success", p1)
  }
  /// Thử nghiệm Push loop back
  internal static var troubleshootNotificationsTestPushLoopBackTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_push_loop_back_title") }
  /// Đảm bảo bộ phân phối UnifiedPush khả dụng.
  internal static var troubleshootNotificationsTestUnifiedPushDescription: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_description") }
  /// Không tìm thấy bộ phân phối push.
  internal static var troubleshootNotificationsTestUnifiedPushFailure: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_failure") }
  /// Plural format key: "%#@COUNT@"
  internal static func troubleshootNotificationsTestUnifiedPushSuccess(_ p1: Int) -> String {
    return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_success", p1)
  }
  /// Kiểm tra UnifiedPush
  internal static var troubleshootNotificationsTestUnifiedPushTitle: String { return L10n.tr("Localizable", "troubleshoot_notifications_test_unified_push_title") }

  internal enum A11y {
    /// Chi tiết mã hóa
    internal static var encryptionDetails: String { return L10n.tr("Localizable", "a11y.encryption_details") }
    /// Di chuyển bản đồ đến vị trí của tôi
    internal static var moveTheMapToMyLocation: String { return L10n.tr("Localizable", "a11y.move_the_map_to_my_location") }
    /// Avatar của người dùng khác
    internal static var otherUserAvatar: String { return L10n.tr("Localizable", "a11y.other_user_avatar") }
    /// Avatar phòng
    internal static var roomAvatar: String { return L10n.tr("Localizable", "a11y.room_avatar") }
    /// Avatar người dùng
    internal static var userAvatar: String { return L10n.tr("Localizable", "a11y.user_avatar") }
    /// Avatar của bạn
    internal static var yourAvatar: String { return L10n.tr("Localizable", "a11y.your_avatar") }
  }

  internal enum Action {
    /// Mở menu ngữ cảnh
    internal static var openContextMenu: String { return L10n.tr("Localizable", "action.open_context_menu") }
    /// Gửi tin nhắn đã chỉnh sửa
    internal static var sendEditedMessage: String { return L10n.tr("Localizable", "action.send_edited_message") }
    /// Gửi tin nhắn thoại
    internal static var sendVoiceMessage: String { return L10n.tr("Localizable", "action.send_voice_message") }
    /// Xem
    internal static var view: String { return L10n.tr("Localizable", "action.view") }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // Use preferredLocalizations to get a language that is in the bundle and the user's preferred list of languages.
    let languages = Bundle.overrideLocalizations ?? Bundle.app.preferredLocalizations

    for language in languages {
      if let translation = trIn(language, table, key, args) {
        return translation
      }
    }
    return Bundle.app.developmentLocalization.flatMap { trIn($0, table, key, args) } ?? key
  }

  private static func trIn(_ language: String, _ table: String, _ key: String, _ args: CVarArg...) -> String? {
    guard let bundle = Bundle.lprojBundle(for: language) else { return nil }
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    let translation = String(format: format, locale: Locale(identifier: language), arguments: args)
    guard translation != key, 
          translation != "\(key) \(key)" // Handle double pseudo for tests
      else { 
        return nil 
      }
    return translation
  }
}

// swiftlint:enable all
