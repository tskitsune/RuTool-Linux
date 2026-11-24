# Основные файлы Linux-порта

| Задача | Файлы |
| --- | --- |
| Выбор платформы и сборка | `CMakeLists.txt`, `CMakePresets.json`, `crypto/CMakeLists.txt` |
| Файловые операции, процессы и локальное шифрование | `src/platform/linux/` |
| Поиск Steam/Proton | `src/platform/linux/GameDiscovery.cpp` |
| Штатная конфигурация и XDG override | `src/core/InstallerConfig.cpp` |
| Установка и контроллер | `src/core/Installation.cpp`, `src/app/Client*.cpp` |
| Дополнение 2.1.1 и генератор дельт | `src/core/Installation.cpp`, `src/app/ClientPremium.cpp`, `src/network/Premium.cpp`, `scripts/build-addon-delta.py` |
| Сборка клиента и тестов | `scripts/build-linux.sh` |
| Сборка AppImage в Docker | `scripts/build-appimage-container.sh`, `packaging/linux/Dockerfile` |
| Упаковка и проверка содержимого | `scripts/package-appimage.sh`, `scripts/check-appdir.py`, `scripts/extract-appimage.py` |
| Инструменты упаковки и SHA-256 | `scripts/fetch-appimage-tools.sh`, `packaging/linux/deployment-tools.lock` |
| Запуск без установленного Qt | `scripts/verify-appimage-clean.sh` |
| Launcher, ярлык и значок | `packaging/linux/AppRun`, `rutool.desktop`, `rutool.svg` |
| Автотесты и фикстуры | `tests/linux/` |

[Сборка и запуск](../BUILDING-LINUX.md) · [Устройство порта](LINUX-AUDIT.md) · [Проверки AppImage](APPIMAGE-2.1.1-VALIDATION.md)
