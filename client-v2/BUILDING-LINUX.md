# RuTool 2.1.1 на Linux

RuTool находит Blue Archive, скачивает и устанавливает перевод, восстанавливает
оригинальные файлы. Готовая сборка — AppImage для x86_64 с glibc 2.39 или новее.
Qt и QML-модули уже включены; графические драйверы и сертификаты используются системные.

## Запуск

Скачай AppImage из [релиза 2.1.1](https://github.com/tskitsune/RuTool-Linux/releases/tag/v2.1.1-linux).
Результат локальной сборки находится в `dist-appimage-2.1.1/`:

```sh
chmod +x RuTool-2.1.1-x86_64.AppImage
./RuTool-2.1.1-x86_64.AppImage
```

Если FUSE недоступен:

```sh
./RuTool-2.1.1-x86_64.AppImage --appimage-extract-and-run
```

На NixOS:

```sh
appimage-run ./RuTool-2.1.1-x86_64.AppImage
```

## Сборка AppImage

Нужны Docker и доступ к сети. Из каталога `client-v2`:

```sh
./scripts/build-appimage-container.sh dist-appimage-2.1.1
```

Результат — `dist-appimage-2.1.1/RuTool-2.1.1-x86_64.AppImage` и файл `SHA256SUMS`.
Для повторной сборки укажи новый каталог, например `dist-appimage-rebuild`.

Сценарий собирает клиент с тестами, запускает CTest, затем отдельно собирает
релиз с `BUILD_TESTING=OFF`. После упаковки он проверяет содержимое AppDir,
извлекает готовый AppImage и запускает его интерфейс в offscreen-режиме.
Тесты, фикстуры и файлы разработки в пакет не устанавливаются.

Сборка использует Ubuntu 24.04, GCC 14 и Qt 6.8.3. Qt SDK хранится в
`build-linux-sdk/`, тестовая сборка — в `build-linux-2.1.1-tests/`,
релизная — в `build-appimage-2.1.1/`. Для тестов используется искусственный
`machine-id`; данные системы в пакет не копируются.

Образ Ubuntu закреплён digest, aqtinstall — версией 3.3.0. Версии и SHA-256
инструментов упаковки записаны в `packaging/linux/deployment-tools.lock`.
Версии apt-пакетов и зависимостей aqt не зафиксированы, поэтому результаты
повторных сборок могут отличаться побайтно. Значение `SOURCE_DATE_EPOCH`
по умолчанию — `1767225600`.

На NixOS обработчик binfmt может перехватить запуск AppImage внутри контейнера
и вернуть `ENOENT`. Поэтому скрипт извлекает инструменты через SquashFS и
запускает их содержимое. Исходные файлы инструментов проверяются по SHA-256.

## Проверки

Запуск в новом Ubuntu-контейнере без установленного Qt:

```sh
./scripts/verify-appimage-clean.sh \
  dist-appimage-2.1.1/RuTool-2.1.1-x86_64.AppImage build-linux-validation-2.1.1
```

Лог и снимок окна сохраняются в `build-linux-validation-2.1.1/`.
Проверка использует пустое окружение и временные каталоги настроек.

Быстрая проверка интерфейса без сети и обращения к игре:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./dist-appimage-2.1.1/RuTool-2.1.1-x86_64.AppImage --smoke-test
```

`check-appdir.py` проверяет ELF-зависимости, Qt/QML-модули, плагины, штатную
конфигурацию и отсутствие тестовых файлов. Проверяются и AppDir, и содержимое
готового AppImage. Результаты для версии 2.1.1 — в [отчёте](docs/APPIMAGE-2.1.1-VALIDATION.md).

## Конфигурация и данные

Штатный `installer-keys.json` находится внутри AppImage в `usr/bin/app/config/`
рядом с `update-public.der`. Дополнительная настройка для запуска не нужна.
Свой файл можно положить в `${XDG_CONFIG_HOME:-$HOME/.config}/rutool/installer-keys.json`.
Он имеет приоритет над штатным; при ошибке чтения или неверном формате приложение
покажет ошибку.

Данные хранятся отдельно от AppImage:

* Установочные данные, загрузки и оригинальные копии —
  `${XDG_DATA_HOME:-$HOME/.local/share}/RuToolInstaller/`.
* Локальный ключ — `RuToolInstaller/private/local.key` внутри этого каталога.
  Права файла — `0600`, каталога `private` — `0700`.
* Настройки окна —
  `${XDG_DATA_HOME:-$HOME/.local/share}/RuTool/RuToolInstaller/settings.ini`.

Сохраняй `local.key` вместе с резервными данными: без него нельзя расшифровать
сохранённые коды и журналы восстановления. Зашифрованные данные Windows DPAPI
автоматически не переносятся. Linux использует AES-GCM и формат `RULOC1`.

Для обновления приложения замени AppImage вручную. Кнопка «Обновить форк»
открывает репозиторий Linux-сборки на GitHub.

## Сборка без упаковки

Нужны C++23 со `std::expected`, CMake >=3.25, Ninja и Qt >=6.8 с Core, Gui,
Qml, Quick, QuickControls2, Network, Concurrent. Для тестов нужен Qt Test.
Mbed TLS и zlib находятся в исходниках.

```sh
export CMAKE_PREFIX_PATH=/path/to/Qt/6.8.3/gcc_64
./scripts/build-linux.sh
# Без тестов:
./scripts/build-linux.sh build-release -DBUILD_TESTING=OFF
```

Локальная сборка с Nix SDK зависит от `/nix/store` и не подходит для упаковки
переносимого релиза. Для AppImage используй контейнер или обычный Linux SDK.

Ручная упаковка готовой сборки из обычного Linux SDK:

```sh
./scripts/fetch-appimage-tools.sh build-linux-tools
export QMAKE=/path/to/Qt/6.8.3/gcc_64/bin/qmake
export RUTOOL_TOOLS_DIR="$PWD/build-linux-tools"
./scripts/package-appimage.sh build-release dist-manual
```

## Новое в 2.1.1

Папка игры, ручной выбор `.rut`, восстановление основного перевода и тема
находятся в настройках (кнопка с шестерёнкой). Каталог открывается справа.
Для обновления Linux по-прежнему нужно заменить AppImage вручную.
Windows-обновлятор на Linux не собирается и не запускается.

Русские экраны загрузки — отдельное Premium-дополнение. Нужны действующий
код бусти и поддерживаемый исходный bundle игры. Размер, SHA-256 загрузки,
исходного файла и результата проверяются до замены; применяется формат `RUTD1`.
Произвольные и уже изменённые версии bundle не принимаются.
Оригинал хранится в `RuToolInstaller/Backups/Addons/loading-screens/`.
Кнопка восстановления основного перевода не восстанавливает это дополнение;
отдельного интерфейса восстановления дополнения upstream 2.1.1 не предоставляет.

Сборочный сценарий использует каталоги с номером версии, сохраняя прежние сборки.
Их можно переопределить через `RUTOOL_TEST_BUILD_DIR` и `RUTOOL_RELEASE_BUILD_DIR`
(имена `build-*` без слешей). Для повторной упаковки выбирай новый выходной каталог.

Тесты работают с временными каталогами и синтетическими файлами.
Для пересоздания криптографических фикстур нужен Python с `cryptography >=43`;
для обычного запуска тестов он не требуется.
