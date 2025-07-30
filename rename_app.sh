#!/bin/bash

# Script để đổi tên app từ Element X sang tên mới
# Sử dụng: ./rename_app.sh "Tên App Mới"

if [ $# -eq 0 ]; then
    echo "Sử dụng: $0 \"Tên App Mới\""
    echo "Ví dụ: $0 \"MyChat\""
    exit 1
fi

NEW_APP_NAME="$1"
NEW_APP_NAME_LOWER=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ //g')

echo "Đang đổi tên app từ 'Element X' sang '$NEW_APP_NAME'..."
echo "Tên app viết thường: $NEW_APP_NAME_LOWER"

# Thay thế trong các file cấu hình chính
sed -i '' "s/Element X/$NEW_APP_NAME/g" app.yml
sed -i '' "s/Element/$NEW_APP_NAME/g" app.yml
sed -i '' "s/ElementX/$NEW_APP_NAME/g" project.yml
sed -i '' "s/Element/$NEW_APP_NAME/g" project.yml
sed -i '' "s/Element Swift/$NEW_APP_NAME Swift/g" Package.swift

# Thay thế trong Info.plist
sed -i '' "s/io\.element\.call/io.$NEW_APP_NAME_LOWER.call/g" ElementX/SupportingFiles/Info.plist

# Thay thế trong tất cả các file .strings
find ElementX/Resources/Localizations -name "*.strings" -type f -exec sed -i '' "s/Element X/$NEW_APP_NAME/g" {} \;
find ElementX/Resources/Localizations -name "*.strings" -type f -exec sed -i '' "s/Element/$NEW_APP_NAME/g" {} \;

echo "Hoàn thành! Đã đổi tên app sang '$NEW_APP_NAME'"
echo ""
echo "Lưu ý: Bạn cần:"
echo "1. Chạy 'xcodegen' để tạo lại project"
echo "2. Cập nhật Bundle Identifier trong Xcode"
echo "3. Cập nhật App Group Identifier"
echo "4. Cập nhật URL Schemes"
echo "5. Cập nhật App Icon và Launch Screen" 