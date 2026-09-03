#!/bin/bash

# ==============================================================================
# Worrell Testnet Node Manager
#   Chain ID : worrell-testnet-1
#   Binary   : worrelld (Cosmos SDK v0.53.6)
#   Source   : https://github.com/worrellchain/worrell @ v0.1.2
#   Networks : https://github.com/worrellchain/networks
#   Repo     : https://github.com/Edsny1/Worrel-Testnet
# ==============================================================================

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Chain sabitleri (Tamamı izole ve sabittir)
readonly CHAIN_ID="worrell-testnet-1"
readonly DENOM="uworrell"
readonly DAEMON_NAME="worrelld"
readonly WORRELL_HOME="$HOME/.worrell"
WORRELL_REPO="worrellchain/worrell"
WORRELL_VERSION="v0.1.2"
NETWORKS_RAW="https://raw.githubusercontent.com/worrellchain/networks/main/worrell-testnet-1"
GENESIS_SHA256="a81c507b12ba0678c3172394ff4bb03e1c3db60050cc5568c127a24ec19378fd"
PERSISTENT_PEER="bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656"
MIN_GAS_PRICE="0.025uworrell"
FAUCET_URL="http://164.68.98.186:4500"
REQUIRED_GO_VERSION="1.23.5"

# Mevcut portu oku veya varsayılan 10 ata
get_node_rpc() {
    local port="10"
    if [ -f "$HOME/.bash_profile" ]; then
        local saved_port
        saved_port=$(grep 'WORRELL_PORT=' "$HOME/.bash_profile" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        [ -n "$saved_port" ] && port="$saved_port"
    fi
    echo "tcp://127.0.0.1:${port}657"
}

# ASCII Art
print_logo() {
    echo -e "${CYAN}"
    echo " __          __                          _ _ "
    echo " \ \        / /                         | | |"
    echo "  \ \  /\  / /__  _ __ _ __ ___| | |"
    echo "   \ \/  \/ / _ \| '__| '__/ _ \ | |"
    echo "    \  /\  / (_) | |  | | |  __/ | |"
    echo "     \/  \/ \___/|_|  |_|  \___|_|_|"
    echo -e "${NC}"
    echo
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${WHITE}       Worrell Testnet (worrell-testnet-1) Node Manager${NC}"
    echo -e "${WHITE}                  Repo: Edsny1/Worrel-Testnet${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo
}

# Dil seçimi
select_language() {
    clear
    print_logo
    echo -e "${CYAN}Select Language / Dil Seçin:${NC}"
    echo -e "${WHITE}1)${NC} English"
    echo -e "${WHITE}2)${NC} Türkçe"
    echo
    read -p "$(echo -e ${YELLOW}"Enter your choice / Seçiminizi yapın [1-2]: "${NC})" lang_choice

    case $lang_choice in
        1) LANG_SEL="EN" ;;
        2) LANG_SEL="TR" ;;
        *) LANG_SEL="EN" ;;
    esac
}

