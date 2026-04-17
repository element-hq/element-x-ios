# UCMeet.Chat — iOS

Мессенджер на базе протокола [Matrix](https://matrix.org/), форк [Element X iOS](https://github.com/element-hq/element-x-ios). Брендированная версия для инфраструктуры UCMeet.

## Основные характеристики

| Параметр | Значение |
|----------|----------|
| Bundle ID | `org.ucmeet.UCMeetChat` |
| Минимальная iOS | 18.0 |
| Язык | Swift, SwiftUI |
| Архитектура | Coordinator + MVVM |
| Ядро | Matrix Rust SDK (бинарный пакет, не модифицируется) |
| Система сборки | XcodeGen + SPM |
| Лицензия | AGPL v3 |

## Требования для разработки

| Инструмент | Версия |
|------------|--------|
| macOS | 15+ (Sequoia) |
| Xcode | 16.2+ |
| XcodeGen | 2.44+ |
| git-lfs | обязателен |

### Установка зависимостей

```bash
# Homebrew (если не установлен)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# XcodeGen и git-lfs
brew install xcodegen git-lfs

# Инициализация git-lfs
git lfs install
```

## Развёртывание проекта

```bash
# 1. Клонировать репозиторий
git clone https://github.com/smurzaliev/ucmeet-chat-ios.git
cd ucmeet-chat-ios

# 2. Скачать LFS-файлы (бинарники Rust SDK)
git lfs pull

# 3. Сгенерировать .xcodeproj
xcodegen generate

# 4. Открыть проект
open ElementX.xcodeproj
```

После открытия Xcode автоматически загрузит SPM-зависимости (первый запуск может занять несколько минут).

## Конфигурация

### Основные файлы конфигурации

| Файл | Назначение |
|------|------------|
| `project.yml` | Версия, номер сборки, глобальные build settings |
| `app.yml` | Bundle ID, Team ID, App Group, display name |
| `ElementX/SupportingFiles/target.yml` | Entitlements, associated domains |
| `ElementX/Sources/Services/Client/AppSettings.swift` | Homeserver, push gateway, OIDC, фичи |
| `ElementX/Sources/Other/Extensions/CompoundHook.swift` | Цветовая тема (акцентный цвет) |
| `ElementX/SupportingFiles/Info.plist` | Разрешения, background modes, экспортное шифрование |
| `GoogleService-Info.plist` | Firebase конфигурация |
| `Secrets/Secrets.swift` | API-ключи (MapTiler, Sentry, PostHog, rageshake) |
| `ElementX/Sources/Assets.xcassets` | Иконка приложения |

### Что заменять при смене окружения

- **Homeserver:** `AppSettings.swift` → `defaultHomeserverAddress`
- **Push gateway:** `AppSettings.swift` → `pusherAppId`, `pushGatewayBaseURL`
- **OIDC callback:** `AppSettings.swift` → OIDC redirect URI
- **Team ID / Bundle ID:** `app.yml`
- **Firebase:** заменить `GoogleService-Info.plist`
- **API-ключи:** `Secrets/Secrets.swift` — MapTiler (`mapLibreAPIKey`), аналитика (Sentry, PostHog — сейчас `nil`)

## Сборка

### Debug (симулятор)

```bash
xcodegen generate
xcodebuild build \
  -scheme ElementX \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug
```

### Release (устройство / архив)

```bash
xcodegen generate
xcodebuild archive \
  -scheme ElementX \
  -archivePath ./build/UCMeetChat.xcarchive \
  -configuration Release \
  -destination 'generic/platform=iOS'
```

Или через Xcode: **Product → Archive**.

### Загрузка в TestFlight

1. В Xcode: **Product → Archive**
2. В Organizer: **Distribute App → App Store Connect**
3. Сборка появится в TestFlight через 10–30 минут после обработки

## Структура проекта

```
├── project.yml                    # XcodeGen: версия, build settings
├── app.yml                        # XcodeGen: Bundle ID, Team ID
├── ElementX/
│   ├── Sources/
│   │   ├── Application/           # AppCoordinator, навигация, роутинг
│   │   ├── Screens/               # Экраны (SwiftUI views + view models)
│   │   ├── Services/              # Бизнес-логика, SDK обёртки
│   │   └── Other/                 # Расширения, утилиты, HTML парсинг
│   ├── SupportingFiles/
│   │   ├── Info.plist
│   │   ├── target.yml             # Entitlements, build settings
│   │   └── Localizable/           # Локализация (en, ru)
│   └── Assets.xcassets            # Иконки, цвета
├── NSE/                           # Notification Service Extension
├── ShareExtension/                # Share Extension
├── UnitTests/                     # Юнит-тесты
└── documentation/                 # Проектная документация
```

## Особенности

### Перманентные ссылки (Permalinks)

Все ссылки на пользователей, чаты и сообщения используют домен `ucmatrix.org` вместо стандартного `matrix.to` (заблокирован в РФ). Замена происходит на уровне приложения через метод `URL.replacingMatrixToHost()`. Входящие ссылки `ucmatrix.org` обрабатываются парсером `UCMatrixPermalinkParser`.

### Push-уведомления

Приложение использует прямые APNs-токены (не Firebase Cloud Messaging). Firebase SDK присутствует в проекте, но push доставляется через Sygnal с типом `apns`. Конфигурация push gateway: `https://push.ucmeet.org`.

### Локализация

Поддерживаются 3 локали: `en`, `en-US`, `ru`. Остальные 34 языка из upstream удалены. Файлы локализации: `ElementX/SupportingFiles/Localizable/`.

### Аналитика

Вся аналитика отключена: PostHog, Sentry, rageshake — значения установлены в `nil` в `AppSettings.swift`.

### Matrix Rust SDK

Ядро приложения — бинарный Swift-пакет Matrix Rust SDK. Его **нельзя модифицировать**. Обновление SDK: изменить версию в `Package.swift` → `xcodegen generate`.

### Карты

Интерактивные карты работают через MapLibre + MapTiler. Статические превью карт требуют платный план MapTiler.

## Доступы и ключи

Учётные данные и ключи передаются отдельно в защищённом виде (не хранятся в репозитории).

### Firebase

| Параметр | Значение |
|----------|----------|
| Проект | `matrix-8c24a` |
| Конфигурация | `GoogleService-Info.plist` (в репозитории) |
| Консоль | [Firebase Console](https://console.firebase.google.com/project/matrix-8c24a) |
| APNs ключ | `.p8` файл загружен в Firebase Console |

### MapTiler

| Параметр | Значение |
|----------|----------|
| API ключ | Указан в `AppSettings.swift` → `mapTilerAPIKey` |
| Консоль | [MapTiler Cloud](https://cloud.maptiler.com/) |
| План | Free (статические превью недоступны) |

### Apple Developer

| Параметр | Значение |
|----------|----------|
| Team ID | `6HRG779SDK` |
| Bundle ID | `org.ucmeet.UCMeetChat` |
| App Group | `group.org.ucmeet` |
| Консоль | [App Store Connect](https://appstoreconnect.apple.com/) |

### Серверная инфраструктура

| Сервис | URL |
|--------|-----|
| Homeserver | `matrix.ucmeet.org` |
| Push Gateway (Sygnal) | `https://push.ucmeet.org` |
| OIDC (MAS) | через `.well-known` на homeserver |
| Element Call | через `.well-known` на homeserver |

## Лицензия

Форк Element X iOS. Лицензия — [AGPL v3](LICENSE).

