#!/usr/bin/env bash

set -e

echo "🧠 Project Synapse: Universal Installer"
echo "🔄 Updating system and installing dependencies..."

# Detect package manager
#if command -v apt &> /dev/null; then
    #sudo apt update && sudo apt install -y git curl wget build-essential libbz2-dev libssl-dev libreadline-dev libsqlite3-dev zlib1g-dev
#elif command -v pacman &> /dev/null; then
    #sudo pacman -Sy --noconfirm base-devel git curl wget openssl zlib
#elif command -v dnf &> /dev/null; then
   # sudo dnf install -y gcc gcc-c++ make git curl wget zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel
if command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y git curl wget build-essential \
        libbz2-dev libssl-dev libreadline-dev libsqlite3-dev zlib1g-dev tk-dev liblzma-dev
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm base-devel git curl wget openssl zlib tk xz
elif command -v dnf &> /dev/null; then
    sudo dnf install -y gcc gcc-c++ make git curl wget \
        zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel \
        openssl-devel tk-devel xz-devel
elif command -v emerge &> /dev/null; then
    sudo emerge --ask dev-vcs/git dev-lang/python curl wget
else
    echo "❌ Unsupported Linux distro. Please install dependencies manually."
    exit 1
fi

echo "📦 Installing pyenv..."

# Install pyenv
if [ -d "$HOME/.pyenv" ]; then
echo "🔁 pyenv already installed"
else
    curl https://pyenv.run | bash
fi

# --- PATCH: persist pyenv in user shell ---
for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$profile" ] && ! grep -q 'pyenv init' "$profile"; then
cat >> "$profile" << 'EOF'

# >>> pyenv initialization >>>
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# <<< pyenv initialization <<<

EOF
    fi
done
# ----------------------------------------

# Set up pyenv environment
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Required old Python version for TensorFlow 2.13.1
PYTHON_VERSION="3.10.13"

if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo "📥 Installing Python $PYTHON_VERSION using pyenv..."
    pyenv install $PYTHON_VERSION
fi

echo "🔒 Creating and activating pyenv virtualenv 'mikey-7x'..."
pyenv virtualenv $PYTHON_VERSION mikey-7x || true
pyenv activate mikey-7x

echo "📂 Installing required Python packages..."
pip install --upgrade pip
pip install numpy pandas scipy joblib scikit-learn tensorflow==2.13.1

echo "📥 Downloading abd57.py from GitHub..."
wget -O abd57.py https://raw.githubusercontent.com/mikey-7x/Project-Synapse-Real-Time-Brainwave-Decoder-with-Android/main/abd57.py

echo "✅ Done! Your environment 'mikey-7x' is ready."
echo ""
echo "🧠 To run your brainwave decoder:"
echo "➡️ pyenv activate mikey-7x"
echo "➡️ python abd57.py"
echo ""
echo "🔁 To deactivate: pyenv deactivate"
