#!/bin/bash

# ============================================================
# Docker Manager - универсальный скрипт для Linux
# Установка, удаление, проверка Docker и Docker Compose
# ============================================================

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ============================================================
# Функции для вывода сообщений
# ============================================================
print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║         🐳 Docker Manager                    ║"
    echo "║    Установка и управление Docker             ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_menu_title() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_message() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_success() {
    echo -e "${GREEN}"
    echo "✅ $1"
    echo -e "${NC}"
}

# ============================================================
# Проверка прав root
# ============================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен запускаться с правами root (sudo)"
        exit 1
    fi
}

# ============================================================
# Определение дистрибутива
# ============================================================
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_NAME="$PRETTY_NAME"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO_ID="debian"
        DISTRO_NAME="Debian"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO_ID="rhel"
        DISTRO_NAME="RHEL/CentOS"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO_ID="arch"
        DISTRO_NAME="Arch Linux"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown"
    fi
    
    print_info "Система: ${DISTRO_NAME}"
}

# ============================================================
# Проверка текущего статуса Docker
# ============================================================
get_docker_status() {
    if command -v docker &> /dev/null; then
        DOCKER_INSTALLED=true
        DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
    else
        DOCKER_INSTALLED=false
        DOCKER_VERSION=""
    fi
    
    if docker compose version &> /dev/null 2>&1; then
        COMPOSE_INSTALLED=true
        COMPOSE_VERSION=$(docker compose version 2>/dev/null | cut -d' ' -f4)
    else
        COMPOSE_INSTALLED=false
        COMPOSE_VERSION=""
    fi
}

# ============================================================
# Функции установки для разных дистрибутивов
# ============================================================

# Установка на Ubuntu/Debian
install_docker_debian() {
    print_info "Обновление пакетов..."
    apt-get update -qq
    print_info "Установка зависимостей..."
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    print_info "Добавление GPG-ключа Docker..."
    curl -fsSL https://download.docker.com/linux/${DISTRO_ID}/gpg | gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    print_info "Добавление репозитория Docker..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${DISTRO_ID} $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    print_info "Установка Docker Engine..."
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# Установка на RHEL/CentOS/Fedora
install_docker_rhel() {
    print_info "Установка yum-utils..."
    yum install -y yum-utils
    
    print_info "Добавление репозитория Docker..."
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    print_info "Установка Docker Engine..."
    yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    print_info "Запуск Docker..."
    systemctl start docker
    systemctl enable docker
}

# Установка на Arch Linux
install_docker_arch() {
    print_info "Обновление системы..."
    pacman -Sy --noconfirm
    
    print_info "Установка Docker..."
    pacman -S --noconfirm docker docker-compose
    
    print_info "Запуск Docker..."
    systemctl start docker
    systemctl enable docker
}

# ============================================================
# Основная функция установки
# ============================================================
install_docker() {
    print_menu_title "🐳 Установка Docker"
    
    if $DOCKER_INSTALLED; then
        print_warning "Docker уже установлен: версия ${DOCKER_VERSION}"
        read -p "Переустановить? [y/N]: " reinstall
        case ${reinstall:0:1} in
            y|Y)
                print_info "Переустановка..."
                uninstall_docker
                ;;
            *)
                print_warning "Пропускаем установку Docker"
                ;;
        esac
    else
        print_info "Начинаем установку Docker для ${DISTRO_NAME}..."
        
        case $DISTRO_ID in
            ubuntu|debian)
                install_docker_debian
                ;;
            rhel|centos|fedora)
                install_docker_rhel
                ;;
            arch)
                install_docker_arch
                ;;
            *)
                print_error "Автоматическая установка не поддерживается для ${DISTRO_NAME}"
                print_info "Установите Docker вручную: https://docs.docker.com/engine/install/"
                return 1
                ;;
        esac
        
        # Добавляем пользователя в группу docker
        if [[ -n "$SUDO_USER" ]] && id "$SUDO_USER" &>/dev/null; then
            usermod -aG docker "$SUDO_USER"
            print_message "Пользователь ${SUDO_USER} добавлен в группу docker"
            print_warning "Перезайдите в SSH (или выполните 'newgrp docker') для применения"
        fi
        
        print_success "Docker успешно установлен!"
    fi
    
    # Проверяем Docker Compose
    if ! $COMPOSE_INSTALLED; then
        print_info "Устанавливаем Docker Compose..."
        
        if ! docker compose version &> /dev/null 2>&1; then
            # Устанавливаем последнюю версию
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
            
            mkdir -p /usr/local/lib/docker/cli-plugins
            curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose
            chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        fi
        
        print_success "Docker Compose установлен!"
    fi
    
    # Запускаем Docker если есть systemd
    if command -v systemctl &> /dev/null; then
        systemctl start docker 2>/dev/null
        systemctl enable docker 2>/dev/null
    fi
}

# ============================================================
# Функции удаления для разных дистрибутивов
# ============================================================

