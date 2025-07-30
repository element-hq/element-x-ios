# Debug: File không hiển thị trong Media Browser

## Vấn đề
Người dùng gửi file trong phòng chat nhưng file không hiển thị trong phần "Tệp" của Media Browser.

## Các thay đổi đã thực hiện

### 1. Thêm logging vào RoomTimelineItemFactory
- **File**: `ElementX/Sources/Services/Timeline/TimelineItems/RoomTimelineItemFactory.swift`
- **Thay đổi**: Thêm logging trong `buildFileTimelineItemContent` để debug file processing
- **Log**: Tên file, MIME type, kích thước, content type

### 2. Thêm logging vào MediaEventsTimelineScreenViewModel
- **File**: `ElementX/Sources/Screens/MediaEventsTimelineScreen/MediaEventsTimelineScreenViewModel.swift`
- **Thay đổi**: Thêm logging trong `updateWithTimelineViewState` để debug việc lọc
- **Log**: Số lượng timeline items, screen mode, loại item, kết quả lọc

### 3. Thêm logging vào MediaEventsTimelineFlowCoordinator
- **File**: `ElementX/Sources/FlowCoordinators/MediaEventsTimelineFlowCoordinator.swift`
- **Thay đổi**: Thêm logging trong `presentMediaEventsTimeline` để debug việc tạo TimelineController
- **Log**: Quá trình tạo media và files timeline controller

## Cách debug

### 1. Build và chạy ứng dụng
```bash
# Build ứng dụng
xcodebuild -scheme ElementX -destination 'platform=iOS Simulator,name=iPhone 15' build

# Hoặc mở trong Xcode và chạy
open SevenChat.xcodeproj
```

### 2. Gửi file trong phòng chat
- Tạo một phòng chat
- Gửi một file (ZIP, PDF, TXT, etc.)
- Mở Media Browser (vào thông tin phòng → Media và tệp)

### 3. Kiểm tra logs
Trong Xcode Console hoặc terminal, tìm các log có prefix `🔍`:

```
🔍 Media Browser: Creating files timeline controller with allowedMessageTypes: [.file, .audio]
🔍 Processing file: example.zip
🔍 File MIME type: application/zip
🔍 File size: 1024
🔍 File content type: public.zip-archive
🔍 Media Browser: Processing 5 timeline items
🔍 Media Browser: Current screen mode: files
🔍 Media Browser: Item type file - should show: true
🔍 Media Browser: Created 1 groups with 1 items
```

### 4. Phân tích logs

#### A. Nếu không thấy log "Processing file":
- File không được xử lý như `FileMessageContent`
- Có thể file được phân loại sai type

#### B. Nếu thấy log "Processing file" nhưng không hiển thị:
- Kiểm tra MIME type có đúng không
- Kiểm tra file có được lọc đúng không

#### C. Nếu TimelineController không được tạo:
- Có lỗi trong việc tạo timeline controller
- Kiểm tra room proxy có hoạt động không

## Các nguyên nhân có thể

### 1. File được phân loại sai type
- File có thể được phân loại là `.image` hoặc `.video` thay vì `.file`
- Kiểm tra MIME type trong logs

### 2. TimelineController không nhận được file
- File có thể không được lưu vào timeline
- Có thể có vấn đề với pagination

### 3. Lỗi trong việc tạo FileMessageContent
- File có thể không được tạo thành `FileMessageContent` đúng cách
- Có thể có lỗi trong Rust SDK

## Giải pháp

### 1. Nếu file được phân loại sai
- Kiểm tra logic phân loại file trong Rust SDK
- Có thể cần cập nhật MIME type mapping

### 2. Nếu TimelineController không nhận được file
- Kiểm tra pagination logic
- Có thể cần tăng số lượng events được load

### 3. Nếu có lỗi trong FileMessageContent
- Kiểm tra Rust SDK logs
- Có thể cần cập nhật SDK version

## Test cases

Tạo các file test khác nhau:
- ZIP file (.zip) - MIME: application/zip
- PDF file (.pdf) - MIME: application/pdf
- Text file (.txt) - MIME: text/plain
- Image file (.jpg) - MIME: image/jpeg
- Video file (.mp4) - MIME: video/mp4

Kiểm tra xem file nào được phân loại đúng và hiển thị trong Media Browser.

## Rollback

Nếu cần rollback các thay đổi logging:
```bash
git checkout HEAD -- ElementX/Sources/Services/Timeline/TimelineItems/RoomTimelineItemFactory.swift
git checkout HEAD -- ElementX/Sources/Screens/MediaEventsTimelineScreen/MediaEventsTimelineScreenViewModel.swift
git checkout HEAD -- ElementX/Sources/FlowCoordinators/MediaEventsTimelineFlowCoordinator.swift
``` 