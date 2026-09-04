# worrell-testnet-1 — Node Manager Kurulum Rehberi

Bu script, **worrell-testnet-1** ağına Cosmovisor ile bağlanan bir node
kurmak ve yönetmek için tamamen **interaktif bir menü** sunar: script'i
çalıştırdığınızda moniker'ınızı ve port prefix'inizi sorar, ardından
cüzdan/validator/node yönetimi işlemlerini menüden yapabilirsiniz.

| Alan | Değer |
|---|---|
| Chain ID | `worrell-testnet-1` |
| Binary | `worrelld` (Cosmos SDK v0.53.6) |
| Kaynak | [worrellchain/worrell](https://github.com/worrellchain/worrell) @ `v0.1.2` |
| Genesis | [worrell-testnet-1/genesis.json](https://github.com/worrellchain/networks/blob/main/worrell-testnet-1/genesis.json) |
| Genesis sha256 | `a81c507b12ba0678c3172394ff4bb03e1c3db60050cc5568c127a24ec19378fd` |
| Persistent peer | `bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656` |
| Min gas price | `0.025uworrell` |
| Faucet | `POST http://164.68.98.186:4500` → `{"address":"worrell1..."}` (500 WORRELL) |

---

## Kullanım

```bash
git clone https://github.com/Edsny1/Worrel-Testnet.git && cd Worrel-Testnet && chmod +x worrell-node-manager.sh && ./worrell-node-manager.sh
```

Script açıldığında sırasıyla:

1. **Dil seçimi** (English / Türkçe)
2. **Ana menü** görüntülenir

```
1)  Kurulum Yap
2)  Sync Durumu Kontrol Et
3)  Logları Görüntüle
4)  Cüzdan Oluştur
5)  Cüzdan İçe Aktar
6)  Validator Oluştur
7)  Token Delege Et
8)  Token Gönder
9)  Bakiye Kontrol Et
10) Faucet'ten Token İste
11) Node Yönetimi
0)  Çıkış
```

### 1) Kurulum Yap

Bu seçenek sırayla:

- **Moniker sorar** (node isminiz)
- **Port prefix sorar** — örn. `10`, `26`, `45` gibi 1-2 haneli bir sayı
  (boş bırakırsanız varsayılan `10` kullanılır). Bu prefix tüm servis
  portlarının başına eklenir, böylece aynı sunucuda birden fazla node
  çalıştırdığınızda port çakışması yaşamazsınız:

  | Servis | Sabit sonek | Örnek (prefix=10) |
  |---|---|---|
  | RPC | `657` | `10657` |
  | P2P | `656` | `10656` |
  | ABCI (proxy_app) | `658` | `10658` |
  | pprof | `060` | `10060` |
  | Prometheus | `660` | `10660` |
  | REST API | `317` | `10317` |
  | gRPC | `090` | `10090` |

- Ardından otomatik olarak:
  1. Gerekli paketleri kurar (`curl`, `jq`, `tar`, `build-essential`, vb.)
  2. **Go zaten kuruluysa ve sürümü yeterliyse dokunmaz** (sunucunuzda
     başka Cosmos node'ları çalışıyorsa güvenlidir); yalnızca eksikse
     veya sürüm yetersizse kurar/günceller.
  3. GitHub Releases'ten sisteminize uygun `worrelld` (`v0.1.2`,
     linux/amd64 veya linux/arm64) binary'sini indirir.
  4. Cosmovisor'ü kurar (chain-agnostic bir araç olduğundan sunucudaki
     diğer node'larla paylaşılabilir).
  5. Cosmovisor dizin yapısını (`~/.worrell/cosmovisor/genesis/bin/...`)
     oluşturur.
  6. `worrelld init` çalıştırır, resmi `genesis.json`'ı indirir ve
     **sha256 checksum'ını doğrular**.
  7. `persistent_peers`, `minimum-gas-prices`, pruning ayarlarını ve
     seçtiğiniz **tüm portları** yapılandırır.
  8. `worrelld.service` adında bir systemd servisi oluşturur, etkinleştirir
     ve node'u başlatır.

Kurulum bilgileri (moniker, port prefix) `~/.bash_profile` içine
`WORRELL_MONIKER`, `WORRELL_PORT` gibi değişkenler olarak kaydedilir; bu
sayede script'i tekrar açtığınızda diğer menü seçenekleri de bu bilgileri
kullanabilir.

### 2) Sync Durumu Kontrol Et

```
worrelld status 2>&1 | jq .SyncInfo
```
`catching_up: false` ise senkronizasyon tamamlanmış demektir.

### 3) Logları Görüntüle

```
sudo journalctl -u worrelld -f --no-hostname -o cat
```

### 4-5) Cüzdan Oluştur / İçe Aktar

`worrelld keys add <isim>` veya `worrelld keys add <isim> --recover`
çalıştırır. **Mnemonic kelimelerinizi güvenli bir yerde saklayın.**

### 6-8) Validator Oluştur / Delege Et / Token Gönder

Standart `worrelld tx staking create-validator`, `tx staking delegate`,
`tx bank send` komutlarını, girdiğiniz parametrelerle ve
`worrell-testnet-1` chain-id / `uworrell` denomu ile çalıştırır.

### 9) Bakiye Kontrol Et

```
worrelld query bank balances <cüzdan-veya-adres>
```

### 10) Faucet'ten Token İste

Belirttiğiniz cüzdanın adresini `worrelld keys show` ile çözüp, faucet'e
otomatik POST isteği gönderir:

```
curl -X POST http://164.68.98.186:4500 \
  -H "Content-Type: application/json" \
  -d '{"address":"worrell1..."}'
```

```
# Değişkenleri kendi bilgilerinize göre düzenleyin
MONIKER="YOUR_MONIKER"
IDENTITY="YOUR_KEYBASE_ID"
WEBSITE="https://yourwebsite.com"
SECURITY_CONTACT="your-email@example.com"
DETAILS="Your node description"
AMOUNT="490000000uworrell"

# JSON dosyasını oluştur
cat <<EOF > $HOME/.worrell/validator.json
{
  "pubkey": $(worrelld tendermint show-validator --home $HOME/.worrell),
  "amount": "${AMOUNT}",
  "moniker": "${MONIKER}",
  "identity": "${IDENTITY}",
  "website": "${WEBSITE}",
  "security": "${SECURITY_CONTACT}",
  "details": "${DETAILS}",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1000000"
}
EOF
```
```
# Cüzdan adınızı ve port bilginizi tanımlayın
WALLET="wallet-adı"
PORT_PREFIX=$(grep 'WORRELL_PORT=' $HOME/.bash_profile 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "10")

worrelld tx staking create-validator $HOME/.worrell/validator.json \
  --from $WALLET \
  --chain-id worrell-testnet-1 \
  --home $HOME/.worrell \
  --node tcp://127.0.0.1:${PORT_PREFIX}657 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 0.025uworrell \
  -y

```

### 11) Node Yönetimi

Alt menüden node durumunu görüntüleyebilir, yeniden başlatabilir,
durdurabilir, başlatabilir veya **tamamen silebilirsiniz** (silme işlemi
onay ister; sunucudaki paylaşılan Go/Cosmovisor kurulumuna dokunmaz,
sadece bu node'a ait dosyaları kaldırır).

---

## Firewall

En azından P2P portunu dışa açmanız gerekir (seçtiğiniz prefix'e göre
`<prefix>656`):

```bash
sudo ufw allow 10656/tcp   # p2p (örnek: prefix=10)
sudo ufw allow 10657/tcp   # rpc (opsiyonel, dışa açmak isterseniz)
sudo ufw allow 10317/tcp   # REST API (opsiyonel)
```

---

## Cosmovisor ile ileride yapılacak upgrade'ler

Bir governance upgrade proposal'ı geçerse yeni binary'yi şu klasöre
koymanız yeterlidir:

```bash
mkdir -p $HOME/.worrell/cosmovisor/upgrades/<UPGRADE-ADI>/bin
cp <yeni-worrelld-binary> $HOME/.worrell/cosmovisor/upgrades/<UPGRADE-ADI>/bin/worrelld
chmod +x $HOME/.worrell/cosmovisor/upgrades/<UPGRADE-ADI>/bin/worrelld
```

Upgrade bloğuna ulaşıldığında Cosmovisor node'u otomatik olarak durdurup
yeni binary ile yeniden başlatır. Yükseltme duyuruları için:
[t.me/worrellvalidators](https://t.me/worrellvalidators).

---

## Yardım

- GitHub Discussions: [worrellchain/worrell](https://github.com/worrellchain/worrell/discussions)
- E-posta: hello@worrellchain.com
- Telegram: [t.me/worrellvalidators](https://t.me/worrellvalidators)
