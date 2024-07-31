#!/bin/bash

# Проверка, установлен ли build-essential
if dpkg-query -W build-essential >/dev/null 2>&1; then
    echo "build-essential уже установлен, пропускаем установку."
else
    echo "Устанавливаем build-essential..."
    sudo apt update
    sudo apt install -y build-essential
fi

# Проверка, установлен ли git
if dpkg-query -W git >/dev/null 2>&1; then
    echo "git уже установлен, пропускаем установку."
else
    echo "Устанавливаем git..."
    sudo apt update
    sudo apt install -y git
fi

# Проверка, установлен ли make
if dpkg-query -W make >/dev/null 2>&1; then
    echo "make уже установлен, пропускаем установку."
else
    echo "Устанавливаем make..."
    sudo apt update
    sudo apt install -y make
fi

# Проверка, установлен ли jq
if dpkg-query -W jq >/dev/null 2>&1; then
    echo "jq уже установлен, пропускаем установку."
else
    echo "Устанавливаем jq..."
    sudo apt update
    sudo apt install -y jq
fi

# Проверка, установлен ли curl
if dpkg-query -W curl >/dev/null 2>&1; then
    echo "curl уже установлен, пропускаем установку."
else
    echo "Устанавливаем curl..."
    sudo apt update
    sudo apt install -y curl
fi

# Проверка, установлен ли clang
if dpkg-query -W clang >/dev/null 2>&1; then
    echo "clang уже установлен, пропускаем установку."
else
    echo "Устанавливаем clang..."
    sudo apt update
    sudo apt install -y clang
fi

# Проверка, установлен ли pkg-config
if dpkg-query -W pkg-config >/dev/null 2>&1; then
    echo "pkg-config уже установлен, пропускаем установку."
else
    echo "Устанавливаем pkg-config..."
    sudo apt update
    sudo apt install -y pkg-config
fi

# Проверка, установлен ли libssl-dev
if dpkg-query -W libssl-dev >/dev/null 2>&1; then
    echo "libssl-dev уже установлен, пропускаем установку."
else
    echo "Устанавливаем libssl-dev..."
    sudo apt update
    sudo apt install -y libssl-dev
fi

# Проверка, установлен ли wget
if dpkg-query -W wget >/dev/null 2>&1; then
    echo "wget уже установлен, пропускаем установку."
else
    echo "Устанавливаем wget..."
    sudo apt update
    sudo apt install -y wget
fi

# Проверка, установлен ли Go
if command -v go >/dev/null 2>&1; then
    echo "Go уже установлен, пропускаем установку."
else
    echo "Скачиваем и устанавливаем Go..."
    wget -c https://golang.org/dl/go1.22.3.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# Проверка установленной версии Go
echo "Текущая версия Go:"
go version