# Metin çevirileri
get_text() {
    case $1 in
        "main_menu")
            [ "$LANG_SEL" = "TR" ] && echo "ANA MENÜ" || echo "MAIN MENU"
            ;;
        "install")
            [ "$LANG_SEL" = "TR" ] && echo "Kurulum Yap" || echo "Install Node"
            ;;
        "check_sync")
            [ "$LANG_SEL" = "TR" ] && echo "Sync Durumu Kontrol Et" || echo "Check Sync Status"
            ;;
        "view_logs")
            [ "$LANG_SEL" = "TR" ] && echo "Logları Görüntüle" || echo "View Logs"
            ;;
        "create_wallet")
            [ "$LANG_SEL" = "TR" ] && echo "Cüzdan Oluştur" || echo "Create Wallet"
            ;;
        "import_wallet")
            [ "$LANG_SEL" = "TR" ] && echo "Cüzdan İçe Aktar" || echo "Import Wallet"
            ;;
        "create_validator")
            [ "$LANG_SEL" = "TR" ] && echo "Validator Oluştur" || echo "Create Validator"
            ;;
        "delegate")
            [ "$LANG_SEL" = "TR" ] && echo "Token Delege Et" || echo "Delegate Tokens"
            ;;
        "send_tokens")
            [ "$LANG_SEL" = "TR" ] && echo "Token Gönder" || echo "Send Tokens"
            ;;
        "check_balance")
            [ "$LANG_SEL" = "TR" ] && echo "Bakiye Kontrol Et" || echo "Check Balance"
            ;;
        "request_faucet")
            [ "$LANG_SEL" = "TR" ] && echo "Faucet'ten Token İste" || echo "Request Faucet Tokens"
            ;;
        "node_management")
            [ "$LANG_SEL" = "TR" ] && echo "Node Yönetimi" || echo "Node Management"
            ;;
        "restart_node")
            [ "$LANG_SEL" = "TR" ] && echo "Node'u Yeniden Başlat" || echo "Restart Node"
            ;;
        "stop_node")
            [ "$LANG_SEL" = "TR" ] && echo "Node'u Durdur" || echo "Stop Node"
            ;;
        "start_node")
            [ "$LANG_SEL" = "TR" ] && echo "Node'u Başlat" || echo "Start Node"
            ;;
        "node_status")
            [ "$LANG_SEL" = "TR" ] && echo "Node Durumu" || echo "Node Status"
            ;;
        "delete_node")
            [ "$LANG_SEL" = "TR" ] && echo "Node'u Sil" || echo "Delete Node"
            ;;
        "back")
            [ "$LANG_SEL" = "TR" ] && echo "Geri" || echo "Back"
            ;;
        "exit")
            [ "$LANG_SEL" = "TR" ] && echo "Çıkış" || echo "Exit"
            ;;
        "press_enter")
            [ "$LANG_SEL" = "TR" ] && echo "Devam etmek için Enter'a basın..." || echo "Press Enter to continue..."
            ;;
        "enter_moniker")
            [ "$LANG_SEL" = "TR" ] && echo "Node isminizi girin (moniker)" || echo "Enter your node name (moniker)"
            ;;
        "enter_wallet")
            [ "$LANG_SEL" = "TR" ] && echo "Cüzdan isminizi girin" || echo "Enter your wallet name"
            ;;
        "enter_port")
            [ "$LANG_SEL" = "TR" ] && echo "Port prefix girin (örn: 10, 26, 45)" || echo "Enter port prefix (e.g: 10, 26, 45)"
            ;;
        "installation_complete")
            [ "$LANG_SEL" = "TR" ] && echo "Kurulum tamamlandı!" || echo "Installation completed!"
            ;;
        "go_version_check")
            [ "$LANG_SEL" = "TR" ] && echo "Go versiyonu kontrol ediliyor..." || echo "Checking Go version..."
            ;;
    esac
}

