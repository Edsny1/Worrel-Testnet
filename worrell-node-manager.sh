#!/bin/bash

# ==============================================================================
# Worrell Testnet Node Manager (Cosmovisor Integrated)
#   Chain ID : worrell-testnet-1
#   Binary   : worrelld (v0.1.2) via Cosmovisor
#   Repo     : https://github.com/Edsny1/Worrel-Testnet
# ==============================================================================

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Sabitler
readonly CHAIN_ID="worrell-testnet-1"
readonly DENOM="uworrell"
readonly DAEMON_NAME="worrelld"
readonly WORRELL_HOME="$HOME/.worrell"
readonly REPO_URL="https://github.com/worrellchain/worrell.git"
readonly REPO_VERSION="v0.1.2"
readonly GENESIS_URL="https://server-3.itrocket.net/testnet/worrell/genesis.json"
readonly ADDRBOOK_URL="https://server-3.itrocket.net/testnet/worrell/addrbook.json"
readonly SEEDS="3856d067b900fb6d6136c597a631296dd12c84ad@worrell-testnet-seed.itrocket.net:12656"
readonly PEERS="40128ea31b1cfb5d4b24fc9e32ee0c468586c983@worrell-testnet-peer.itrocket.net:12656,754f6a93b484b6486eac888a2fcbf76430152817@65.108.229.19:27006,bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656,34d2f0b735d951a293e0862e9c2afaba8a54100a@93.159.130.41:31656,5222f1c8916513add07e847be033b145f31bdeaf@65.109.85.159:12656"
readonly MIN_GAS_PRICE="0.025uworrell"
readonly FAUCET_URL="http://164.68.98.186:4500"

# Binary konumu
get_binary() {
    if command -v worrelld &>/dev/null; then
        command -v worrelld
    elif [ -f "$HOME/go/bin/worrelld" ]; then
        echo "$HOME/go/bin/worrelld"
    elif [ -f "$WORRELL_HOME/cosmovisor/current/bin/worrelld" ]; then
        echo "$WORRELL_HOME/cosmovisor/current/bin/worrelld"
    else
        echo "worrelld"
    fi
}