function install_node() {

    if [ -d "/data/airchains/evm-station" ]; then
        rm -rf /data/airchains/evm-station
    fi

    if [ -d "tracks" ]; then
        rm -rf tracks
    fi

    mkdir -p /data/airchains/ && cd /data/airchains/
    git clone https://github.com/airchains-network/evm-station.git
    git clone https://github.com/airchains-network/tracks.git

    cd /data/airchains/evm-station  && go mod tidy

    # Убедитесь, что путь к скрипту верный
    nano ./scripts/local-setup.sh
    /bin/bash ./scripts/local-setup.sh

    # Изменяем адрес json-rpc на 0.0.0.0
    sed -i.bak 's@address = "127.0.0.1:8545"@address = "0.0.0.0:8545"@' ~/.evmosd/config/app.toml
    
    # Вводим новый CHAIN_ID
    read -p "Введите новый CHAIN_ID (по умолчанию: name_1234-1): " CHAIN_ID
    CHAIN_ID=${CHAIN_ID:-name_1234-1}  # Устанавливаем значение по умолчанию

    cat > /etc/systemd/system/evmosd.service << EOF
[Unit]
Description=Узел evmosd
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/.evmosd
ExecStart=/data/airchains/evm-station/build/station-evm start --metrics "" --log_level "info" --json-rpc.api eth,txpool,personal,net,debug,web3 --chain-id "$CHAIN_ID"
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable evmosd
    systemctl restart evmosd

    # Развертываем легкий узел avail
    mkdir /data/airchains/availda && cd /data/airchains/availda
    wget https://github.com/availproject/avail-light/releases/download/v1.9.1/avail-light-linux-amd64.tar.gz
    tar xvf avail-light-linux-amd64.tar.gz
    mv avail-light-linux-amd64 avail-light && chmod +x avail-light

    mkdir -p ~/.avail/turing/bin
    mkdir -p ~/.avail/turing/data
    mkdir -p ~/.avail/turing/config
    mkdir -p ~/.avail/identity

    cat > ~/.avail/turing/config/config.yml << EOF
bootstraps=['/dns/bootnode.1.lightclient.turing.avail.so/tcp/37000/p2p/12D3KooWBkLsNGaD3SpMaRWtAmWVuiZg1afdNSPbtJ8M8r9ArGRT']
full_node_ws=['wss://avail-turing.public.blastapi.io','wss://turing-testnet.avail-rpc.com']
confidence=80.0
avail_path='/root/.avail/turing/data'
kad_record_ttl=43200
ot_collector_endpoint='http://otel.lightclient.turing.avail.so:4317'
genesis_hash='d3d2f3a3495dc597434a99d7d449ebad6616db45e4e4f178f31cc6fa14378b70'
EOF

    cat > /etc/systemd/system/availd.service << EOF
[Unit]
Description=Легкий клиент Avail
After=network.target
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=/data/airchains/availda/avail-light --network "turing" --config /root/.avail/turing/config/config.yml --app-id 36 --identity /root/.avail/identity/identity.toml
Restart=always
RestartSec=30
Environment="DAEMON_HOME=/root/.avail"

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable availd
    systemctl restart availd
    journalctl -u availd | head

    # Развертываем сервис Tracks
    cd /data/airchains/tracks/ && make build

    # Извлекаем публичный ключ
    JOURNALCTL_CMD="journalctl -u availd | grep 'public key'"

    extract_public_key() {
        eval $JOURNALCTL_CMD | awk -F'public key: ' '{print $2}' | head -n 1
    }

    public_key=$(extract_public_key)
    LOCAL_IP=$(hostname -I | awk '{print $1}')

    if [ -n "$public_key" ]; then
        echo "Найден публичный ключ: $public_key"
    else
        echo "Ошибка: не удалось найти публичный ключ в логах availd"
        exit 1
    fi

    /data/airchains/tracks/build/tracks init --daRpc "http://127.0.0.1:7000" --daKey "$public_key" --daType "avail" --moniker "$MONIKER" --stationRpc "http://$LOCAL_IP:8545" --stationAPI "http://$LOCAL_IP:8545" --stationType "evm"
    /data/airchains/tracks/build/tracks keys junction --accountName node --accountPath $HOME/.tracks/junction-accounts/keys
    /data/airchains/tracks/build/tracks prover v1EVM

    grep node_id ~/.tracks/config/sequencer.toml
    sed -i.bak 's/utilis\.GenerateRandomWithFavour(1200, 2400, \[2\]int{1500, 2000}, 0\.7)/utilis.GenerateRandomWithFavour(2400, 3400, [2]int{2600, 3000}, 0.7)/g' ~/tracks/infra/prover/evm.go

    cat > /etc/systemd/system/tracksd.service << EOF
[Unit]
Description=Tracks
After=network.target
StartLimitIntervalSec=0

[Service]
User=root
WorkingDirectory=/root/.tracks
ExecStart=/data/airchains/tracks/build/tracks start --rpcPort 8000 --p2pPort 11000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable tracksd
    systemctl restart tracksd
    journalctl -u tracksd | head
}

# Просмотр логов evmosd
function evmos_log() {
    journalctl -u evmosd -f
}

# Просмотр логов availd
function avail_log() {
    journalctl -u availd -f
}

# Просмотр логов tracksd
function tracks_log() {
    journalctl -u tracksd -f
}

# Получение приватных ключей
function private_key() {
    echo "evmos:"
    jq -r .priv_key ~/.evmosd/config/priv_validator_key.json
    echo "======================"
    echo "avail:"
    jq -r .secret_key ~/.avail/identity/identity.toml
    echo "======================"
    echo "airchain:"
    jq -r .priv_key ~/.tracks/config/priv_validator_key.json
}

# Проверка адреса avail
function check_avail_address() {
    jq -r .address ~/.avail/identity/identity.toml
}

# Перезапуск служб
function restart() {
    systemctl restart evmosd && systemctl restart availd && systemctl restart tracksd
}

# Удаление ноды
function delete_node() {
    systemctl stop evmosd && systemctl stop availd && systemctl stop tracksd
    rm -rf ~/.evmosd && rm -rf ~/.avail && rm -rf ~/.tracks
}

# Главное меню
function main_menu() {
    echo "Выберите действие:"
    echo "1) Установить ноду"
    echo "2) Логи evmos"
    echo "3) Логи avail"
    echo "4) Логи tracks"
    echo "5) Приватный ключ"
    echo "6) Проверить адрес avail"
    echo "7) Перезапустить"
    echo "8) Удалить ноду"
    echo "0) Выйти"

    read -p "Выберите опцию: " choice
    case $choice in
        1)
            install_node
            ;;
        2)
            evmos_log
            ;;
        3)
            avail_log
            ;;
        4)
            tracks_log
            ;;
        5)
            private_key
            ;;
        6)
            check_avail_address
            ;;
        7)
            restart
            ;;
        8)
            delete_node
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Неверный выбор."
            ;;
    esac
}

main_menu
