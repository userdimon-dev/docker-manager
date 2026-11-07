#!/bin/bash

# ============================================================
# RemnaNode Installer - автоматическая установка ноды Remnawave
# Для работы в связке с панелью управления VPN Remnawave
# Репозиторий: https://github.com/userdimon-dev/docker-manager
# ============================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\133[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\133[1;37m'
NC='\033[0m' # No Color

# Параметры по умолчанию
INSTALL_DIR="/opt/remnanode"
DEFAULT_PORT=2222
NODE_PORT=""
SECRET_KEY=""
PANEL_IP=""
NON_INTERACTIVE=false

# ============================================================
# Функции сообщений
# ============================================================
print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║         🌐 RemnaNode Installer               ║"
    echo "║     Автоматическая установка ноды VPN        ║"
    echo "║          для панели Remnawave                ║"
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
# Проверка и установка Docker
# ============================================================
check_docker() {
    print_info "Проверка наличия Docker и Docker Compose..."
    local need_docker=false
    local need_compose=false

    if ! command -v docker &> /dev/null; then
        need_docker=true
    fi

    if ! docker compose version &> /dev/null 2>&1; then
        need_compose=true
    fi

    if $need_docker || $need_compose; then
        print_warning "Docker или Docker Compose не обнаружен."
        if [ "$NON_INTERACTIVE" = false ]; then
            read -p "Установить Docker автоматически сейчас? [Y/n]: " install_confirm
            install_confirm=${install_confirm:-Y}
            case ${install_confirm:0:1} in
                y|Y)
                    ;;
                *)
                    print_error "Установка отменена. RemnaNode требует установленный Docker."
                    exit 1
                    ;;
            esac
        fi

        print_info "Запуск официальной установки Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
        print_success "Docker успешно установлен!"
    else
        print_message "Docker и Docker Compose уже установлены."
    fi
}

# ============================================================
# Настройка системных параметров ядра (sysctl) для VPN
# ============================================================
tune_network_for_vpn() {
    print_info "Оптимизация параметров ядра Linux для VPN (ip_forward, bbr)..."
    
    mkdir -p /etc/sysctl.d
    cat > /etc/sysctl.d/99-remnanode.conf <<EOF
# Включение пересылки пакетов для VPN
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Увеличение буферов сети
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
EOF

    sysctl -p /etc/sysctl.d/99-remnanode.conf >/dev/null 2>&1 || sysctl --system >/dev/null 2>&1 || true
    print_message "Сетевые параметры ядра оптимизированы (BBR + IP Forwarding)."
}

# ============================================================
# Валидация порта
# ============================================================
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# ============================================================
# Проверка статуса RemnaNode
# ============================================================
show_status() {
    print_header
    print_menu_title "📊 Статус контейнера RemnaNode"

    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
        cd "$INSTALL_DIR"
        echo -e "${WHITE}Директория:${NC} $INSTALL_DIR"
        echo ""
        docker compose ps
        echo ""
        print_info "Последние 15 строк логов:"
        docker compose logs --tail=15
    else
        print_warning "RemnaNode не установлен в $INSTALL_DIR"
    fi
}

# ============================================================
# Удаление RemnaNode
# ============================================================
uninstall_remnanode() {
    print_header
    print_menu_title "🗑️ Удаление RemnaNode"

    if [ ! -d "$INSTALL_DIR" ]; then
        print_warning "Каталог $INSTALL_DIR не найден. Возможно, нода не установлена."
        return 0
    fi

    if [ "$NON_INTERACTIVE" = false ]; then
        read -p "Вы уверены, что хотите остановить и удалить RemnaNode? [y/N]: " confirm
        case ${confirm:0:1} in
            y|Y) ;;
            *)
                print_info "Удаление отменено."
                return 0
                ;;
        esac
    fi

    print_info "Остановка и удаление контейнера..."
    if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
        cd "$INSTALL_DIR"
        docker compose down -v || true
    fi

    print_info "Удаление файлов конфигурации..."
    rm -rf "$INSTALL_DIR"

    print_success "RemnaNode полностью удалён!"
}

# ============================================================
# Настройка файрвола (UFW)
# ============================================================
configure_firewall() {
    local port=$1
    local panel_ip=$2

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        print_info "Обнаружен активный UFW файрвол."
        if [ -n "$panel_ip" ]; then
            ufw allow from "$panel_ip" to any port "$port" proto tcp comment "Remnawave Panel to Node" >/dev/null
            print_success "Порт $port открыт в UFW только для IP панели: $panel_ip"
        else
            if [ "$NON_INTERACTIVE" = false ]; then
                read -p "Открыть порт $port для всех IP? (Рекомендуется ограничить только для панели) [y/N]: " open_all
                case ${open_all:0:1} in
                    y|Y)
                        ufw allow "$port"/tcp comment "Remnawave Node API" >/dev/null
                        print_warning "Порт $port открыт для ВСЕХ IP адресов."
                        ;;
                    *)
                        print_info "Порт не был открыт в UFW. Настройте доступ вручную: ufw allow from <IP_ПАНЕЛИ> to any port $port proto tcp"
                        ;;
                esac
            fi
        fi
    fi
}

