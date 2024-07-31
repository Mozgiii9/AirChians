#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

# Функция для отображения логотипа
display_logo() {
  echo -e '\e[40m\e[32m'
  echo -e '███╗   ██╗ ██████╗ ██████╗ ███████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗ '
  echo -e '████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗'
  echo -e '██╔██╗ ██║██║   ██║██║  ██║█████╗  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝'
  echo -e '██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗'
  echo -e '██║ ╚████║╚██████╔╝██████╔╝███████╗██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║'
  echo -e '╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝'
  echo -e '\e[0m'
  echo -e "\nПодписаться на канал may.crypto{🦅} чтобы быть в курсе самых актуальных нод - https://t.me/maycrypto\n"
}

display_logo

# Функция для основного меню
main_menu() {
  while true; do
    echo -e "\nМЕНЮ СКРИПТА:\n"
    echo "1. Установить ноду Airchains"
    echo "2. Проверить синхронизацию ноды Airchains"
    echo "3. Создать кошелек"
    echo "4. Импортировать кошелек"
    echo "5. Проверить баланс кошелька"
    echo "6. Создать валидатора Airchains"
    echo "7. Проверить логи"
    echo "8. Покинуть меню скрипта"
    echo
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        install_airchains_node
        ;;
      2)
        check_sync
        ;;
      3)
        create_wallet
        ;;
      4)
        import_wallet
        ;;
      5)
        check_balance
        ;;
      6)
        create_validator
        ;;
      7)
        check_logs
        ;;
      8)
        echo "Выход из меню скрипта."
        exit 0
        ;;
      *)
        echo "Неверный выбор. Пожалуйста, выберите пункт из меню."
        ;;
    esac
  done
}

