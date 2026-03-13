# CellMiner v1.2

High-performance RandomX (XMR) miner for Android phones. Pre-built binaries optimized for 36 ARM SoCs — from Snapdragon 821 (2017) to Snapdragon 8 Elite (2025), plus Samsung Exynos, Google Tensor, MediaTek Dimensity, Huawei Kirin, and generic fallbacks.

## Performance

| Miner | Avg H/s | Low | High | Notes |
|---|---|---|---|---|
| **CellMiner v1.2** | **~800** | ~680 | **~1,050** | LTO + SoC-specific tuning |
| xmrig | ~720 | ~620 | ~925 | Default config |

## Quick Start

### 1. Get the files onto your phone

**Option A — ADB push (from PC):**
```bash
adb push . /data/local/tmp/cellminer-install/
adb shell "cd /data/local/tmp/cellminer-install && bash install.sh"
```

**Option B — Termux (on phone):**

Clone or download this branch, then:
```bash
cd cellminer-install
bash install.sh
```

The installer will:
- Detect your SoC and pick the best binary
- Auto-set `light` mode if your phone has 4GB RAM or less
- Set thread count to match your core count
- Generate a starter `config.json`

### 2. Edit your config

```bash
cd ~/cellminer
nano config.json
```

Change these fields:

```json
{
  "pool": "pool.supportxmr.com:3333",
  "wallet": "YOUR_XMR_WALLET_ADDRESS",
  "pass": "x",
  "worker": "my-phone",
  "threads": 8,
  "huge_pages": true,
  "mode": "full"
}
```

| Field | What it does |
|---|---|
| **pool** | Your mining pool address and port |
| **wallet** | Your XMR wallet address |
| **pass** | Pool password — on some pools like supportxmr this shows as your **worker name** in the dashboard |
| **worker** | Worker ID sent as the `rigid` field in stratum login |
| **threads** | Number of mining threads (max 8). Set to your big core count for best results |
| **huge_pages** | Try to use huge pages for the dataset (recommended: `true`) |
| **mode** | `"full"` = 2GB dataset (needs ~2.5GB free RAM), `"light"` = 256MB (slower, for phones with 4GB or less) |

A fully annotated example is in `config.example.json`.

### 3. Start mining

```bash
cd ~/cellminer
bash run.sh
```

Or run directly:
```bash
cd ~/cellminer
./cellminer --config config.json
```

To run in the background:
```bash
cd ~/cellminer
nohup ./cellminer --config config.json > miner.log 2>&1 &
```

### 4. Check hashrate

If running in foreground, hashrate prints every 10 seconds.

If running in background:
```bash
tail -f ~/cellminer/miner.log
```

## Supported Devices

The installer auto-detects your SoC. If detection fails, it falls back to a generic build that works on any ARM64 Android phone.

| Year | SoCs | Example Devices |
|---|---|---|
| 2017 | SD 821, SD 835, Exynos 8895, Kirin 970 | Pixel 1-2, Galaxy S8, OnePlus 5 |
| 2018 | SD 845, Exynos 9810, Kirin 980 | Pixel 3, Galaxy S9, OnePlus 6 |
| 2019 | SD 855, Exynos 9820, Kirin 990 | Pixel 4, Galaxy S10, OnePlus 7 |
| 2020 | SD 865, SD 765, Exynos 990 | Galaxy S20, Pixel 5, OnePlus 8 |
| 2021 | SD 888, Exynos 2100, Dimensity 9000 | Galaxy S21/Z Fold3, Pixel 6 |
| 2022 | SD 8 Gen 1/1+, Exynos 2200 | Galaxy S22/Z Fold4, Pixel 7 |
| 2023 | SD 8 Gen 2, Dimensity 9200 | Galaxy S23, Pixel 8 |
| 2024 | SD 8 Gen 3, Exynos 2400 | Galaxy S24, Pixel 9 |
| 2025 | SD 8 Elite | Galaxy S25, OnePlus 13 |
| Any | Generic ARM64 fallback | Any 64-bit Android device |

## Tips

- **Termux gives ~17% more hashrate** than ADB shell due to Android's cpuset scheduler boosting foreground apps
- **Full mode** is ~5-10x faster than light mode — use it if you have 6GB+ RAM
- **Don't run more threads than big cores** — little cores (A55) are slow and drag down average hashrate
- Run via **Termux SSH** for headless setups: install openssh in Termux, start sshd, connect remotely

## Files

```
bin/                    # Pre-built binaries for all SoCs
  cellminer-sd888_x1   # Snapdragon 888 (optimized for X1 prime core)
  cellminer-sd855      # Snapdragon 855
  cellminer-generic_v8 # Works on any ARM64 phone
  ...                  # 36 targets total
install.sh             # Auto-detect installer
run.sh                 # Start script (checks config first)
config.example.json    # Annotated config template
```
