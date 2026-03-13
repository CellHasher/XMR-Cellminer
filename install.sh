#!/data/data/com.termux/files/usr/bin/bash
# CellMiner auto-installer for Termux
# Detects SoC, picks the right binary, auto-configures for device capabilities.
#
# Usage (on phone in Termux):
#   bash install.sh

set -euo pipefail

INSTALL_DIR="$HOME/cellminer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

# ============================================================================
# SoC DETECTION
# ============================================================================

detect_soc() {
    local board=""
    local chipset=""

    board=$(getprop ro.board.platform 2>/dev/null || true)
    chipset=$(getprop ro.hardware.chipname 2>/dev/null || true)
    [ -z "$chipset" ] && chipset=$(getprop ro.soc.model 2>/dev/null || true)

    echo "  Board:     ${board:-unknown}" >&2
    echo "  Chipset:   ${chipset:-unknown}" >&2

    # Match by Qualcomm board platform
    case "$board" in
        pineapple|sun)          echo "sd8elite" ; return ;;
        kalama)                 echo "sd8gen3" ; return ;;
        crow)                   echo "sd7plusgen3" ; return ;;
        taro|cape)              echo "sd8gen2" ; return ;;
        waipio)                 echo "sd8gen1" ; return ;;
        lahaina)                echo "sd888_x1" ; return ;;
        kona)                   echo "sd865" ; return ;;
        lito|lagoon)            echo "sd765" ; return ;;
        msmnile|sm8150)         echo "sd855" ; return ;;
        sdm845)                 echo "sd845" ; return ;;
        msm8998)                echo "sd835" ; return ;;
        msm8996*)               echo "sd821" ; return ;;
    esac

    # Match by chipset name
    case "$chipset" in
        exynos2400*|s5e8835*)   echo "exynos2400" ; return ;;
        exynos2200*|s5e9925*)   echo "exynos2200" ; return ;;
        exynos2100*|s5e9815*)   echo "exynos2100" ; return ;;
        exynos990*)             echo "exynos990" ; return ;;
        exynos9820*)            echo "exynos9820" ; return ;;
        exynos9810*)            echo "exynos9810" ; return ;;
        exynos8895*)            echo "exynos8895" ; return ;;
        kirin*9000*|kirin*990*) echo "kirin990" ; return ;;
        kirin*980*)             echo "kirin980" ; return ;;
        kirin*970*)             echo "kirin970" ; return ;;
        mt6893*|mt6895*)        echo "dimensity1200" ; return ;;
        mt6983*|mt6985*|mt6989*) echo "dimensity9200" ; return ;;
        mt6877*|mt6853*)        echo "dimensity1000" ; return ;;
        mt6771*)                echo "helio_p60" ; return ;;
    esac

    # Google Tensor detection by model
    local model=""
    model=$(getprop ro.product.model 2>/dev/null || true)
    case "$model" in
        Pixel\ 9*)              echo "tensor_g4" ; return ;;
        Pixel\ 8*)              echo "tensor_g3" ; return ;;
        Pixel\ 7*)              echo "tensor_g2" ; return ;;
        Pixel\ 6*)              echo "tensor_g1" ; return ;;
    esac

    # Fallback: detect by CPU features
    local cpufeatures=""
    cpufeatures=$(grep -m1 "Features" /proc/cpuinfo 2>/dev/null || true)

    if echo "$cpufeatures" | grep -q "i8mm"; then
        echo "generic_v82_i8mm"
    elif echo "$cpufeatures" | grep -q "asimddp"; then
        echo "generic_v82"
    else
        echo "generic_v8"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

echo "=== CellMiner Installer ==="
echo ""
echo "Detecting device..."
TARGET=$(detect_soc)
RAM_MB=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))
THREADS=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)

echo "  Target:    $TARGET"
echo "  RAM:       ${RAM_MB}MB"
echo "  Cores:     $THREADS"
echo ""

# Pick binary
BINARY="$BIN_DIR/cellminer-$TARGET"
if [ ! -f "$BINARY" ]; then
    echo "WARNING: No optimized binary for $TARGET"
    for fb in generic_v82_i8mm generic_v82 generic_v8; do
        if [ -f "$BIN_DIR/cellminer-$fb" ]; then
            BINARY="$BIN_DIR/cellminer-$fb"
            echo "  Using fallback: $fb"
            break
        fi
    done
fi

if [ ! -f "$BINARY" ]; then
    echo "FATAL: No compatible binary found in $BIN_DIR/"
    exit 1
fi

# Determine mode based on RAM
MODE="full"
if [ "$RAM_MB" -le 4096 ]; then
    MODE="light"
    echo "  RAM <= 4GB, using light mode (256MB instead of 2GB dataset)"
fi

# Install
mkdir -p "$INSTALL_DIR"
cp "$BINARY" "$INSTALL_DIR/cellminer"
chmod 755 "$INSTALL_DIR/cellminer"

# Copy run script
if [ -f "$SCRIPT_DIR/run.sh" ]; then
    cp "$SCRIPT_DIR/run.sh" "$INSTALL_DIR/run.sh"
    chmod 755 "$INSTALL_DIR/run.sh"
fi

# Copy example config
if [ -f "$SCRIPT_DIR/config.example.json" ]; then
    cp "$SCRIPT_DIR/config.example.json" "$INSTALL_DIR/config.example.json"
fi

# Generate config if none exists
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    cat > "$INSTALL_DIR/config.json" << CONF
{
  "pool": "pool.supportxmr.com:3333",
  "wallet": "YOUR_XMR_WALLET_ADDRESS",
  "pass": "x",
  "worker": "cellminer-01",
  "threads": $THREADS,
  "huge_pages": true,
  "mode": "$MODE"
}
CONF
    echo ""
    echo "Created config.json — edit wallet address before mining!"
else
    echo ""
    echo "Existing config.json preserved."
fi

SIZE=$(ls -lh "$INSTALL_DIR/cellminer" | awk '{print $5}')
echo ""
echo "=== Installed ==="
echo "  Binary:  $INSTALL_DIR/cellminer ($SIZE, target=$TARGET)"
echo "  Config:  $INSTALL_DIR/config.json (mode=$MODE, threads=$THREADS)"
echo "  Example: $INSTALL_DIR/config.example.json"
echo "  Runner:  $INSTALL_DIR/run.sh"
echo ""
echo "To start mining:"
echo "  cd ~/cellminer"
echo "  # Edit config.json with your wallet address first!"
echo "  bash run.sh"
echo ""