# ============================================================
# Основная установка RemnaNode
# ============================================================
install_remnanode() {
    print_header
    print_menu_title "🚀 Установка и настройка RemnaNode"

    check_docker
    tune_network_for_vpn

    # Запрос порта если не передан через CLI
    if [ -z "$NODE_PORT" ]; then
        while true; do
            read -p "Введите Node Port из панели Remnawave [по умолчанию $DEFAULT_PORT]: " input_port
            input_port=${input_port:-$DEFAULT_PORT}
            if validate_port "$input_port"; then
                NODE_PORT=$input_port
                break
            else
                print_error "Некорректный порт: $input_port. Порт должен быть числом от 1 до 65535."
            fi
        done
    else
        if ! validate_port "$NODE_PORT"; then
            print_error "Некорректный порт: $NODE_PORT"
            exit 1
        fi
    fi

    # Запрос Secret Key если не передан через CLI
    if [ -z "$SECRET_KEY" ]; then
        while true; do
            read -p "Вставьте Secret Key из панели Remnawave: " input_key
            # Очистка пробелов и кавычек
            input_key=$(echo "$input_key" | sed -e 's/^[[:space:]"'"'"']*//' -e 's/[[:space:]"'"'"']*$//')
            if [ -n "$input_key" ]; then
                SECRET_KEY=$input_key
                break
            else
                print_error "Secret Key не может быть пустым!"
            fi
        done
    fi

    # Запрос IP панели для фаервола (в интерактивном режиме)
    if [ -z "$PANEL_IP" ] && [ "$NON_INTERACTIVE" = false ]; then
        read -p "Введите IP адрес вашей панели Remnawave (для фаервола, опционально, Enter чтобы пропустить): " input_panel_ip
        PANEL_IP=$(echo "$input_panel_ip" | tr -d ' ')
    fi

    print_info "Подготовка рабочей директории: $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p /var/log/remnanode

    # Создание docker-compose.yml
    print_info "Генерация docker-compose.yml..."
    cat > "$INSTALL_DIR/docker-compose.yml" <<EOF
services:
  remnanode:
    image: remnawave/node:latest
    container_name: remnanode
    hostname: remnanode
    restart: always
    network_mode: host
    environment:
      - NODE_PORT=${NODE_PORT}
      - SECRET_KEY=${SECRET_KEY}
    volumes:
      - /var/log/remnanode:/var/log/remnanode
    logging:
      driver: "json-file"
      options:
        max-size: "15m"
        max-file: "3"
EOF

    # Сохраняем метаданные конфигурации для удобного менеджмента
    cat > "$INSTALL_DIR/.remnanode.env" <<EOF
NODE_PORT=${NODE_PORT}
PANEL_IP=${PANEL_IP}
INSTALLED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
    chmod 600 "$INSTALL_DIR/docker-compose.yml" "$INSTALL_DIR/.remnanode.env"

    # Запуск контейнера
    print_info "Загрузка образа и запуск контейнера remnanode..."
    cd "$INSTALL_DIR"
    docker compose pull
    docker compose up -d

    # Настройка файрвола
    configure_firewall "$NODE_PORT" "$PANEL_IP"

    print_info "Ожидание запуска сервиса (5 сек)..."
    sleep 5

    # Проверка статуса
    if docker ps --format '{{.Names}}' | grep -q "^remnanode$"; then
        print_success "Контейнер RemnaNode успешно запущен!"
        echo ""
        echo -e "${WHITE}Параметры подключения:${NC}"
        echo -e "  ● Node Port:   ${CYAN}${NODE_PORT}${NC}"
        echo -e "  ● Сеть:        ${CYAN}host (доступны все входящие VPN-порты)${NC}"
        echo -e "  ● Каталог:     ${CYAN}${INSTALL_DIR}${NC}"
        echo ""
        print_info "Логи запуска:"
        docker compose logs --tail=15
        echo ""
        print_success "Теперь вернитесь в панель Remnawave и завершите добавление ноды!"
    else
        print_error "Контейнер не запустился. Пожалуйста, проверьте логи:"
        docker compose logs
        return 1
    fi
}