# Go versiyon kontrolü ve kurulumu
install_go() {
    echo -e "${BLUE}$(get_text go_version_check)${NC}"

    if command -v go &> /dev/null; then
        CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        echo -e "${YELLOW}Mevcut Go versiyonu: $CURRENT_VERSION${NC}"

        if [ "$(printf '%s\n' "$REQUIRED_GO_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$REQUIRED_GO_VERSION" ]; then
            echo -e "${GREEN}Go versiyonu uygun. Kurulum atlanıyor (mevcut kurulum korunuyor).${NC}"
            return
        else
            echo -e "${YELLOW}Kurulu Go sürümü gereken minimum sürümün altında, güncelleniyor...${NC}"
        fi
    fi

    echo -e "${YELLOW}Go $REQUIRED_GO_VERSION kuruluyor...${NC}"

    rm -rf $HOME/go
    sudo rm -rf /usr/local/go
    cd $HOME
    curl https://dl.google.com/go/go${REQUIRED_GO_VERSION}.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf -

    if ! grep -q "GOROOT=/usr/local/go" $HOME/.profile 2>/dev/null; then
        cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
    fi

    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    echo -e "${GREEN}Go $(go version) kuruldu.${NC}"
}

# Bağımlılıkları yükle
install_dependencies() {
    echo -e "${BLUE}Sistem bağımlılıkları yükleniyor...${NC}"
    sudo apt update
    sudo apt-get install git curl build-essential make jq gcc chrony tmux unzip bc -y
    echo -e "${GREEN}Bağımlılıklar yüklendi.${NC}"
}

# Cosmovisor kur
install_cosmovisor() {
    echo -e "${BLUE}Cosmovisor kuruluyor...${NC}"
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
    echo -e "${GREEN}Cosmovisor: $($HOME/go/bin/cosmovisor version 2>&1 | tail -n1)${NC}"
}

# worrelld release binary'sini indir
download_worrelld() {
    local arch_raw
    arch_raw="$(uname -m)"
    case "$arch_raw" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo -e "${RED}Desteklenmeyen mimari: ${arch_raw}${NC}"; return 1 ;;
    esac

    echo -e "${BLUE}worrelld ${WORRELL_VERSION} (linux/${ARCH}) binary aranıyor...${NC}"
    local api_url="https://api.github.com/repos/${WORRELL_REPO}/releases/tags/${WORRELL_VERSION}"
    local assets_json
    assets_json="$(curl -fsSL "$api_url")"
    if [ -z "$assets_json" ]; then
        echo -e "${RED}GitHub release bilgisi alınamadı!${NC}"
        return 1
    fi

    local download_url
    download_url="$(echo "$assets_json" | jq -r --arg arch "$ARCH" \
        '.assets[] | select(.name | test("linux"; "i")) | select(.name | test($arch; "i")) | .browser_download_url' \
        | head -n1)"

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        echo -e "${RED}linux/${ARCH} için uygun release dosyası bulunamadı!${NC}"
        echo -e "${YELLOW}https://github.com/${WORRELL_REPO}/releases/tag/${WORRELL_VERSION} adresini kontrol edin.${NC}"
        return 1
    fi

    echo -e "${BLUE}İndiriliyor: ${download_url}${NC}"
    WORK_DIR=$(mktemp -d)
    cd "$WORK_DIR"
    curl -fsSL -o worrelld.tar.gz "$download_url"

    if [ ! -f "worrelld.tar.gz" ]; then
        echo -e "${RED}Binary indirilemedi! İnternet bağlantınızı kontrol edin.${NC}"
        cd $HOME; rm -rf "$WORK_DIR"
        return 1
    fi

    tar -xzf worrelld.tar.gz 2>/dev/null || cp worrelld.tar.gz worrelld
    rm -f worrelld.tar.gz

    if find "$WORK_DIR" -name "libwasmvm*.so" 2>/dev/null | grep -q .; then
        find "$WORK_DIR" -name "libwasmvm*.so" -exec sudo mv {} /usr/lib/ \;
        echo -e "${GREEN}libwasmvm kütüphanesi kuruldu.${NC}"
    fi

    WORRELLD_BIN=$(find "$WORK_DIR" -type f -name "worrelld" 2>/dev/null | head -1)
    if [ -z "$WORRELLD_BIN" ]; then
        echo -e "${RED}HATA: worrelld binary bulunamadı! Tarball içeriğini kontrol edin.${NC}"
        ls -la "$WORK_DIR"
        cd $HOME; rm -rf "$WORK_DIR"
        return 1
    fi

    chmod +x "$WORRELLD_BIN"
    mkdir -p $HOME/go/bin
    cp "$WORRELLD_BIN" $HOME/go/bin/worrelld

    cd $HOME
    rm -rf "$WORK_DIR"

    export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin
    if ! command -v worrelld &> /dev/null; then
        sudo ln -sf $HOME/go/bin/worrelld /usr/local/bin/worrelld
    fi

    echo -e "${GREEN}worrelld versiyonu: $($HOME/go/bin/worrelld version --home $WORRELL_HOME 2>/dev/null || echo 'versiyon okunamadı')${NC}"
    return 0
}

# Node kurulumu
install_node() {
    clear
    print_logo

    read -p "$(echo -e ${YELLOW}$(get_text enter_moniker)": "${NC})" MONIKER

    if [ -z "$MONIKER" ]; then
        echo -e "${RED}Node ismi boş olamaz!${NC}"
        sleep 2
        return
    fi

    echo
    read -p "$(echo -e ${YELLOW}$(get_text enter_port)" [varsayılan: 10]: "${NC})" CUSTOM_PORT

    if [ -z "$CUSTOM_PORT" ]; then
        CUSTOM_PORT="10"
    fi

    if ! [[ "$CUSTOM_PORT" =~ ^[0-9]{1,2}$ ]]; then
        echo -e "${RED}Geçersiz port prefix! 1-2 haneli rakam girin. Varsayılan port (10) kullanılacak.${NC}"
        CUSTOM_PORT="10"
        sleep 2
    fi

    echo -e "${GREEN}Seçilen port prefix: $CUSTOM_PORT${NC}"
    echo -e "${YELLOW}Portlar: RPC ${CUSTOM_PORT}657, P2P ${CUSTOM_PORT}656, API ${CUSTOM_PORT}317, gRPC ${CUSTOM_PORT}090, vb.${NC}"
    sleep 2

    echo -e "${BLUE}Kurulum başlıyor...${NC}"

    install_dependencies
    install_go
    export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

    if ! download_worrelld; then
        echo -e "${RED}Kurulum durduruldu (worrelld indirilemedi).${NC}"
        sleep 3
        return
    fi

    install_cosmovisor

    echo -e "${BLUE}Cosmovisor dizin yapısı oluşturuluyor...${NC}"
    mkdir -p $WORRELL_HOME/cosmovisor/genesis/bin
    mkdir -p $WORRELL_HOME/cosmovisor/upgrades
    cp $HOME/go/bin/worrelld $WORRELL_HOME/cosmovisor/genesis/bin/worrelld

    if [ ! -f "$WORRELL_HOME/cosmovisor/genesis/bin/worrelld" ]; then
        echo -e "${RED}HATA: Cosmovisor genesis binary kopyalanamadı!${NC}"
        sleep 3
        return
    fi
    echo -e "${GREEN}Cosmovisor genesis binary doğrulandı: $(ls -lh $WORRELL_HOME/cosmovisor/genesis/bin/worrelld)${NC}"

    echo -e "${BLUE}Node başlatılıyor...${NC}"
    $HOME/go/bin/worrelld init "$MONIKER" --chain-id="$CHAIN_ID" --home="$WORRELL_HOME"

    echo -e "${BLUE}Genesis indiriliyor...${NC}"
    curl -fsSL "${NETWORKS_RAW}/genesis.json" -o $WORRELL_HOME/config/genesis.json

    DOWNLOADED_SHA=$(sha256sum $WORRELL_HOME/config/genesis.json | awk '{print $1}')
    if [ "$DOWNLOADED_SHA" != "$GENESIS_SHA256" ]; then
        echo -e "${RED}HATA: Genesis SHA256 uyuşmuyor!${NC}"
        echo -e "${RED}Beklenen: $GENESIS_SHA256${NC}"
        echo -e "${RED}Bulunan : $DOWNLOADED_SHA${NC}"
        sleep 3
        return
    fi
    echo -e "${GREEN}Genesis checksum doğrulandı.${NC}"

    # Bash profiline diğer zincirleri etkilemeyecek şekilde WORRELL prefixiyle yaz
    sed -i '/WORRELL_PORT/d' $HOME/.bash_profile 2>/dev/null
    sed -i '/WORRELL_MONIKER/d' $HOME/.bash_profile 2>/dev/null
    sed -i '/WORRELL_CHAIN_ID/d' $HOME/.bash_profile 2>/dev/null

    cat <<EOF >> $HOME/.bash_profile
export WORRELL_MONIKER="$MONIKER"
export WORRELL_CHAIN_ID="$CHAIN_ID"
export WORRELL_PORT="$CUSTOM_PORT"
EOF

    echo -e "${BLUE}Konfigürasyonlar ayarlanıyor...${NC}"
    sed -i "s|^persistent_peers *=.*|persistent_peers = \"${PERSISTENT_PEER}\"|" $WORRELL_HOME/config/config.toml
    sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "'"${MIN_GAS_PRICE}"'"|g' $WORRELL_HOME/config/app.toml
    sed -i -e "s/^enable *=.*/enable = true/" $WORRELL_HOME/config/app.toml

    # Port yapılandırması
    sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:9090%:${CUSTOM_PORT}090%g" $WORRELL_HOME/config/app.toml

    sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(curl -4 -s ifconfig.me || wget -4 -qO- ifconfig.me):${CUSTOM_PORT}656\"%;
s%:26660%:${CUSTOM_PORT}660%g" $WORRELL_HOME/config/config.toml

    # Pruning ayarları
    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $WORRELL_HOME/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $WORRELL_HOME/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $WORRELL_HOME/config/app.toml
    sed -i -e "s/prometheus = false/prometheus = true/" $WORRELL_HOME/config/config.toml
    sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $WORRELL_HOME/config/config.toml

    echo -e "${BLUE}Cosmovisor servisi oluşturuluyor...${NC}"
    sudo tee /etc/systemd/system/worrelld.service > /dev/null <<EOF
[Unit]
Description=Worrell Testnet Node with Cosmovisor
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start --home $WORRELL_HOME
Restart=always
RestartSec=3
LimitNOFILE=65535
Environment="DAEMON_NAME=worrelld"
Environment="DAEMON_HOME=$WORRELL_HOME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable worrelld

    echo -e "${BLUE}Node başlatılıyor...${NC}"
    sudo systemctl restart worrelld

    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}$(get_text installation_complete)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}Node Bilgileri:${NC}"
    echo -e "${YELLOW}Moniker: ${WHITE}$MONIKER${NC}"
    echo -e "${YELLOW}Versiyon: ${WHITE}${WORRELL_VERSION}${NC}"
    echo -e "${YELLOW}Port Prefix: ${WHITE}$CUSTOM_PORT${NC}"
    echo -e "${YELLOW}Chain ID: ${WHITE}$CHAIN_ID${NC}"
    echo
    echo -e "${CYAN}Kullanılan Portlar:${NC}"
    echo -e "${YELLOW}API: ${WHITE}${CUSTOM_PORT}317${NC}"
    echo -e "${YELLOW}RPC: ${WHITE}${CUSTOM_PORT}657${NC}"
    echo -e "${YELLOW}P2P: ${WHITE}${CUSTOM_PORT}656${NC}"
    echo -e "${YELLOW}gRPC: ${WHITE}${CUSTOM_PORT}090${NC}"
    echo -e "${YELLOW}Prometheus: ${WHITE}${CUSTOM_PORT}660${NC}"
    echo
    echo -e "${CYAN}Yararlı Komutlar:${NC}"
    echo -e "${YELLOW}Servis Durumu: ${WHITE}sudo systemctl status worrelld${NC}"
    echo -e "${YELLOW}Logları Görüntüle: ${WHITE}sudo journalctl -u worrelld -f${NC}"
    echo -e "${YELLOW}Sync Durumu: ${WHITE}worrelld status --home $WORRELL_HOME --node $(get_node_rpc) 2>&1 | jq .SyncInfo${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"

    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Sync durumu kontrolü
