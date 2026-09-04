# Worrell Testnet (`worrell-testnet-1`) — Node Manager Guide

An interactive CLI manager to deploy, synchronize, and operate a validator node on the **`worrell-testnet-1`** network using Cosmovisor.

The script automates Go, Cosmovisor, and binary source compilation, configures customized port prefixes to avoid conflicts on multi-node servers, enforces IPv4 networking, downloads snapshots, and provides wallet/validator management directly using wallet addresses.

| Parameter | Value |
| --- | --- |
| Chain ID | `worrell-testnet-1` |
| Binary | `worrelld` (Cosmos SDK v0.53.6) |
| Source | [worrellchain/worrell](https://github.com/worrellchain/worrell) @ `v0.1.2` |
| Genesis | [server-3.itrocket.net/.../genesis.json](https://server-3.itrocket.net/testnet/worrell/genesis.json) |
| Addrbook | [server-3.itrocket.net/.../addrbook.json](https://server-3.itrocket.net/testnet/worrell/addrbook.json) |
| Min Gas Price | `0.025uworrell` |
| Faucet | `POST [http://164.68.98.186:4500](http://164.68.98.186:4500)` → `{"address":"worrell1..."}` (500 WORRELL / hour) |

---

## Quick Start

Run the manager using git clone:

```bash
git clone https://github.com/Edsny1/Worrel-Testnet.git && cd Worrel-Testnet && chmod +x worrell-node-manager.sh && ./worrell-node-manager.sh

```

Or execute directly via one-liner:

```bash
bash <(curl -s https://raw.githubusercontent.com/Edsny1/Worrel-Testnet/main/worrell-node-manager.sh)

```

---

## Menu Interface

```text
1)  Install Node (Cosmovisor Setup)
2)  Check Sync Status
3)  View Logs
4)  Download Snapshot
5)  Create Wallet
6)  Import Wallet
7)  List Wallets
8)  Check Balance
9)  Request Faucet Tokens
10) Create Validator
11) Node Service Management (Start/Stop/Delete)
0)  Exit

```

---

## Features & Usage

### 1) Install Node (Cosmovisor Setup)

* Prompts for a custom **Moniker** and a 1–2 digit **Port Prefix** (default: `10`).
* Verifies system dependencies and Go environment (requires Go `1.23.5+`).
* Installs `cosmovisor` and sets up the `$HOME/.worrell/cosmovisor/genesis/bin` directory layout.
* Clones and builds `worrellchain/worrell` from source at `v0.1.2`.
* Downloads official Genesis and Addrbook files from ITRocket.
* Offsets all default ports with your port prefix to run multiple nodes on a single host.
* Detects your public IPv4 address to configure `external_address`, preventing CometBFT IPv6 parsing crashes.
* Automatically downloads and unpacks the latest available `.tar.lz4` snapshot.
* Generates, enables, and starts the `worrelld.service` systemd unit under Cosmovisor.

**Port Allocation Table (Example Prefix: `10`)**

| Service | Default Port | Configured Port |
| --- | --- | --- |
| RPC | `26657` | `10657` |
| P2P | `26656` | `10656` |
| REST API | `1317` | `10317` |
| gRPC | `9090` | `10090` |
| Prometheus | `26660` | `10660` |

### 2) Check Sync Status

Queries the local node status via JSON-RPC:

```bash
worrelld status --home $HOME/.worrell --node tcp://127.0.0.1:<PORT>657 2>&1 | jq '.SyncInfo // .sync_info'

```

When `catching_up` returns `false`, your node is fully synced with the network.

### 3) View Logs

Streams live service logs:

```bash
sudo journalctl -u worrelld -f -o cat

```

### 4) Download Snapshot

Stops the node, creates a backup of `$HOME/.worrell/data/priv_validator_state.json` to prevent double-signing, wipes outdated data, downloads the latest available ITRocket snapshot, restores your validator state file, and restarts the service.

### 5 - 7) Wallet Operations

* **Create / Import Wallet:** Generates or recovers a seed phrase stored in `$HOME/.worrell`. Automatically sets `WORRELL_WALLET_ADDRESS` in your shell environment.
* **List Wallets:** Displays all keys registered under the isolated home directory.

### 8) Check Balance

Bypasses OS Keyring prompts by querying the bank module directly with your `worrell1...` address:

```bash
worrelld query bank balances <WORRELL_ADDRESS> --home $HOME/.worrell --node tcp://127.0.0.1:<PORT>657

```

### 9) Request Faucet Tokens

```
curl -X POST http://164.68.98.186:4500 \
  -H "Content-Type: application/json" \
  -d '{"address":"worrell1..."}'
```

Sends an automated API request to for 500 WORRELL test tokens (rate limit: once per hour per address).

### 10) Create Validator

Generates the Cosmos SDK v0.50+ compliant `$HOME/.worrell/validator.json` specification and submits the transaction using your `worrell1...` signer address:

```json
{
  "pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"..."},
  "amount": "490000000uworrell",
  "moniker": "YOUR_MONIKER",
  "identity": "YOUR_KEYBASE_ID",
  "website": "https://yourwebsite.com",
  "security": "security@yourwebsite.com",
  "details": "Validator description",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1000000"
}

```

```bash
worrelld tx staking create-validator $HOME/.worrell/validator.json \
  --from <SIGNER_ADDRESS> \
  --chain-id worrell-testnet-1 \
  --home $HOME/.worrell \
  --node tcp://127.0.0.1:<PORT>657 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 0.025uworrell \
  -y

```

### 11) Node Service Management

Submenu to restart, stop, start, view systemd status, or cleanly wipe the Worrell installation without affecting your system Go environment or other node daemons.

---

## Firewall Configuration (UFW)

Ensure P2P traffic is accessible based on your chosen port prefix (e.g., prefix `10`):

```bash
sudo ufw allow 10656/tcp comment "Worrell P2P"
sudo ufw allow 10657/tcp comment "Worrell RPC (Optional)"
sudo ufw allow 10317/tcp comment "Worrell API (Optional)"

```

---

## Cosmovisor Upgrades

When a network upgrade proposal passes governance, prepare the target binary under the Cosmovisor upgrades folder:

```bash
mkdir -p $HOME/.worrell/cosmovisor/upgrades/<UPGRADE_NAME>/bin
cp <new_worrelld_binary> $HOME/.worrell/cosmovisor/upgrades/<UPGRADE_NAME>/bin/worrelld
chmod +x $HOME/.worrell/cosmovisor/upgrades/<UPGRADE_NAME>/bin/worrelld

```

Cosmovisor will switch to the new binary automatically at the target upgrade block height.

---

## Community & Resources

* **Documentation:** [docs.oshvank.xyz/docs/testnet/Worrel](https://docs.oshvank.xyz/docs/testnet/Worrel)
* **Explorer:** [explorer.oshvank.xyz/worrel-testnet](https://explorer.oshvank.xyz/worrel-testnet)
* **Public RPC:** `worrel-testnet-rpc.oshvank.xyz`
* **Official Telegram:** [t.me/worrellvalidators](https://t.me/worrellvalidators)
