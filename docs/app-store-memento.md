# Memento Themes — Выкладка в App Store / TestFlight

## 1. Данные вашего аккаунта разработчика (из проекта AuthorToday)

| Параметр | Значение |
| :--- | :--- |
| **Разработчик** | Кавешников Александр Владимирович (`@dark_tarkhan`) |
| **Team ID (`DEVELOPMENT_TEAM`)** | `57FVB8DUWX` |
| **App Store Connect Issuer ID** | `4178b5af-2d2d-414f-ba80-ce236a4bb048` |
| **App Store Connect Key ID** | `7MA636HK4K` (`C:\Users\fowl_\Downloads\AuthKey_7MA636HK4K.p8`) |
| **Основной Bundle ID** | `ru.theinquisitor.mementothemes` |
| **Виджет Bundle ID** | `ru.theinquisitor.mementothemes.MementoWidget` |
| **App Group** | `group.ru.theinquisitor.mementothemes` |
| **Категория App Store** | `Graphics & Design` / `Lifestyle` |
| **Privacy Policy URL** | `https://at.theinquisitor.ru/chitalnya/privacy.html` |
| **Support URL** | `https://at.theinquisitor.ru/chitalnya/support.html` |
| **URL онлайн-каталога новых тем** | `https://at.theinquisitor.ru/memento/catalog.json` |

---

## 2. Что умеет приложение `MementoThemes`

1. **Вкладка «Студия темы» (`ThemeStudioTabView`):**
   * Интерактивное живое превью с зацикленным видео `live_wallpaper.mp4` (вороны кружат вокруг собора в грозовом небе и клюют тело слева у ограды, фонарь Чумного Доктора мерцает).
   * **Нативный конвертер видео в Apple Live Photo (`LivePhotoCreator.swift`)**: по нажатию одной кнопки «Сохранить Живые обои (Live Photo)» приложение само упаковывает JPEG + QuickTime `.mov` с парой метаданных `ContentIdentifier` (`kCGImagePropertyMakerAppleDictionary[17]` + `com.apple.quicktime.content.identifier`) и сохраняет готовое **Live Photo** прямо в медиатеку iPhone! Никаких сторонних программ вроде `intoLive` больше не нужно.
   * Кнопки сохранения статичных обоев Экрана блокировки (`1290×2796`) и матовых туманных обоев Экрана «Домой» (`1290×2796`).
2. **Вкладка «Иконки и шрифты» (`IconsAndFontsInstallerTabView`):**
   * Сетка из 16 кастомных готических иконок с чекбоксами и переключателем включения 3 готических шрифтов (`Cormorant Unicase Bold`, `Ruslan Display`, `UnifrakturMaguntia`).
   * **Локальный генератор и сервер `.mobileconfig` (`MobileConfigGenerator.swift`)**: собирает профиль прямо на телефоне и поднимает локальный HTTP-сервер (`127.0.0.1:8765/install.mobileconfig`) с MIME-типом `application/x-apple-aspen-config`, чтобы Safari на iPhone сразу вызывал системное окно «Профиль загружен» в 1 тап, либо экспортирует файл `.mobileconfig` в «Файлы».
3. **Вкладка «Каталог тем» (`ThemeCatalogAndImportTabView`):**
   * Поддержка **загрузки будущих тем с сервера** (`https://at.theinquisitor.ru/memento/catalog.json` или по любому URL): скачивает манифест `theme.json`, обои, видео живых обоев, пакет иконок и шрифты новой темы и сохраняет их в локальное хранилище приложения.
   * Встроенный конструктор для создания новых тем прямо на iPhone из своих картинок/видео.
4. **Вкладка «Виджеты» + расширение `MementoWidget`:**
   * Настоящий системный виджет WidgetKit для Экрана блокировки (`accessoryCircular`, `accessoryRectangular`, `accessoryInline`) и Домашнего экрана (`systemSmall`, `systemMedium`) с настраиваемым готическим девизом (`MEMENTO MORI`).

---

## 3. Как добавить новую тему на сервер в будущем

Чтобы любая новая тема автоматически появилась в приложении у всех пользователей без перевыпуска приложения в App Store:
1. Создайте на вашем VPS (`at.theinquisitor.ru`) папку `/var/www/.../memento/themes/<id-темы>/` с файлами `lockscreen.png`, `homescreen.png`, `live_wallpaper.mp4`, папками `icons/` и `fonts/`.
2. Добавьте описание темы в массив `"themes"` внутри файла `catalog.json` (образец лежит в `docs/server-catalog/catalog.json`).
3. Нажмите кнопку обновления каталога в приложении `Memento Темы` — новая тема сразу появится со своей кнопкой «Скачать»!