# ============================================================
# Перезапуск контейнера
# ============================================================
restart_remnanode() {
    print_header
    print_menu_title "🔄 Перезапуск RemnaNode"
    if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
        cd "$INSTALL_DIR"
        docker compose down && docker compose up -d
        print_success "RemnaNode перезапущен!"
    else
        print_error "Конфигурация не найдена в $INSTALL_DIR"
    fi
}

# ============================================================
# Обновление контейнера
# ============================================================
update_remnanode() {
    print_header
    print_menu_title "⬆️ Обновление RemnaNode"
    if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
        cd "$INSTALL_DIR"
        print_info "Загрузка свежего образа remnawave/node:latest..."
        docker compose pull
        docker compose up -d
        print_success "RemnaNode успешно обновлён до последней версии!"
    else
        print_error "Конфигурация не найдена в $INSTALL_DIR"
    fi
}

# ============================================================
# Интерактивное меню
# ============================================================
show_menu() {
    while true; do
        print_header
        
        local is_running=false
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^remnanode$"; then
            is_running=true
            echo -e "  Статус RemnaNode: ${GREEN}● Работает${NC}"
        elif [ -d "$INSTALL_DIR" ]; then
            echo -e "  Статус RemnaNode: ${RED}● Остановлен${NC}"
        else
            echo -e "  Статус RemnaNode: ${YELLOW}○ Не установлен${NC}"
        fi
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${WHITE}Действия с RemnaNode${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🚀 Установить / Переустановить RemnaNode"
        echo -e "  ${BLUE}2)${NC} 📊 Статус и логи контейнера"
        echo -e "  ${YELLOW}3)${NC} 🔄 Перезапустить RemnaNode"
        echo -e "  ${CYAN}4)${NC} ⬆️  Обновить образ до последней версии"
        echo -e "  ${RED}5)${NC} 🗑️  Удалить RemnaNode с сервера"
        echo -e "  ${RED}0)${NC} 🚪 Выход"
        echo ""

        read -p "Выберите действие [0-5]: " choice
        case $choice in
            1)
                install_remnanode
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                show_status
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                restart_remnanode
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                update_remnanode
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                uninstall_remnanode
                read -p "Нажмите Enter для продолжения..."
                ;;
            0)
                exit 0
                ;;
            *)
                print_error "Неверный выбор"
                sleep 1
                ;;
        esac
    done
}

# ============================================================
# Парсинг аргументов CLI
# ============================================================
usage() {
    print_header
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции установки:"
    echo "  -k, --key KEY        Secret Key из панели Remnawave (обязательно для неинтерактивного режима)"
    echo "  -p, --port PORT      Порт ноды (по умолчанию: 2222)"
    echo "  --panel-ip IP        IP-адрес панели Remnawave (для настройки правил UFW)"
    echo "  -d, --dir DIR        Директория установки (по умолчанию: /opt/remnanode)"
    echo "  -y, --yes            Не задавать вопросов (неинтерактивный режим)"
    echo ""
    echo "Опции управления:"
    echo "  --status             Показать статус и последние логи"
    echo "  --logs               Показать логи в реальном времени"
    echo "  --restart            Перезапустить контейнер"
    echo "  --update             Обновить образ ноды"
    echo "  --uninstall          Удалить RemnaNode"
    echo "  -h, --help           Показать эту справку"
    echo ""
    echo "Пример быстрой установки:"
    echo "  sudo $0 -k \"YOUR_SECRET_KEY\" -p 2222 --panel-ip 1.2.3.4"
    exit 0
}

# Проверяем root
check_root

# Парсинг флагов
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--key)
            SECRET_KEY="$2"
            shift 2
            ;;
        -p|--port)
            NODE_PORT="$2"
            shift 2
            ;;
        --panel-ip)
            PANEL_IP="$2"
            shift 2
            ;;
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -y|--yes)
            NON_INTERACTIVE=true
            shift
            ;;
        --status)
            show_status
            exit 0
            ;;
        --logs)
            if [ -d "$INSTALL_DIR" ]; then
                cd "$INSTALL_DIR"
                docker compose logs -f
            else
                print_error "Каталог $INSTALL_DIR не существует."
            fi
            exit 0
            ;;
        --restart)
            restart_remnanode
            exit 0
            ;;
        --update)
            update_remnanode
            exit 0
            ;;
        --uninstall)
            uninstall_remnanode
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Неизвестный аргумент: $1"
            usage
            ;;
    esac
done

# Если передан ключ или флаг -y, запускаем установку напрямую
if [ -n "$SECRET_KEY" ] || [ "$NON_INTERACTIVE" = true ]; then
    install_remnanode
    exit 0
fi

# Иначе открываем интерактивное меню
show_menu