# Удаление на Ubuntu/Debian
uninstall_docker_debian() {
    print_info "Остановка Docker..."
    systemctl stop docker containerd 2>/dev/null
    
    print_info "Удаление пакетов Docker..."
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
    
    print_info "Удаление старых версий..."
    apt-get purge -y docker docker-engine docker.io docker-doc
    
    print_info "Удаление репозитория..."
    rm -rf /etc/apt/sources.list.d/docker.list
    rm -rf /usr/share/keyrings/docker-archive-keyring.gpg
}

# Удаление на RHEL/CentOS/Fedora
uninstall_docker_rhel() {
    print_info "Остановка Docker..."
    systemctl stop docker containerd 2>/dev/null
    
    print_info "Удаление пакетов Docker..."
    yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
    
    print_info "Удаление старых версий..."
    yum remove -y docker docker-common docker-selinux docker-engine
    
    print_info "Удаление репозитория..."
    rm -rf /etc/yum.repos.d/docker-ce.repo
}

# Удаление на Arch Linux
uninstall_docker_arch() {
    print_info "Остановка Docker..."
    systemctl stop docker containerd 2>/dev/null
    
    print_info "Удаление пакетов Docker..."
    pacman -Rns --noconfirm docker docker-compose
}

# ============================================================
# Основная функция удаления
# ============================================================
uninstall_docker() {
    print_menu_title "🗑️  Удаление Docker"
    
    if ! $DOCKER_INSTALLED; then
        print_warning "Docker не установлен!"
        return 1
    fi
    
    echo -e "${RED}⚠️  ВНИМАНИЕ!${NC}"
    echo -e "${YELLOW}Вы собираетесь удалить Docker. Это действие нельзя отменить!${NC}"
    echo ""
    
    read -p "Удалить Docker? Введите 'yes' для подтверждения: " confirm
    if [[ "$confirm" != "yes" ]]; then
        print_warning "Удаление отменено"
        return 1
    fi
    
    case $DISTRO_ID in
        ubuntu|debian)
            uninstall_docker_debian
            ;;
        rhel|centos|fedora)
            uninstall_docker_rhel
            ;;
        arch)
            uninstall_docker_arch
            ;;
        *)
            print_error "Автоматическое удаление не поддерживается для ${DISTRO_NAME}"
            return 1
            ;;
    esac
    
    # Спрашиваем про данные
    echo ""
    read -p "Удалить все данные Docker (контейнеры, образы, тома)? [y/N]: " data_answer
    case ${data_answer:0:1} in
        y|Y)
            rm -rf /var/lib/docker
            rm -rf /var/lib/containerd
            print_message "Данные Docker удалены"
            ;;
        *)
            print_warning "Данные Docker сохранены"
            ;;
    esac
    
    print_success "Docker успешно удалён!"
}

# ============================================================
# Проверка установки
# ============================================================
check_docker() {
    print_menu_title "🔍 Проверка Docker"
    
    echo ""
    if $DOCKER_INSTALLED; then
        print_message "Docker установлен: ${GREEN}${DOCKER_VERSION}${NC}"
    else
        print_error "Docker не установлен"
    fi
    
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            print_message "Docker daemon запущен"
        else
            print_warning "Docker daemon не запущен"
        fi
    fi
    
    echo ""
    if $COMPOSE_INSTALLED; then
        print_message "Docker Compose установлен: ${GREEN}${COMPOSE_VERSION}${NC}"
    else
        print_warning "Docker Compose не установлен"
    fi
    
    if [[ -n "$SUDO_USER" ]]; then
        if id -nG "$SUDO_USER" 2>/dev/null | grep -qw docker; then
            print_message "Пользователь ${SUDO_USER} в группе docker"
        else
            print_warning "Пользователь ${SUDO_USER} НЕ в группе docker"
            echo ""
            echo -e "${YELLOW}Для добавления:${NC}"
            echo "  sudo usermod -aG docker $SUDO_USER"
            echo "  newgrp docker"
        fi
    fi
    
    if systemctl is-active docker &> /dev/null; then
        print_message "Сервис Docker: активен"
    else
        print_warning "Сервис Docker: не активен"
        print_info "Запустите: systemctl start docker"
    fi
}

# ============================================================
# Полное тестирование
# ============================================================
full_test() {
    print_menu_title "🧪 Полное тестирование"
    
    check_docker
    
    if $DOCKER_INSTALLED; then
        echo ""
        print_info "Запуск тестового контейнера hello-world..."
        if docker run --rm hello-world 2>/dev/null; then
            print_success "Тестовый контейнер: успешно!"
        else
            print_error "Ошибка запуска тестового контейнера"
        fi
    fi
}

