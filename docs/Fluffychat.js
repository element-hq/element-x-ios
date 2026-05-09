/*
Copyright 2020 The Matrix.org Foundation C.I.C.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import { Maturity, Platform, LinkKind, FlathubLink, AppleStoreLink, PlayStoreLink, FDroidLink, WebsiteLink } from "../types.js";

/**
 * Information on how to deep link to UC.Meet Chat.
 */
export class Fluffychat {
    get id() { return "org.ucmeet.UCMeetChat"; }
    get name() { return "UC.Meet Chat"; }
    get icon() { return "images/client-icons/ucmeetchat.svg"; }
    get author() { return "UC Matrix"; }
    get homepage() { return "https://ucmatrix.org"; }
    
    get platforms() {
        return [
            Platform.Android, Platform.iOS,
            Platform.Windows, Platform.macOS, Platform.Linux,
            Platform.DesktopWeb,
        ];
    }
    
    get description() { return "Корпоративный мессенджер UC.Meet Chat на базе Matrix."; }
    
    getMaturity(platform) {
        switch (platform) {
            case Platform.Android: return Maturity.Beta;
            case Platform.iOS: return Maturity.Stable;
            case Platform.DesktopWeb: return Maturity.Stable;
            case Platform.Linux: return Maturity.Beta;
            case Platform.macOS: return Maturity.Beta;
            case Platform.Windows: return Maturity.Beta;
        }
    }

    getInstallLinks(platform) {
        switch (platform) {
            case Platform.iOS:
                return [new AppleStoreLink("UC.Meet Chat", "id6759875787")];
            case Platform.Android:
                return [new WebsiteLink("https://ucmatrix.org/download")];
            case Platform.Linux:
                return [new WebsiteLink("https://ucmatrix.org/download")];
            default:
                return [new WebsiteLink("https://ucmatrix.org")];
        }
    }

    getDeepLink(platform, link) {
        // Определяем путь фрагмента в зависимости от типа ссылки
        let fragmentPath;
        switch (link.kind) {
            case LinkKind.User:
                fragmentPath = `@${link.identifier.split(':')[0].replace('@', '')}:${link.identifier.split(':')[1]}`;
                break;
            case LinkKind.Room:
                // Проверяем, является ли идентификатор алиасом (начинается с #)
                if (link.identifier.startsWith('#')) {
                    // Кодируем # в %23 для корректной передачи в URL
                    fragmentPath = `%23${link.identifier.substring(1)}`;
                } else if (link.identifier.startsWith('!')) {
                    // Это room ID
                    fragmentPath = link.identifier;
                } else {
                    // На всякий случай обрабатываем как есть
                    fragmentPath = link.identifier;
                }
                break;
            case LinkKind.Event:
                // Для событий добавляем ID события после идентификатора комнаты
                fragmentPath = `${link.identifier}/${link.eventId}`;
                break;
            case LinkKind.Group:
                fragmentPath = `+${link.identifier}`;
                break;
            default:
                fragmentPath = link.identifier;
        }

        // Добавляем via параметры для комнат и событий
        if ((link.kind === LinkKind.Event || link.kind === LinkKind.Room) && link.servers && link.servers.length > 0) {
            fragmentPath += '?' + link.servers.map(server => `via=${encodeURIComponent(server)}`).join('&');
        }

        switch (platform) {
            case Platform.iOS:
                // Используем основную схему приложения с фрагментом #/
                return `org.ucmeet.UCMeetChat://#/${fragmentPath}`;
            case Platform.Android:
                // Пока возвращаем undefined для Android
                return undefined;
            default:
                return undefined;
        }
    }

    getLinkInstructions(platform, link) {
        if (link.kind === LinkKind.User) {
            switch (platform) {
                case Platform.Android:
                    return;
                case Platform.DesktopWeb:
                    return "Откройте веб-приложение https://ucmatrix.org и войдите в учётную запись. Нажмите '+' и вставьте имя пользователя.";
                default:
                    return "Откройте приложение, нажмите '+' и вставьте имя пользователя.";
            }
        }
        if (link.kind === LinkKind.Room) {
            switch (platform) {
                case Platform.Android:
                    return;
                case Platform.DesktopWeb:
                    return "Откройте веб-приложение https://ucmatrix.org и войдите в учётную запись. Нажмите «Поиск» и вставьте идентификатор комнаты.";
                default:
                    return "Откройте приложение на устройстве. Нажмите «Поиск» и вставьте идентификатор комнаты.";
            }
        }
    }

    getCopyString(platform, link) {
        if (link.kind === LinkKind.User || link.kind === LinkKind.Room) {
            return link.identifier;
        }
    }

    canInterceptMatrixToLinks(platform) {
        return false;
    }

    getPreferredWebInstance(link) {}
}