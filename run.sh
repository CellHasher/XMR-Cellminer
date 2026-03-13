#!/data/data/com.termux/files/usr/bin/bash
# CellMiner run script for Termux
# Usage: bash run.sh

DIR="$HOME/cellminer"

if [ ! -f "$DIR/cellminer" ]; then
    echo "CellMiner not installed. Run install.sh first."
    exit 1
fi

if grep -q "YOUR_XMR_WALLET_ADDRESS" "$DIR/config.json" 2>/dev/null; then
    echo "ERROR: Edit $DIR/config.json and set your wallet address first!"
    exit 1
fi

cd "$DIR"
echo "Starting CellMiner..."
exec ./cellminer --config config.json
