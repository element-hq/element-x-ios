# Сообщение заказчику — Диагностика push-уведомлений

**Дата:** 2026-03-18
**Контекст:** Анализ логов ntfy (файл «logs NTFY.rtf») + E2E тест push-уведомлений с реального устройства и симулятора

---

## Текст сообщения

Сергей, здравствуйте!

Спасибо за логи — внимательно их изучил. Также провёл полный E2E тест push-уведомлений: отправил сообщение с симулятора на реальное устройство (iPhone). Результат — уведомление не пришло.

Хорошая новость: вся клиентская часть (iOS-приложение) работает корректно. Проблема полностью на стороне сервера.

### Что подтверждено тестом (работает)

1. **Firebase инициализируется, FCM-токен получен:**
   ```
   FCM registration token updated: d41nFt4-VkdMjRCYR9Mr03:APA91bEg-...
   ```

2. **Pusher зарегистрирован на homeserver — ответ 200 OK:**
   ```
   Set FCM pusher succeeded
   appId: org.ucmeet.UCMeetChat.ios.dev
   url: https://push.ucmeet.org/_matrix/push/v1/notify
   ```
   Synapse принял регистрацию и знает, куда отправлять push-уведомления.

3. **Сообщение успешно отправлено с симулятора:**
   ```
   Sent event in room, event_id="$ItJFHMiIDbFprZaPIYxg_QQpMMt0H_-jggc9FNw4fzE"
   ```

4. **Уведомления включены на устройстве**, звук включён, приложение было свёрнуто.

### Где обрывается цепочка

После отправки сообщения Synapse должен сделать HTTP POST на `https://push.ucmeet.org/_matrix/push/v1/notify` с FCM-токеном устройства. Но в логах ntfy **ни одного такого запроса нет**.

Вся цепочка push-уведомлений:
```
Synapse → push.ucmeet.org (ntfy) → Firebase (FCM) → Apple (APNs) → iPhone
   ✅          ❌ сюда не доходит       не тестировалось
```

### Что показывают логи ntfy

1. **`messages_published=2` не менялся** за всё время логирования — ntfy не обрабатывает новых push-запросов.
2. **В Traefik нет обращений к `push.ucmeet.org`** — трафик к element-call, jitsi-web, element-web есть, а к push gateway — нет.
3. **Логов Synapse в дампе нет** — мы не видим, пытается ли Synapse вообще вызвать gateway.
4. **Ошибок FCM нет** — ntfy даже не доходит до этапа пересылки в Firebase.

### Что нужно проверить (4 команды)

Прошу выполнить на сервере и прислать результат:

**1. Логи Synapse — пытается ли homeserver отправить push?**
```bash
docker logs matrix-synapse 2>&1 | grep -i "push\|pusher\|http_push" | tail -50
```
Это самая важная команда — покажет, видит ли Synapse зарегистрированный pusher и пытается ли отправить уведомление.

**2. Доступность gateway извне:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://push.ucmeet.org/_matrix/push/v1/notify
```
Любой HTTP-ответ (даже 404 или 405) = маршрут работает. Отсутствие ответа = маршрут не настроен.

**3. Маршрут Traefik — направляется ли `push.ucmeet.org` на ntfy?**
```bash
# Проверить через Docker labels
docker inspect matrix-ntfy | grep -i "traefik\|push"

# Или проверить конфиг Traefik
docker exec matrix-traefik cat /etc/traefik/dynamic_conf.yml 2>/dev/null | grep -A 10 -i push
```

**4. Конфигурация ntfy — есть ли Firebase service account JSON?**
```bash
docker exec matrix-ntfy cat /etc/ntfy/server.yml
```
Нас интересует параметр `firebase-key-file` (путь к JSON-файлу сервисного аккаунта Firebase, который я отправлял 11 марта).

### Важный вопрос по архитектуре

ntfy поддерживает Matrix Push Gateway API (`/_matrix/push/v1/notify`), но его основное назначение — UnifiedPush для Android. Для iOS с кастомным Firebase-проектом (как у нас — `matrix-8c24a`) стандартное решение — **Sygnal** (официальный push gateway от Matrix).

**Вопрос:** используется ли на сервере также Sygnal, или только ntfy? Если только ntfy — настроен ли в нём Firebase service account JSON для пересылки уведомлений в FCM?

Если ntfy не поддерживает пересылку в кастомный Firebase-проект, потребуется установить Sygnal. Это Docker-контейнер (`matrixdotorg/sygnal`), конфигурация несложная — я помогу с настройкой.

### Итого — текущий статус

| Компонент | Статус |
|-----------|--------|
| iOS-приложение (код push) | Готово, протестировано |
| Firebase-проект (matrix-8c24a) | Готово |
| APNs-ключ в Firebase Console | Загружен |
| Firebase service account JSON | Отправлен 11.03 |
| FCM-токен на устройстве | Получен |
| Регистрация pusher на homeserver | Работает (200 OK) |
| Отправка сообщений | Работает (event_id получен) |
| Synapse → push.ucmeet.org | **Не работает — запросы не доходят** |
| ntfy → FCM (Firebase) | Не тестировалось (зависит от предыдущего) |
| FCM → APNs → устройство | Не тестировалось |

Жду результаты 4 команд — по ним смогу точно определить, где разрыв: на уровне Synapse, Traefik или ntfy.

С уважением,
Саид

---

*Файл сохранён для истории переписки.*