check_sync_status() {
    clear
    print_logo
    echo -e "${BLUE}Sync Durumu ($CHAIN_ID):${NC}"
    echo
    $HOME/go/bin/worrelld status --home "$WORRELL_HOME" --node "$(get_node_rpc)" 2>&1 | jq .SyncInfo
    echo
    echo -e "${YELLOW}Catching Up: false ise sync tamamlanmıştır${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Logları görüntüle
view_logs() {
    clear
    print_logo
    echo -e "${BLUE}Logları görüntülemek için CTRL+C ile çıkabilirsiniz${NC}"
    sleep 2
    sudo journalctl -u worrelld -f --no-hostname -o cat
}

# Cüzdan oluştur
create_wallet() {
    clear
    print_logo
    read -p "$(echo -e ${YELLOW}$(get_text enter_wallet)": "${NC})" WALLET_NAME

    if [ -z "$WALLET_NAME" ]; then
        echo -e "${RED}Cüzdan ismi boş olamaz!${NC}"
        sleep 2
        return
    fi

    $HOME/go/bin/worrelld keys add "$WALLET_NAME" --home "$WORRELL_HOME"
    echo
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Cüzdan oluşturuldu!${NC}"
    echo -e "${RED}⚠ UYARI: Mnemonic kelimelerinizi güvenli bir yere kaydedin!${NC}"
    echo -e "${RED}Bu kelimeleri kaybederseniz cüzdanınıza erişimi kaybedersiniz!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Cüzdan içe aktar
import_wallet() {
    clear
    print_logo
    read -p "$(echo -e ${YELLOW}$(get_text enter_wallet)": "${NC})" WALLET_NAME

    if [ -z "$WALLET_NAME" ]; then
        echo -e "${RED}Cüzdan ismi boş olamaz!${NC}"
        sleep 2
        return
    fi

    $HOME/go/bin/worrelld keys add "$WALLET_NAME" --recover --home "$WORRELL_HOME"
    echo
    echo -e "${GREEN}Cüzdan içe aktarıldı!${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Faucet'ten token iste
request_faucet() {
    clear
    print_logo
    read -p "$(echo -e ${YELLOW}$(get_text enter_wallet)" (adresi almak için): "${NC})" WALLET_NAME

    if [ -z "$WALLET_NAME" ]; then
        echo -e "${RED}Cüzdan ismi boş olamaz!${NC}"
        sleep 2
        return
    fi

    ADDRESS=$($HOME/go/bin/worrelld keys show "$WALLET_NAME" -a --home "$WORRELL_HOME" 2>/dev/null)
    if [ -z "$ADDRESS" ]; then
        echo -e "${RED}Adres bulunamadı! Cüzdan ismini kontrol edin.${NC}"
        sleep 2
        return
    fi

    echo -e "${BLUE}Faucet'ten talep gönderiliyor: ${ADDRESS}${NC}"
    curl -s -X POST "$FAUCET_URL" \
        -H "Content-Type: application/json" \
        -d "{\"address\":\"${ADDRESS}\"}"
    echo
    echo -e "${GREEN}Talep gönderildi. Birkaç saniye sonra bakiyenizi kontrol edin.${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Validator oluştur
create_validator() {
    clear
    print_logo

    echo -e "${YELLOW}Validator Detayları ($CHAIN_ID):${NC}"
    echo
    read -p "Cüzdan ismi: " WALLET_NAME
    read -p "Validator ismi (moniker): " MONIKER
    read -p "Identity (opsiyonel, Keybase ID): " IDENTITY
    read -p "Website (opsiyonel): " WEBSITE
    read -p "Security Contact (email): " SECURITY
    read -p "Details (açıklama): " DETAILS
    read -p "Commission rate (örn: 0.05): " RATE
    read -p "Commission max rate (örn: 0.20): " MAX_RATE
    read -p "Commission max change rate (örn: 0.01): " MAX_CHANGE_RATE
    read -p "Minimum self delegation (örn: 1): " MIN_SELF_DELEGATION
    read -p "Stake miktarı (örn: 1000000${DENOM}): " AMOUNT

    $HOME/go/bin/worrelld tx staking create-validator \
        --amount="$AMOUNT" \
        --pubkey="$($HOME/go/bin/worrelld tendermint show-validator --home "$WORRELL_HOME")" \
        --moniker="$MONIKER" \
        --identity="$IDENTITY" \
        --website="$WEBSITE" \
        --security-contact="$SECURITY" \
        --details="$DETAILS" \
        --chain-id="$CHAIN_ID" \
        --commission-rate="$RATE" \
        --commission-max-rate="$MAX_RATE" \
        --commission-max-change-rate="$MAX_CHANGE_RATE" \
        --min-self-delegation="$MIN_SELF_DELEGATION" \
        --from="$WALLET_NAME" \
        --home="$WORRELL_HOME" \
        --node="$(get_node_rpc)" \
        --gas="auto" \
        --gas-adjustment="1.4" \
        --fees="500${DENOM}" \
        -y

    echo
    echo -e "${GREEN}Validator oluşturma işlemi gönderildi!${NC}"
    echo -e "${YELLOW}Explorer'dan validator'ınızı kontrol edebilirsiniz: test.anode.team/worrell${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Token delege et
delegate_tokens() {
    clear
    print_logo

    read -p "Cüzdan ismi: " WALLET_NAME
    read -p "Validator adresi: " VALIDATOR_ADDR
    read -p "Miktar (örn: 1000000${DENOM}): " AMOUNT

    $HOME/go/bin/worrelld tx staking delegate "$VALIDATOR_ADDR" "$AMOUNT" \
        --from="$WALLET_NAME" \
        --chain-id="$CHAIN_ID" \
        --home="$WORRELL_HOME" \
        --node="$(get_node_rpc)" \
        --gas="auto" \
        --gas-adjustment="1.4" \
        --fees="500${DENOM}" \
        -y

    echo
    echo -e "${GREEN}Delegasyon işlemi gönderildi!${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Token gönder
send_tokens() {
    clear
    print_logo

    read -p "Gönderen cüzdan ismi: " WALLET_NAME
    read -p "Alıcı adres: " TO_ADDRESS
    read -p "Miktar (örn: 1000000${DENOM}): " AMOUNT

    $HOME/go/bin/worrelld tx bank send "$WALLET_NAME" "$TO_ADDRESS" "$AMOUNT" \
        --chain-id="$CHAIN_ID" \
        --home="$WORRELL_HOME" \
        --node="$(get_node_rpc)" \
        --gas="auto" \
        --gas-adjustment="1.4" \
        --fees="500${DENOM}" \
        -y

    echo
    echo -e "${GREEN}Transfer işlemi gönderildi!${NC}"
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Bakiye kontrol et
check_balance() {
    clear
    print_logo

    read -p "Cüzdan ismi veya adres: " WALLET_INPUT

    echo -e "${BLUE}Bakiye sorgulanıyor ($CHAIN_ID)...${NC}"
    local TARGET_ADDR
    if [[ "$WALLET_INPUT" =~ ^worrell ]]; then
        TARGET_ADDR="$WALLET_INPUT"
    else
        TARGET_ADDR=$($HOME/go/bin/worrelld keys show "$WALLET_INPUT" -a --home "$WORRELL_HOME" 2>/dev/null)
    fi

    if [ -z "$TARGET_ADDR" ]; then
        echo -e "${RED}Adres tespit edilemedi!${NC}"
    else
        $HOME/go/bin/worrelld query bank balances "$TARGET_ADDR" --chain-id="$CHAIN_ID" --home="$WORRELL_HOME" --node="$(get_node_rpc)"
    fi

    echo
    read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
}

# Node yönetimi menüsü
node_management_menu() {
    while true; do
        clear
        print_logo
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}     $(get_text node_management)           ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo
        echo -e "${WHITE}1)${NC}  $(get_text node_status)"
        echo -e "${WHITE}2)${NC}  $(get_text restart_node)"
        echo -e "${WHITE}3)${NC}  $(get_text stop_node)"
        echo -e "${WHITE}4)${NC}  $(get_text start_node)"
        echo -e "${WHITE}5)${NC}  $(get_text delete_node)"
        echo -e "${WHITE}0)${NC}  $(get_text back)"
        echo
        read -p "$(echo -e ${YELLOW}"Seçiminiz / Your choice: "${NC})" choice

        case $choice in
            1)
                clear
                print_logo
                sudo systemctl status worrelld
                echo
                read -p "$(echo -e ${CYAN}$(get_text press_enter)${NC})"
                ;;
            2)
                echo -e "${BLUE}Node yeniden başlatılıyor...${NC}"
                sudo systemctl restart worrelld
                echo -e "${GREEN}Node yeniden başlatıldı!${NC}"
                sleep 2
                ;;
            3)
                echo -e "${BLUE}Node durduruluyor...${NC}"
                sudo systemctl stop worrelld
                echo -e "${GREEN}Node durduruldu!${NC}"
                sleep 2
                ;;
            4)
                echo -e "${BLUE}Node başlatılıyor...${NC}"
                sudo systemctl start worrelld
                echo -e "${GREEN}Node başlatıldı!${NC}"
                sleep 2
                ;;
            5)
                clear
                print_logo
                echo -e "${RED}⚠ UYARI: Bu işlem node'unuzu tamamen silecektir!${NC}"
                echo -e "${RED}Cüzdan bilgilerinizi yedeklediğinizden emin olun!${NC}"
                echo
                read -p "$(echo -e ${YELLOW}"Devam etmek istiyor musunuz? (y/n): "${NC})" confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    echo -e "${BLUE}Node siliniyor...${NC}"
                    sudo systemctl stop worrelld
                    sudo systemctl disable worrelld
                    sudo rm -f /etc/systemd/system/worrelld.service
                    sudo systemctl daemon-reload
                    rm -rf "$WORRELL_HOME"
                    rm -f $HOME/go/bin/worrelld
                    sudo rm -f /usr/local/bin/worrelld
                    sed -i '/WORRELL_/d' $HOME/.bash_profile 2>/dev/null
                    echo -e "${GREEN}Node tamamen silindi!${NC}"
                    echo -e "${YELLOW}Not: Go ve Cosmovisor kurulumu (sunucudaki diğer node'lar için) korundu.${NC}"
                    sleep 3
                    return
                else
                    echo -e "${YELLOW}İşlem iptal edildi.${NC}"
                    sleep 2
                fi
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Geçersiz seçim!${NC}"
                sleep 2
                ;;
        esac
    done
}

# Ana menü
main_menu() {
    while true; do
        clear
        print_logo
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}           $(get_text main_menu)                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo
        echo -e "${WHITE}1)${NC}  $(get_text install)"
        echo -e "${WHITE}2)${NC}  $(get_text check_sync)"
        echo -e "${WHITE}3)${NC}  $(get_text view_logs)"
        echo -e "${WHITE}4)${NC}  $(get_text create_wallet)"
        echo -e "${WHITE}5)${NC}  $(get_text import_wallet)"
        echo -e "${WHITE}6)${NC}  $(get_text create_validator)"
        echo -e "${WHITE}7)${NC}  $(get_text delegate)"
        echo -e "${WHITE}8)${NC}  $(get_text send_tokens)"
        echo -e "${WHITE}9)${NC}  $(get_text check_balance)"
        echo -e "${WHITE}10)${NC} $(get_text request_faucet)"
        echo -e "${WHITE}11)${NC} $(get_text node_management)"
        echo -e "${WHITE}0)${NC}  $(get_text exit)"
        echo
        read -p "$(echo -e ${YELLOW}"Seçiminiz / Your choice: "${NC})" choice

        case $choice in
            1) install_node ;;
            2) check_sync_status ;;
            3) view_logs ;;
            4) create_wallet ;;
            5) import_wallet ;;
            6) create_validator ;;
            7) delegate_tokens ;;
            8) send_tokens ;;
            9) check_balance ;;
            10) request_faucet ;;
            11) node_management_menu ;;
            0)
                echo -e "${GREEN}Çıkılıyor... / Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Geçersiz seçim! / Invalid choice!${NC}"
                sleep 2
                ;;
        esac
    done
}

# Script başlangıcı
select_language
main_menu