# Kayıtlı RPC Portunu getir
get_node_rpc() {
    local port="10"
    if [ -f "$HOME/.bash_profile" ]; then
        local saved_port
        saved_port=$(grep 'WORRELL_PORT=' "$HOME/.bash_profile" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        [ -n "$saved_port" ] && port="$saved_port"
    fi
    echo "tcp://127.0.0.1:${port}657"
}

# Kayıtlı Cüzdan Adresini al
get_saved_address() {
    local addr=""
    if [ -f "$HOME/.bash_profile" ]; then
        addr=$(grep 'WORRELL_WALLET_ADDRESS=' "$HOME/.bash_profile" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
    echo "$addr"
}

print_logo() {
    echo -e "${CYAN}"
    echo " ██████╗ ███████╗██╗  ██╗██╗   ██╗ █████╗ ███╗   ██╗██╗  ██╗"
    echo "██╔═══██╗██╔════╝██║  ██║██║   ██║██╔══██╗████╗  ██║██║ ██╔╝"
    echo "██║   ██║███████╗███████║██║   ██║███████║██╔██╗ ██║█████╔╝ "
    echo "██║   ██║╚════██║██╔══██║╚██╗ ██╔╝██╔══██║██║╚██╗██║██╔═██╗ "
    echo "╚██████╔╝███████║██║  ██║ ╚████╔╝ ██║  ██║██║ ╚████║██║  ██╗"
    echo " ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${WHITE}           Worrell Testnet ($CHAIN_ID) - Node Manager${NC}"
    echo -e "${WHITE}                      Repo: Edsny1/Worrel-Testnet${NC}"
    echo -e "${YELLOW}================================================================${NC}\n"
}

# Go Kurulumu
install_go() {
    local required_ver="1.23.5"
    if command -v go &>/dev/null; then
        local current_ver
        current_ver=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$(printf '%s\n' "$required_ver" "$current_ver" | sort -V | head -n1)" = "$required_ver" ]; then
            echo -e "${GREEN}Mevcut Go sürümü yeterli: v$current_ver${NC}"
            return
        fi
    fi

    echo -e "${BLUE}Go $required_ver kuruluyor...${NC}"
    cd "$HOME"
    wget -q "https://golang.org/dl/go${required_ver}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${required_ver}.linux-amd64.tar.gz"
    rm -f "go${required_ver}.linux-amd64.tar.gz"

    mkdir -p "$HOME/go/bin"
    export GOROOT=/usr/local/go
    export GOPATH="$HOME/go"
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

    if ! grep -q "/usr/local/go/bin" "$HOME/.bash_profile" 2>/dev/null; then
        echo 'export PATH=$PATH:/usr/local/go/bin:~/go/bin' >> "$HOME/.bash_profile"
    fi
}

# Bağımlılıklar
install_dependencies() {
    echo -e "${BLUE}Sistem bağımlılıkları güncelleniyor...${NC}"
    sudo apt update
    sudo apt install -y curl git jq lz4 build-essential make gcc tar wget
}

# Cosmovisor Kurulumu
install_cosmovisor() {
    echo -e "${BLUE}Cosmovisor kontrol ediliyor/kuruluyor...${NC}"
    if ! command -v cosmovisor &>/dev/null; then
        go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
    fi
    echo -e "${GREEN}Cosmovisor hazır: $(cosmovisor version 2>&1 | head -n 1)${NC}"
}

# Snapshot İndirme ve Yükleme
apply_snapshot() {
    clear
    print_logo
    echo -e "${BLUE}ITRocket üzerinden en güncel snapshot kontrol ediliyor...${NC}"
    
    local SNAP_NAME
    SNAP_NAME=$(curl -s https://server-3.itrocket.net/testnet/worrell/ | grep -oE 'worrell_[0-9-]+_[0-9]+_snap\.tar\.lz4' | head -n 1)

    if [ -z "$SNAP_NAME" ]; then
        echo -e "${RED}Snapshot bulunamadı! Lütfen https://server-3.itrocket.net/testnet/worrell/ adresini kontrol edin.${NC}"
        read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
        return 1
    fi

    echo -e "${GREEN}Bulunan Snapshot:${NC} $SNAP_NAME"
    read -p "$(echo -e ${YELLOW}"Snapshot yüklenirken veritabanı sıfırlanacak. Devam edilsin mi? (y/n): "${NC})" confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}İşlem iptal edildi.${NC}"
        sleep 2
        return 0
    fi

    echo -e "${BLUE}Node servisi durduruluyor...${NC}"
    sudo systemctl stop worrelld

    echo -e "${BLUE}Validator imzalama durumu yedekleniyor...${NC}"
    if [ -f "$WORRELL_HOME/data/priv_validator_state.json" ]; then
        cp "$WORRELL_HOME/data/priv_validator_state.json" "$WORRELL_HOME/priv_validator_state.json.backup"
    fi

    echo -e "${BLUE}Eski veritabanı temizleniyor...${NC}"
    rm -rf "$WORRELL_HOME/data"

    echo -e "${BLUE}Snapshot indiriliyor ve açılıyor...${NC}"
    curl -L "https://server-3.itrocket.net/testnet/worrell/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$WORRELL_HOME"

    echo -e "${BLUE}Validator imzalama dosyası geri yükleniyor...${NC}"
    if [ -f "$WORRELL_HOME/priv_validator_state.json.backup" ]; then
        mv "$WORRELL_HOME/priv_validator_state.json.backup" "$WORRELL_HOME/data/priv_validator_state.json"
    fi

    echo -e "${BLUE}Servis yeniden başlatılıyor...${NC}"
    sudo systemctl restart worrelld

    echo -e "${GREEN}\nSnapshot başarıyla yüklendi ve servis başlatıldı!${NC}"
    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Node Kurulumu
install_node() {
    clear
    print_logo

    read -p "$(echo -e ${YELLOW}"Node Moniker isminizi girin: "${NC})" MONIKER
    [ -z "$MONIKER" ] && { echo -e "${RED}Moniker boş olamaz!${NC}"; sleep 2; return; }

    read -p "$(echo -e ${YELLOW}"Port Prefix girin [Varsayılan: 10]: "${NC})" CUSTOM_PORT
    [ -z "$CUSTOM_PORT" ] && CUSTOM_PORT="10"

    install_dependencies
    install_go
    install_cosmovisor
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

    echo -e "${BLUE}Kaynak kod indiriliyor ve derleniyor (${REPO_VERSION})...${NC}"
    cd "$HOME"
    rm -rf worrell
    git clone "$REPO_URL"
    cd worrell
    git checkout "$REPO_VERSION"
    make install

    BIN_PATH=$(get_binary)
    if ! command -v "$BIN_PATH" &>/dev/null; then
        echo -e "${RED}Derleme başarısız! worrelld binary dosyası bulunamadı.${NC}"
        sleep 3
        return
    fi

    echo -e "${BLUE}Cosmovisor klasör yapısı hazırlanıyor...${NC}"
    mkdir -p "$WORRELL_HOME/cosmovisor/genesis/bin"
    mkdir -p "$WORRELL_HOME/cosmovisor/upgrades"
    cp "$BIN_PATH" "$WORRELL_HOME/cosmovisor/genesis/bin/worrelld"

    echo -e "${BLUE}Node yapılandırılıyor...${NC}"
    "$BIN_PATH" init "$MONIKER" --chain-id "$CHAIN_ID" --home "$WORRELL_HOME"

    "$BIN_PATH" config set client chain-id "$CHAIN_ID" --home "$WORRELL_HOME"
    "$BIN_PATH" config set client node "tcp://localhost:${CUSTOM_PORT}657" --home "$WORRELL_HOME"

    echo -e "${BLUE}Genesis ve Addrbook indiriliyor...${NC}"
    wget -qO "$WORRELL_HOME/config/genesis.json" "$GENESIS_URL"
    wget -qO "$WORRELL_HOME/config/addrbook.json" "$ADDRBOOK_URL"

    sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
           -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" "$WORRELL_HOME/config/config.toml"

    sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:8080%:${CUSTOM_PORT}080%g;
s%:9090%:${CUSTOM_PORT}090%g;
s%:9091%:${CUSTOM_PORT}091%g;
s%:8545%:${CUSTOM_PORT}545%g;
s%:8546%:${CUSTOM_PORT}546%g;
s%:6065%:${CUSTOM_PORT}065%g" "$WORRELL_HOME/config/app.toml"

    local ip_addr
    ip_addr=$(curl -4 -s ifconfig.me || wget -4 -qO- ifconfig.me || echo "127.0.0.1")
    sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%^external_address = \"\"%external_address = \"${ip_addr}:${CUSTOM_PORT}656\"%;
s%:26660%:${CUSTOM_PORT}660%g" "$WORRELL_HOME/config/config.toml"

    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" "$WORRELL_HOME/config/app.toml"
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" "$WORRELL_HOME/config/app.toml"
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" "$WORRELL_HOME/config/app.toml"
    sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.025uworrell"|g' "$WORRELL_HOME/config/app.toml"
    sed -i -e "s/prometheus = false/prometheus = true/" "$WORRELL_HOME/config/config.toml"
    sed -i -e "s/^indexer *=.*/indexer = \"null\"/" "$WORRELL_HOME/config/config.toml"

    echo -e "${BLUE}Cosmovisor systemd servisi oluşturuluyor...${NC}"
    sudo tee /etc/systemd/system/worrelld.service > /dev/null <<EOF
[Unit]
Description=Worrell Testnet Node via Cosmovisor
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$WORRELL_HOME
ExecStart=$(which cosmovisor) run start --home $WORRELL_HOME
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
Environment="DAEMON_NAME=worrelld"
Environment="DAEMON_HOME=$WORRELL_HOME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

    sed -i '/WORRELL_PORT/d' "$HOME/.bash_profile" 2>/dev/null
    sed -i '/WORRELL_CHAIN_ID/d' "$HOME/.bash_profile" 2>/dev/null
    sed -i '/WORRELL_MONIKER/d' "$HOME/.bash_profile" 2>/dev/null
    cat <<EOF >> "$HOME/.bash_profile"
export WORRELL_PORT="$CUSTOM_PORT"
export WORRELL_CHAIN_ID="$CHAIN_ID"
export WORRELL_MONIKER="$MONIKER"
EOF

    echo -e "${YELLOW}Snapshot yükleniyor...${NC}"
    local SNAP_NAME
    SNAP_NAME=$(curl -s https://server-3.itrocket.net/testnet/worrell/ | grep -oE 'worrell_[0-9-]+_[0-9]+_snap\.tar\.lz4' | head -n 1)
    if [ -n "$SNAP_NAME" ]; then
        curl -L "https://server-3.itrocket.net/testnet/worrell/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$WORRELL_HOME"
        echo -e "${GREEN}Güncel Snapshot kuruldu: ${SNAP_NAME}${NC}"
    else
        echo -e "${YELLOW}Snapshot bulunamadı, genesis'ten senkronizasyon başlayacak.${NC}"
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable worrelld
    sudo systemctl restart worrelld

    echo -e "${GREEN}\nCosmovisor tabanlı kurulum tamamlandı ve servis başlatıldı!${NC}"
    echo -e "${CYAN}RPC Adresi : ${WHITE}http://127.0.0.1:${CUSTOM_PORT}657${NC}"
    echo -e "${CYAN}Log Takibi : ${WHITE}sudo journalctl -u worrelld -f -o cat${NC}"
    read -p "$(echo -e ${YELLOW}"Devam etmek için Enter'a basın..."${NC})"
}

# Sync Durumu
check_sync_status() {
    clear
    print_logo
    local BIN_PATH=$(get_binary)
    local RPC=$(get_node_rpc)
    echo -e "${BLUE}Sync durumu kontrol ediliyor ($RPC)...${NC}\n"
    "$BIN_PATH" status --home "$WORRELL_HOME" --node "$RPC" 2>&1 | jq '.SyncInfo // .sync_info'
    echo -e "\n${YELLOW}catching_up: false ise node tamamen senkronize olmuştur.${NC}"
    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Cüzdan Oluştur
create_wallet() {
    clear
    print_logo
    local BIN_PATH=$(get_binary)
    read -p "$(echo -e ${YELLOW}"Yeni cüzdan ismi girin (örn: wallet): "${NC})" WNAME
    [ -z "$WNAME" ] && { echo -e "${RED}Cüzdan ismi boş olamaz!${NC}"; sleep 2; return; }

    "$BIN_PATH" keys add "$WNAME" --home "$WORRELL_HOME"
    
    local NEW_ADDR
    NEW_ADDR=$("$BIN_PATH" keys show "$WNAME" -a --home "$WORRELL_HOME" 2>/dev/null)
    if [ -n "$NEW_ADDR" ]; then
        sed -i '/WORRELL_WALLET_ADDRESS/d' "$HOME/.bash_profile" 2>/dev/null
        echo "export WORRELL_WALLET_ADDRESS=\"$NEW_ADDR\"" >> "$HOME/.bash_profile"
        echo -e "\n${GREEN}Cüzdan Adresi Profilinize Kaydedildi:${NC} $NEW_ADDR"
    fi

    echo -e "${RED}\nYukarıdaki Mnemonic kelimelerini güvenli bir yere kaydedin!${NC}"
    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Cüzdan İçe Aktar
import_wallet() {
    clear
    print_logo
    local BIN_PATH=$(get_binary)
    read -p "$(echo -e ${YELLOW}"Cüzdan ismi girin: "${NC})" WNAME
    [ -z "$WNAME" ] && { echo -e "${RED}Cüzdan ismi boş olamaz!${NC}"; sleep 2; return; }

    "$BIN_PATH" keys add "$WNAME" --recover --home "$WORRELL_HOME"
    
    local NEW_ADDR
    NEW_ADDR=$("$BIN_PATH" keys show "$WNAME" -a --home "$WORRELL_HOME" 2>/dev/null)
    if [ -n "$NEW_ADDR" ]; then
        sed -i '/WORRELL_WALLET_ADDRESS/d' "$HOME/.bash_profile" 2>/dev/null
        echo "export WORRELL_WALLET_ADDRESS=\"$NEW_ADDR\"" >> "$HOME/.bash_profile"
        echo -e "\n${GREEN}Cüzdan Adresi Profilinize Kaydedildi:${NC} $NEW_ADDR"
    fi

    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Cüzdanları Listele
list_wallets() {
    clear
    print_logo
    local BIN_PATH=$(get_binary)
    echo -e "${BLUE}Kayıtlı Cüzdanlar ($WORRELL_HOME):${NC}\n"
    "$BIN_PATH" keys list --home "$WORRELL_HOME"
    echo ""
    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Bakiye Sorgulama (Doğrudan Adres ile)
check_balance() {
    clear
    print_logo
    local BIN_PATH=$(get_binary)
    local RPC=$(get_node_rpc)
    local DEFAULT_ADDR=$(get_saved_address)

    if [ -n "$DEFAULT_ADDR" ]; then
        read -p "$(echo -e ${YELLOW}"worrell cüzdan adresinizi girin [Varsayılan: $DEFAULT_ADDR]: "${NC})" ADDR
        [ -z "$ADDR" ] && ADDR="$DEFAULT_ADDR"
    else
        read -p "$(echo -e ${YELLOW}"worrell cüzdan adresinizi girin (worrell1...): "${NC})" ADDR
    fi

    if [ -z "$ADDR" ]; then
        echo -e "${RED}Adres boş bırakılamaz!${NC}"
        sleep 2
        return
    fi

    echo -e "\n${BLUE}Bakiye sorgulanıyor ($ADDR)...${NC}"
    "$BIN_PATH" query bank balances "$ADDR" --home "$WORRELL_HOME" --node "$RPC"
    
    read -p "$(echo -e ${CYAN}"\nDevam etmek için Enter'a basın..."${NC})"
}

# Faucet İsteği (Doğrudan Adres ile)
request_faucet() {
    clear
    print_logo
    local DEFAULT_ADDR=$(get_saved_address)

    if [ -n "$DEFAULT_ADDR" ]; then
        read -p "$(echo -e ${YELLOW}"Faucet talebi için worrell adresinizi girin [Varsayılan: $DEFAULT_ADDR]: "${NC})" ADDR
        [ -z "$ADDR" ] && ADDR="$DEFAULT_ADDR"
    else
        read -p "$(echo -e ${YELLOW}"Faucet talebi için worrell adresinizi girin (worrell1...): "${NC})" ADDR
    fi

    if [ -z "$ADDR" ]; then
        echo -e "${RED}Adres boş bırakılamaz!${NC}"
        sleep 2
        return
    fi

    echo -e "${CYAN}Hedef Adres : ${WHITE}$ADDR${NC}"
    echo -e "${BLUE}Faucet talebi gönderiliyor ($FAUCET_URL)...${NC}\n"
    
    local RESPONSE
    RESPONSE=$(curl -s -X POST "$FAUCET_URL" \
        -H "Content-Type: application/json" \
        -d "{\"address\":\"$ADDR\"}")

    echo -e "${GREEN}Yanıt:${NC} $RESPONSE\n"
    echo -e "${YELLOW}Not: Faucet saatte bir talep edilebilir (500 WORRELL).${NC}"
    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Validator Oluşturma (Doğrudan Adres ile İmzalama)
create_validator() {
    clear
    print_logo
    local BIN_PATH=$(get_binary)
    local RPC=$(get_node_rpc)
    local DEFAULT_ADDR=$(get_saved_address)

    if [ -n "$DEFAULT_ADDR" ]; then
        read -p "İşlemi imzalayacak cüzdan adresi (worrell1...) [Varsayılan: $DEFAULT_ADDR]: " SIGNER_ADDR
        [ -z "$SIGNER_ADDR" ] && SIGNER_ADDR="$DEFAULT_ADDR"
    else
        read -p "İşlemi imzalayacak cüzdan adresi (worrell1...): " SIGNER_ADDR
    fi

    [ -z "$SIGNER_ADDR" ] && { echo -e "${RED}Cüzdan adresi zorunludur!${NC}"; sleep 2; return; }

    read -p "Moniker (Validator Adı): " MONIKER
    read -p "Stake Miktarı (örn: 490000000uworrell): " AMOUNT
    read -p "Identity (Opsiyonel Keybase): " IDENTITY
    read -p "Website (Opsiyonel): " WEBSITE
    read -p "Details (Açıklama): " DETAILS

    [ -z "$MONIKER" ] || [ -z "$AMOUNT" ] && { echo -e "${RED}Moniker ve miktar zorunludur!${NC}"; sleep 2; return; }

    local PUBKEY
    PUBKEY=$("$BIN_PATH" tendermint show-validator --home "$WORRELL_HOME")

    cat <<EOF > "$WORRELL_HOME/validator.json"
{
  "pubkey": ${PUBKEY},
  "amount": "${AMOUNT}",
  "moniker": "${MONIKER}",
  "identity": "${IDENTITY}",
  "website": "${WEBSITE}",
  "security": "",
  "details": "${DETAILS}",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1000000"
}
EOF

    echo -e "\n${CYAN}Oluşturulan validator.json:${NC}"
    cat "$WORRELL_HOME/validator.json"
    echo ""
    read -p "$(echo -e ${YELLOW}"Validator oluşturulsun mu? (y/n): "${NC})" CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        "$BIN_PATH" tx staking create-validator "$WORRELL_HOME/validator.json" \
            --from "$SIGNER_ADDR" \
            --chain-id "$CHAIN_ID" \
            --home "$WORRELL_HOME" \
            --node "$RPC" \
            --gas auto \
            --gas-adjustment 1.5 \
            --gas-prices "$MIN_GAS_PRICE" \
            -y
    fi
    read -p "$(echo -e ${CYAN}"Devam etmek için Enter'a basın..."${NC})"
}

# Node Yönetimi
node_management() {
    while true; do
        clear
        print_logo
        echo -e "${WHITE}1)${NC} Servisi Yeniden Başlat (Restart)"
        echo -e "${WHITE}2)${NC} Servisi Durdur (Stop)"
        echo -e "${WHITE}3)${NC} Servisi Başlat (Start)"
        echo -e "${WHITE}4)${NC} Servis Durumunu Gör (Status)"
        echo -e "${WHITE}5)${NC} ${RED}Node'u Tamamen Sil (Uninstall)${NC}"
        echo -e "${WHITE}0)${NC} Geri Dön"
        echo ""
        read -p "$(echo -e ${YELLOW}"Seçiminiz: "${NC})" opt
        case $opt in
            1) sudo systemctl restart worrelld && echo -e "${GREEN}Yeniden başlatıldı.${NC}"; sleep 2 ;;
            2) sudo systemctl stop worrelld && echo -e "${GREEN}Durduruldu.${NC}"; sleep 2 ;;
            3) sudo systemctl start worrelld && echo -e "${GREEN}Başlatıldı.${NC}"; sleep 2 ;;
            4) sudo systemctl status worrelld; read -p "Devam etmek için Enter..." ;;
            5)
                read -p "$(echo -e ${RED}"Node ve veritabanı tamamen silinsin mi? (y/n): "${NC})" del_confirm
                if [ "$del_confirm" = "y" ] || [ "$del_confirm" = "Y" ]; then
                    sudo systemctl stop worrelld
                    sudo systemctl disable worrelld
                    sudo rm -rf /etc/systemd/system/worrelld.service
                    sudo systemctl daemon-reload
                    local BIN_PATH=$(get_binary)
                    [ -f "$BIN_PATH" ] && sudo rm -f "$BIN_PATH"
                    rm -rf "$WORRELL_HOME"
                    rm -rf "$HOME/worrell"
                    sed -i '/WORRELL_/d' "$HOME/.bash_profile" 2>/dev/null
                    echo -e "${GREEN}Node tamamen temizlendi.${NC}"
                    sleep 2
                    return
                fi
                ;;
            0) return ;;
        esac
    done
}

# Ana Menü
main_menu() {
    while true; do
        clear
        print_logo
        echo -e "${WHITE}1)${NC} Node Kurulumu Yap (Cosmovisor Install)"
        echo -e "${WHITE}2)${NC} Sync Durumunu Kontrol Et (Sync Status)"
        echo -e "${WHITE}3)${NC} Logları Takip Et (View Logs)"
        echo -e "${WHITE}4)${NC} Güncel Snapshot Yükle (Download Snapshot)"
        echo -e "${WHITE}5)${NC} Yeni Cüzdan Oluştur (Create Wallet)"
        echo -e "${WHITE}6)${NC} Cüzdan İçe Aktar (Import Wallet)"
        echo -e "${WHITE}7)${NC} Kayıtlı Cüzdanları Listele (List Wallets)"
        echo -e "${WHITE}8)${NC} Bakiye Sorgula (Check Balance)"
        echo -e "${WHITE}9)${NC} Faucet'ten Token İste (Request Faucet)"
        echo -e "${WHITE}10)${NC} Validator Oluştur (Create Validator)"
        echo -e "${WHITE}11)${NC} Node Servis Yönetimi (Start/Stop/Delete)"
        echo -e "${WHITE}0)${NC} Çıkış"
        echo ""
        read -p "$(echo -e ${YELLOW}"Seçiminiz [0-11]: "${NC})" choice

        case $choice in
            1) install_node ;;
            2) check_sync_status ;;
            3) sudo journalctl -u worrelld -f -o cat ;;
            4) apply_snapshot ;;
            5) create_wallet ;;
            6) import_wallet ;;
            7) list_wallets ;;
            8) check_balance ;;
            9) request_faucet ;;
            10) create_validator ;;
            11) node_management ;;
            0) echo -e "${GREEN}Çıkış yapıldı.${NC}"; exit 0 ;;
            *) echo -e "${RED}Geçersiz seçim!${NC}"; sleep 2 ;;
        esac
    done
}

main_menu
