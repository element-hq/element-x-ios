# GitHub Actions Build Guide for Element X iOS

## Tổng quan

Dự án Element X iOS đã được cấu hình để sử dụng GitHub Actions cho việc build và test. Hệ thống bao gồm:

### Workflows hiện có:
- **Unit Tests** - Chạy unit tests và preview tests
- **UI Tests** - Chạy UI tests trên iPhone và iPad  
- **Integration Tests** - Chạy integration tests
- **Accessibility Tests** - Chạy accessibility tests
- **Build iOS App** - Build app cho simulator (mới thêm)
- **Build Simulator App** - Build app cho simulator với nhiều device options (mới thêm)
- **Build IPA** - Build IPA file cho deployment (mới thêm)

## Cách sử dụng

### 1. Build cho Simulator

Có 2 workflows để build cho simulator:

#### A. Build iOS App (`build.yml`)
Workflow này build app với các configuration khác nhau:

**Trigger tự động:**
- Khi push code lên branch `main` hoặc `develop`
- Khi tạo pull request
- Khi tạo tag `release/*` hoặc `nightly/*`

**Trigger thủ công:**
1. Vào tab **Actions** trên GitHub
2. Chọn workflow **Build iOS App**
3. Click **Run workflow**
4. Chọn build type:
   - **debug**: Build debug version
   - **release**: Build release version  
   - **nightly**: Build nightly version với custom build number

#### B. Build Simulator App (`build-simulator.yml`) - **Khuyến nghị**
Workflow này đơn giản hơn và cho phép chọn device cụ thể:

**Trigger tự động:**
- Khi push code lên branch `main` hoặc `develop`
- Khi tạo pull request

**Trigger thủ công:**
1. Vào tab **Actions** trên GitHub
2. Chọn workflow **Build Simulator App**
3. Click **Run workflow**
4. Chọn:
   - **Device**: iPhone 16, iPhone 16 Pro, iPhone SE, iPad
   - **Configuration**: Debug hoặc Release

**Ưu điểm:**
- Build nhanh hơn
- Chọn device cụ thể
- Tự động tạo simulator nếu cần
- App bundle được upload làm artifact
- Có thể cài đặt trực tiếp vào simulator

### 2. Build IPA cho Deployment

Workflow `build-ipa.yml` tạo IPA file để deploy lên App Store hoặc TestFlight:

#### Yêu cầu Secrets:
Bạn cần cấu hình các secrets sau trong repository settings:

```
P12_BASE64: Certificate file (base64 encoded)
P12_PASSWORD: Certificate password
BUNDLE_ID: App bundle identifier
TEAM_ID: Apple Developer Team ID
PROVISIONING_PROFILE_NAME: Provisioning profile name
APPSTORE_ISSUER_ID: App Store Connect Issuer ID
APPSTORE_KEY_ID: App Store Connect API Key ID
APPSTORE_PRIVATE_KEY: App Store Connect API Private Key
```

#### Cách cấu hình secrets:

1. **Certificate và Provisioning Profile:**
   ```bash
   # Export certificate to base64
   base64 -i Certificates.p12 | pbcopy
   ```

2. **App Store Connect API:**
   - Tạo API key trong App Store Connect
   - Download file `.p8` và convert sang base64
   - Lưu Issuer ID và Key ID

#### Trigger:
- Tự động khi tạo tag `release/*` hoặc `nightly/*`
- Thủ công qua GitHub Actions UI

### 3. Build Nightly

Để build nightly version:

```bash
# Tạo tag nightly
git tag nightly/25.08.0.20241201
git push origin nightly/25.08.0.20241201
```

Hoặc trigger thủ công với build number tùy chỉnh.

## Cấu hình Environment

### macOS Runner
- Sử dụng `macos-15` với Xcode 16.4
- Có sẵn iOS Simulator và build tools

### Dependencies
- Ruby gems được cache để tăng tốc độ
- Fastlane để quản lý build process
- XcodeGen để generate Xcode project

### Caching
- Ruby gems cache
- LFS files cache
- Build artifacts được lưu trữ 7-30 ngày

## Troubleshooting

### Lỗi thường gặp:

1. **Code signing errors:**
   - Kiểm tra certificate và provisioning profile
   - Đảm bảo bundle ID khớp với profile

2. **Build timeout:**
   - Workflow có timeout 6 giờ
   - Có thể tăng thời gian nếu cần

3. **Simulator issues:**
   - Workflow tự động tạo simulator nếu cần
   - Sử dụng iPhone 16 với iOS 18.5

### Logs và Artifacts:
- Build logs có sẵn trong GitHub Actions
- App bundles (.app) được upload làm artifacts
- IPA files được upload làm artifacts (cho deployment)
- Test results được upload lên Codecov

### Cách sử dụng App Bundle:

#### Phương pháp 1: Sử dụng script helper (Khuyến nghị)
```bash
# Download artifact từ GitHub Actions
# Extract file .app
# Chạy script helper
./scripts/install-simulator-app.sh /path/to/ElementX.app
```

#### Phương pháp 2: Thủ công
1. **Download artifact** từ tab Actions
2. **Extract** file .app
3. **Cài đặt vào simulator:**
   ```bash
   # Drag and drop vào simulator, hoặc
   xcrun simctl install booted /path/to/ElementX.app
   ```
4. **Chạy app:**
   ```bash
   xcrun simctl launch booted com.element.ElementX
   ```

### Script Helper Features:
- Tự động tạo simulator nếu cần
- Tự động boot simulator
- Uninstall app cũ nếu có
- Install và launch app mới
- Hiển thị thông tin chi tiết
- Hỗ trợ màu sắc trong output

## Tùy chỉnh

### Thêm build configuration mới:
1. Tạo file `Variants/YourVariant/your_variant.yml`
2. Thêm vào `project.yml` include section
3. Tạo fastlane lane tương ứng

### Thay đổi iOS version:
- Cập nhật `deploymentTarget` trong `project.yml`
- Cập nhật simulator version trong workflows

### Thêm test device:
- Thêm vào matrix trong `ui_tests.yml`
- Cập nhật device configuration

## Liên kết hữu ích

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [Apple Developer Documentation](https://developer.apple.com/documentation/) 