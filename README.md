# 🐳 Docker Manager

Универсальный скрипт для установки и управления Docker и Docker Compose на Linux.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)

## 📋 Описание

**Docker Manager** — это интерактивный bash-скрипт, который позволяет:

- 📦 **Установить** Docker Engine и Docker Compose
- 🗑️ **Удалить** Docker с подтверждением
- 🔍 **Проверить** текущую установку
- 🧪 **Протестировать** работоспособность
- ⚙️ **Настроить** (автозапуск, логи, прокси)
- 📊 **Показать статистику** использования Docker

## 🚀 Быстрый старт

### Одна команда (интерактивное меню):
```bash
curl -sSL https://raw.githubusercontent.com/userdimon-dev/docker-manager/main/docker-manager.sh | sudo bash
```

### Установка без меню:
```bash
curl -sSL https://raw.githubusercontent.com/userdimon-dev/docker-manager/main/docker-manager.sh | sudo bash -s -- --install
```

### Скачать и запустить вручную:
```bash
wget https://raw.githubusercontent.com/userdimon-dev/docker-manager/main/docker-manager.sh
chmod +x docker-manager.sh
sudo ./docker-manager.sh
```

## 📦 Поддерживаемые дистрибутивы

| Дистрибутив | Пакетный менеджер | Установка | Удаление |
|-------------|-------------------|-----------|----------|
| **Ubuntu** 20.04+ | `apt` | ✅ | ✅ |
| **Debian** 12+ | `apt` | ✅ | ✅ |
| **CentOS** 7+ | `yum` | ✅ | ✅ |
| **RHEL** 7+ | `yum` | ✅ | ✅ |
| **Fedora** 35+ | `dnf` | ✅ | ✅ |
| **Arch Linux** | `pacman` | ✅ | ✅ |

## 🖥️ Команды

| Команда | Описание |
|---------|----------|
| `sudo ./docker-manager.sh` | Запуск интерактивного меню |
| `sudo ./docker-manager.sh -i` | Установить Docker |
| `sudo ./docker-manager.sh -u` | Удалить Docker |
| `sudo ./docker-manager.sh -c` | Проверить установку |
| `sudo ./docker-manager.sh -t` | Полное тестирование |
| `sudo ./docker-manager.sh -h` | Показать справку |

## 🎮 Интерактивное меню

При запуске без аргументов отображается меню:

```
╔══════════════════════════════════════════════╗
║         🐳 Docker Manager                    ║
║    Установка и управление Docker             ║
╚══════════════════════════════════════════════╝

  Система: Ubuntu 22.04
  ● Docker:    установлен (24.0.7)
  ● Compose:   установлен (2.23.0)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Основные операции
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1) 🐳 Установить Docker
  2) 🗑️  Удалить Docker
  3) 🔍 Проверить установку
  4) 🧪 Полное тестирование
  5) ⚙️  Дополнительные настройки
  6) 📊 Статистика Docker
  0) 🚪 Выход

Выберите действие [0-6]: _
```

## ⚙️ Дополнительные настройки

В пункте меню **5** доступны:

1. **Автозапуск** — Docker будет запускаться при старте системы
2. **Ограничение логов** — максимальный размер логов контейнеров (10MB)
3. **Настройка прокси** — для работы за прокси-сервером

## 🔧 Что делает скрипт

### При установке:
1. Определяет дистрибутив автоматически
2. Добавляет официальный репозиторий Docker
3. Устанавливает Docker Engine (последняя версия)
4. Устанавливает Docker Compose (последняя версия)
5. Добавляет текущего пользователя в группу `docker`
6. Настраивает автозапуск Docker
7. Проверяет работоспособность

### При удалении:
1. Останавливает Docker
2. Удаляет все пакеты Docker
3. Очищает репозитории и ключи
4. Спрашивает про удаление данных (образы, контейнеры)

## 🔒 Безопасность

- Требуются права root (`sudo`)
- Удаление только после явного подтверждения (`yes`)
- Данные Docker удаляются только с согласия
- Русскоязычный интерфейс для удобства

## 📁 Структура проекта

```
docker-manager/
├── docker-manager.sh    # Основной скрипт
├── README.md            # Этот файл
├── LICENSE              # Лицензия MIT
└── .gitignore           # Исключения git
```

## 🔄 Обновление

Для обновления скрипта достаточно загрузить последнюю версию:

```bash
sudo curl -sSL https://raw.githubusercontent.com/userdimon-dev/docker-manager/main/docker-manager.sh -o /tmp/docker-manager.sh
sudo chmod +x /tmp/docker-manager.sh
sudo /tmp/docker-manager.sh
```

## 🐛 Устранение проблем

### Docker не запускается
```bash
sudo systemctl status docker
sudo systemctl restart docker
sudo journalctl -u docker -f
```

### Ошибка прав при использовании Docker
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Конфликт со старыми версиями
```bash
sudo ./docker-manager.sh --uninstall
sudo ./docker-manager.sh --install
```

## 📄 Лицензия

Проект распространяется под лицензией [MIT](LICENSE).

## 📧 Контакты

- GitHub: [userdimon-dev](https://github.com/userdimon-dev)
- Репозиторий: [docker-manager](https://github.com/userdimon-dev/docker-manager)

## ⭐ Поддержать проект

Если скрипт полезен — поставьте ⭐ на GitHub!
```

---

## ШАГ 3: Создайте файл LICENSE

1. Нажмите **Ctrl+N** чтобы создать новый файл
2. Скопируйте и вставьте туда код ниже
3. Нажмите **Ctrl+S** и сохраните файл как `LICENSE`

```text
MIT License

Copyright (c) 2026 userdimon-dev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## ШАГ 4: Создайте файл .gitignore

1. Нажмите **Ctrl+N** чтобы создать новый файл
2. Скопируйте и вставьте туда код ниже
3. Нажмите **Ctrl+S** и сохраните файл как `.gitignore`

```gitignore
# Временные файлы
*.tmp
*.temp
*.log
*.pid
*.lock

# Кэш
.cache/
*.pyc

# Файлы окружения
.env
.env.local

# Мусор
.DS_Store
Thumbs.db
```

---

## ШАГ 5: Заполните docker-manager.sh

1. Откройте файл `docker-manager.sh` в VS Code (он сейчас пустой)
2. Скопируйте весь код скрипта из моего предыдущего ответа (самый первый блок кода)
3. Вставьте его в файл и сохраните (**Ctrl+S**)

---

## ШАГ 6: Опубликуйте все на GitHub

Откройте терминал в VS Code (нажмите **Ctrl+`**) и выполните команды по очереди:

```powershell
# 1. Проверяем, что все файлы на месте
ls

# 2. Добавляем все файлы
git add .

# 3. Проверяем статус
git status

# 4. Коммитим
git commit -m "Добавлены README, LICENSE, .gitignore и полный код скрипта"

# 5. Пушим на GitHub
git push origin master
```

---

## ШАГ 7: Проверьте результат

После выполнения всех команд проверьте репозиторий:

```powershell
gh repo view userdimon-dev/docker-manager