# ============================================================
# Настройка Docker для production
# ============================================================
configure_docker() {
    print_menu_title "⚙️  Настройка Docker"
    
    echo "Выберите настройку:"
    echo "1) Автозапуск Docker при старте системы"
    echo "2) Ограничение логов контейнеров"
    echo "3) Настройка прокси (если нужен)"
    echo "4) Вернуться в меню"
    echo ""
    
    read -p "Выберите опцию [1-4]: " config_choice
    
    case $config_choice in
        1)
            echo ""
            print_info "Настройка автозапуска..."
            if command -v systemctl &> /dev/null; then
                systemctl enable docker
                systemctl restart docker
                print_success "Автозапуск Docker настроен!"
            else
                print_warning "systemd не найден"
            fi
            sleep 2
            ;;
        2)
            echo ""
            print_info "Ограничение логов (max 10MB)..."
            mkdir -p /etc/docker
            cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
            systemctl restart docker 2>/dev/null
            print_success "Настройка логов применена!"
            sleep 2
            ;;
        3)
            echo ""
            read -p "Введите HTTP прокси (например http://proxy:8080): " http_proxy
            read -p "Введите HTTPS прокси: " https_proxy
            
            mkdir -p /etc/systemd/system/docker.service.d
            cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=${http_proxy}"
Environment="HTTPS_PROXY=${https_proxy}"
EOF
            systemctl daemon-reload
            systemctl restart docker
            print_success "Прокси настроен!"
            sleep 2
            ;;
        4)
            return 0
            ;;
        *)
            print_error "Неверный выбор"
            sleep 2
            ;;
    esac
}

# ============================================================
# Статистика Docker
# ============================================================
show_stats() {
    print_menu_title "📊 Статистика Docker"
    
    if ! $DOCKER_INSTALLED; then
        print_error "Docker не установлен"
        return 1
    fi
    
    docker system df
    echo ""
    print_info "Контейнеры:"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# ============================================================
# Главное меню
# ============================================================
show_main_menu() {
    while true; do
        get_docker_status
        
        print_header
        print_info "Дистрибутив: ${WHITE}${DISTRO_NAME}${NC}"
        
        if $DOCKER_INSTALLED; then
            echo -e "  ${GREEN}●${NC} Docker:    установлен (${DOCKER_VERSION})"
        else
            echo -e "  ${RED}●${NC} Docker:    не установлен"
        fi
        
        if $COMPOSE_INSTALLED; then
            echo -e "  ${GREEN}●${NC} Compose:   установлен (${COMPOSE_VERSION})"
        else
            echo -e "  ${RED}●${NC} Compose:   не установлен"
        fi
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${WHITE}Основные операции${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🐳 Установить Docker"
        echo -e "  ${GREEN}2)${NC} 🗑️  Удалить Docker"
        echo -e "  ${YELLOW}3)${NC} 🔍 Проверить установку"
        echo -e "  ${YELLOW}4)${NC} 🧪 Полное тестирование"
        echo -e "  ${BLUE}5)${NC} ⚙️  Дополнительные настройки"
        echo -e "  ${BLUE}6)${NC} 📊 Статистика Docker"
        echo -e "  ${RED}0)${NC} 🚪 Выход"
        echo ""
        
        read -p "Выберите действие [0-6]: " choice
        
        case $choice in
            1)
                install_docker
                read -p "Нажмите Enter чтобы продолжить..."
                ;;
            2)
                uninstall_docker
                read -p "Нажмите Enter чтобы продолжить..."
                ;;
            3)
                check_docker
                read -p "Нажмите Enter чтобы продолжить..."
                ;;
            4)
                full_test
                read -p "Нажмите Enter чтобы продолжить..."
                ;;
            5)
                configure_docker
                read -p "Нажмите Enter чтобы продолжить..."
                ;;
            6)
                show_stats
                read -p "Нажмите Enter чтобы продолжить..."
                ;;
            0)
                print_message "До свидания!"
                exit 0
                ;;
            *)
                print_error "Неверный выбор. Попробуйте снова..."
                sleep 2
                ;;
        esac
    done
}

# ============================================================
# Обработка аргументов командной строки
# ============================================================
handle_args() {
    case $1 in
        --install|-i)
            get_docker_status
            install_docker
            exit $?
            ;;
        --uninstall|-u)
            get_docker_status
            uninstall_docker
            exit $?
            ;;
        --check|-c)
            get_docker_status
            check_docker
            exit 0
            ;;
        --test|-t)
            get_docker_status
            full_test
            exit 0
            ;;
        --help|-h)
            print_header
            echo "Использование: $0 [опция]"
            echo ""
            echo "Опции:"
            echo "  -i, --install     Установить Docker и Compose"
            echo "  -u, --uninstall   Удалить Docker"
            echo "  -c, --check       Проверить установку"
            echo "  -t, --test        Полное тестирование"
            echo "  -h, --help        Показать эту справку"
            echo ""
            echo "Без аргументов: интерактивное меню"
            exit 0
            ;;
    esac
}

# ============================================================
# Основная логика
# ============================================================

# Проверяем root права
check_root

# Определяем дистрибутив
detect_distro

# Если есть аргументы - обрабатываем их
if [[ $# -gt 0 ]]; then
    handle_args "$1"
fi

# Запускаем интерактивное меню
show_main_menu