# Функция для установки ноды Airchains
install_airchains_node() {
  read -p "Создайте имя кошелька: " WALLET
  echo 'export WALLET='$WALLET
  read -p "Создайте имя ноды(MONIKER): " MONIKER
  echo 'export MONIKER='$MONIKER
  read -p "Введите порт, котором будет работать нода (например 17, по умолчанию порт=26): " PORT
  echo 'export PORT='$PORT

  # Установка переменных
  echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
  echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
  echo "export AIRCHAIN_CHAIN_ID="junction"" >> $HOME/.bash_profile
  echo "export AIRCHAIN_PORT="$PORT"" >> $HOME/.bash_profile
  source $HOME/.bash_profile

  printLine
  echo -e "MONIKER:        \e[1m\e[32m$MONIKER\e[0m"
  echo -e "Кошелек:         \e[1m\e[32m$WALLET\e[0m"
  echo -e "Chain ID:       \e[1m\e[32m$AIRCHAIN_CHAIN_ID\e[0m"
  echo -e "PORT:  \e[1m\e[32m$AIRCHAIN_PORT\e[0m"
  printLine
  sleep 1

  printGreen "1. Установка go..." && sleep 1
  # Установка go, если необходимо
  cd $HOME
  VER="1.21.6"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source $HOME/.bash_profile
  [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

  echo $(go version) && sleep 1

  source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

  printGreen "4. Установка бинарного файла..." && sleep 1
  # Загрузка бинарного файла
  cd $HOME
  wget -O junctiond https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond
  chmod +x junctiond
  mv junctiond $HOME/go/bin/

  printGreen "5. Настройка и инициализация приложения..." && sleep 1
  # Настройка и инициализация приложения
  junctiond init $MONIKER --chain-id $AIRCHAIN_CHAIN_ID 
  sed -i -e "s|^node *=.*|node = \"tcp://localhost:${AIRCHAIN_PORT}657\"|" $HOME/.junction/config/client.toml
  sleep 1
  echo готово

  printGreen "6. Загрузка genesis и addrbook..." && sleep 1
  # Загрузка genesis и addrbook
  wget -O $HOME/.junction/config/genesis.json https://server-4.itrocket.net/testnet/airchains/genesis.json
  wget -O $HOME/.junction/config/addrbook.json  https://server-4.itrocket.net/testnet/airchains/addrbook.json
  sleep 1
  echo готово

  printGreen "7. Добавление seeds, peers, настройка пользовательских портов, обрезка, минимальная цена газа..." && sleep 1
  # Настройка seeds и peers
  SEEDS="04e2fdd6ec8f23729f24245171eaceae5219aa91@airchains-testnet-seed.itrocket.net:19656"
  PEERS="e929f77cfe4cd7d51433f438d3b764937e799313@airchains-testnet-peer.itrocket.net:19656,999a234d17ef264cdccad3dbbe489404270452c1@65.108.126.173:26656,575e98598e9813a26576759c7ef70fd38d2516a4@65.109.113.251:15656,2f17d7cffd83c2e3a0dab853d11092aca1c73e99@49.12.126.32:43456,de2e7251667dee5de5eed98e54a58749fadd23d8@34.77.82.65:26656,36ed02b04e84fb0ba6382d8d1cd2dbe3195a235b@37.27.64.237:10156,d1c949abeb7805546eca0b5e60c4889649760b9c@65.108.121.227:13356,dc189095edccb7af8d8c88cd5b9a3ccd25be1115@65.21.215.142:63656,228e8e13105f6701b2f640eb2d27d14403060df2@64.44.171.196:26656,f2f47fefc40d2311e5578730d95a06ce2f3b7ee7@185.232.70.33:26656,5880ddf4518b061c111ae6bf07b1ef76ef9ed284@65.109.93.58:55656,12d5f5427c99a1625172e3f71440d098e1c8fd7e@51.159.161.79:36656,c8ec06c59bd114d23668dd1a9b13e46481f79f3d@5.189.166.225:26656,cff1962f68db9c2c4c32a5c9c19c0ffed23e72f1@65.109.93.59:31656"
  sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $HOME/.junction/config/config.toml
  sed -i.bak -e "s/^persistent_peers =.*/persistent_peers = \"$PEERS\"/" $HOME/.junction/config/config.toml

  # Настройка портов
  sed -i.bak -e "s%:26658%:${AIRCHAIN_PORT}658%g;
  s%:26657%:${AIRCHAIN_PORT}657%g;
  s%:6060%:${AIRCHAIN_PORT}060%g;
  s%:26656%:${AIRCHAIN_PORT}656%g;
  s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${AIRCHAIN_PORT}656\"%;
  s%:26660%:${AIRCHAIN_PORT}660%g" $HOME/.junction/config/config.toml

  # Настройка обрезки
  sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.junction/config/app.toml
  sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.junction/config/app.toml
  sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.junction/config/app.toml

  # Установка минимальной цены газа, включение prometheus и отключение индексирования
  sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.001amf"|g' $HOME/.junction/config/app.toml
  sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.junction/config/config.toml
  sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.junction/config/config.toml
  sleep 1
  echo готово

  # Создание файла сервиса
  sudo tee /etc/systemd/system/junctiond.service > /dev/null <<EOF
[Unit]
Description=Узел airchains
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.junction
ExecStart=$(which junctiond) start --home $HOME/.junction
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

  printGreen "8. Загрузка Snapshot'a и запуск узла..." && sleep 1
  # Сброс и загрузка снепшота
  junctiond tendermint unsafe-reset-all --home $HOME/.junction
  if curl -s --head curl https://snapshots-testnet.nodejumper.io/airchains-testnet/airchains-testnet_latest.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
    curl https://snapshots-testnet.nodejumper.io/airchains-testnet/airchains-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.junction
  else
    echo "Snapshot не найден"
  fi
  
  # Включение и запуск сервиса
  sudo systemctl daemon-reload
  sudo systemctl enable junctiond
  sudo systemctl restart junctiond

  echo "Установка завершена. Возвращение в меню..."
  sleep 2
  main_menu
}

# Функция для проверки синхронизации ноды
check_sync() {
  junctiond status 2>&1 | jq
  echo "Можно продолжить установку когда 'catching_up' станет 'false'."
  sleep 2
  main_menu
}

# Функция для создания кошелька
create_wallet() {
  read -p "Введите имя кошелька: " WALLET
  junctiond keys add $WALLET

  WALLET_ADDRESS=$(junctiond keys show $WALLET -a)
  VALOPER_ADDRESS=$(junctiond keys show $WALLET --bech val -a)
  echo "export WALLET_ADDRESS="$WALLET_ADDRESS >> $HOME/.bash_profile
  echo "export VALOPER_ADDRESS="$VALOPER_ADDRESS >> $HOME/.bash_profile
  source $HOME/.bash_profile

  echo "Сохраните данные от кошелька в надежное место!"
  sleep 2
  main_menu
}

# Функция для импорта кошелька
import_wallet() {
  read -p "Введите имя кошелька: " WALLET
  junctiond keys add $WALLET --recover

  WALLET_ADDRESS=$(junctiond keys show $WALLET -a)
  VALOPER_ADDRESS=$(junctiond keys show $WALLET --bech val -a)
  echo "export WALLET_ADDRESS="$WALLET_ADDRESS >> $HOME/.bash_profile
  echo "export VALOPER_ADDRESS="$VALOPER_ADDRESS >> $HOME/.bash_profile
  source $HOME/.bash_profile

  echo "Кошелек успешно импортирован."
  sleep 2
  main_menu
}

# Функция для проверки баланса кошелька
check_balance() {
  junctiond query bank balances $WALLET_ADDRESS
  sleep 2
  main_menu
}

# Функция для создания валидатора
create_validator() {
  cd $HOME
  # Создание файла validator.json
  echo "{\"pubkey\":{\"@type\":\"/cosmos.crypto.ed25519.PubKey\",\"key\":\"$(junctiond comet show-validator | grep -Po '\"key\":\s*\"\K[^"]*')\"},
    \"amount\": \"1000000amf\",
    \"moniker\": \"NodeRunner\",
    \"identity\": \"\",
    \"website\": \"\",
    \"security\": \"\",
    \"details\": \"NodeRunner Member 2024\",
    \"commission-rate\": \"0.1\",
    \"commission-max-rate\": \"0.2\",
    \"commission-max-change-rate\": \"0.01\",
    \"min-self-delegation\": \"1\"
  }" > validator.json

  # Создание валидатора с использованием JSON-конфигурации
  junctiond tx staking create-validator validator.json \
      --from $WALLET \
      --chain-id junction \
      --fees 200amf

  echo "Валидатор успешно создан!"
  sleep 2
  main_menu
}

# Функция для проверки логов
check_logs() {
  echo "Через 10 секунд начнется отображение логов ноды Airchains... для выхода из меню нажмите CTRL+C"
  sleep 10
  junctiond status 2>&1 | jq
}

# Запуск основного меню
main_menu
