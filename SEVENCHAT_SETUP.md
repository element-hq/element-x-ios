# SevenChat - Hướng dẫn Setup

## ✅ Đã hoàn thành

### 1. Đổi tên app từ "Element X" sang "SevenChat"
- ✅ Cập nhật `app.yml`: APP_DISPLAY_NAME, PRODUCTION_APP_NAME, Bundle Identifier
- ✅ Cập nhật `project.yml`: Tên project, Organization name
- ✅ Cập nhật `Package.swift`: Tên package
- ✅ Cập nhật `Info.plist`: URL schemes, Bundle URL name
- ✅ Cập nhật tất cả file localization (.strings)
- ✅ Tạo project mới: `SevenChat.xcodeproj`

### 2. Thông tin app mới
- **Tên hiển thị**: SevenChat
- **Bundle Identifier**: `io.sevenchat.sevenchat`
- **App Group**: `group.io.sevenchat`
- **URL Scheme**: `io.sevenchat.call`

## 🔧 Cần làm tiếp theo

### 1. Trong Xcode (SevenChat.xcodeproj)

#### Cập nhật Bundle Identifier cho tất cả targets:
- **SevenChat**: `io.sevenchat.sevenchat`
- **SevenChatTests**: `io.sevenchat.sevenchat.tests`
- **SevenChatUITests**: `io.sevenchat.sevenchat.uitests`
- **SevenChatPreviewTests**: `io.sevenchat.sevenchat.previewtests`
- **SevenChatIntegrationTests**: `io.sevenchat.sevenchat.integrationtests`
- **SevenChatAccessibilityTests**: `io.sevenchat.sevenchat.accessibilitytests`
- **NSE**: `io.sevenchat.sevenchat.nse`
- **ShareExtension**: `io.sevenchat.sevenchat.shareextension`

#### Cập nhật App Group cho các targets cần thiết:
- **SevenChat**: `group.io.sevenchat`
- **NSE**: `group.io.sevenchat`
- **ShareExtension**: `group.io.sevenchat`

#### Cập nhật URL Schemes:
- **SevenChat Call**: `io.sevenchat.call`
- **Application**: `io.sevenchat.sevenchat`, `matrix`

### 2. Cập nhật App Icon
- Thay đổi icon trong `ElementX/Resources/Assets.xcassets/AppIcon.appiconset/`
- Tạo icon mới với kích thước phù hợp

### 3. Cập nhật Launch Screen
- Thay đổi launch screen nếu cần thiết
- Cập nhật màu sắc và logo

### 4. Test app
```bash
# Build app
⌘ + B

# Run tests
⌘ + U

# Run UI tests
# Chọn scheme "SevenChatUITests" và run
```

### 5. Cập nhật các file khác (nếu cần)
- **README.md**: Cập nhật tên app
- **CHANGES.md**: Cập nhật changelog
- **Fastlane**: Cập nhật cấu hình CI/CD
- **Dangerfile.swift**: Cập nhật tên app

## 🚀 Build và Run

1. **Mở project**: `SevenChat.xcodeproj`
2. **Chọn scheme**: "SevenChat"
3. **Chọn device**: iPhone Simulator hoặc thiết bị thật
4. **Build**: ⌘ + B
5. **Run**: ⌘ + R

## 📱 Cài đặt trên thiết bị thật

1. **Signing**: Cập nhật Team ID và Provisioning Profile
2. **Bundle Identifier**: Đảm bảo unique và đã đăng ký
3. **App Groups**: Đăng ký App Group mới nếu cần
4. **Capabilities**: Kiểm tra các capabilities cần thiết

## 🔍 Troubleshooting

### Lỗi thường gặp:
1. **Bundle Identifier conflict**: Đổi thành tên unique khác
2. **App Group không tồn tại**: Đăng ký App Group mới
3. **Signing issues**: Cập nhật Team ID và certificates
4. **Dependencies**: Reset package cache nếu cần

### Reset nếu có lỗi:
```bash
# Reset package cache
File -> Packages -> Reset Package Caches

# Clean build folder
Product -> Clean Build Folder

# Rebuild project
xcodegen
```

## 📞 Hỗ trợ

Nếu gặp vấn đề, hãy kiểm tra:
1. Bundle Identifier đã unique chưa
2. App Group đã được đăng ký chưa
3. Signing configuration đúng chưa
4. Dependencies đã được resolve chưa 