#!/usr/bin/env bash
set -e

echo "🧬 Project Synapse — abd57e Full Builder"

# -------------------------
# 0. Detect distro manager
# -------------------------
PKG=""

if command -v apt >/dev/null 2>&1; then
    PKG="apt"
elif command -v pacman >/dev/null 2>&1; then
    PKG="pacman"
elif command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
elif command -v emerge >/dev/null 2>&1; then
    PKG="emerge"
else
    echo "❌ Unsupported Linux distro"
    exit 1
fi

# -------------------------
# 1. Install system deps
# -------------------------
echo "📦 Installing system dependencies..."

case "$PKG" in
apt)
    sudo apt update
    sudo apt install -y \
        git curl wget build-essential \
        libbz2-dev libssl-dev libreadline-dev libsqlite3-dev \
        zlib1g-dev tk-dev liblzma-dev \
        cmake ninja-build libomp-dev
    ;;
pacman)
    sudo pacman -Sy --noconfirm \
        base-devel git curl wget openssl zlib \
        tk xz cmake ninja libomp
    ;;
dnf)
    sudo dnf install -y \
        gcc gcc-c++ make git curl wget \
        zlib-devel bzip2 bzip2-devel readline-devel \
        sqlite sqlite-devel openssl-devel \
        tk-devel xz-devel cmake ninja-build libomp-devel
    ;;
emerge)
    sudo emerge --ask \
        dev-vcs/git dev-lang/python curl wget \
        dev-util/cmake dev-util/ninja sys-devel/llvm
    ;;
esac

# -------------------------
# 2. Install & init pyenv
# -------------------------
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Load pyenv correctly on fresh shells
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# -------------------------
# 3. Build Python + env
# -------------------------
PYTHON_VERSION="3.10.13"
ENV_NAME="abd57e-env"

if ! pyenv versions --bare | grep -q "^$PYTHON_VERSION$"; then
    pyenv install "$PYTHON_VERSION"
fi

if ! pyenv virtualenvs --bare | grep -q "^$ENV_NAME$"; then
    pyenv virtualenv "$PYTHON_VERSION" "$ENV_NAME"
fi

pyenv activate "$ENV_NAME"

# -------------------------
# 4. Install Python deps
# -------------------------
pip install --upgrade pip

pip install \
    numpy pandas scipy joblib scikit-learn \
    xgboost \
    tensorflow==2.13.1

# -------------------------
# 5. Fetch program
# -------------------------
cd "$HOME"
wget -O abd57e.py \
https://raw.githubusercontent.com/mikey-7x/Project-Synapse-Real-Time-Brainwave-Decoder-with-Android/main/abd57e.py

# -------------------------
# 6. Done
# -------------------------
echo ""
echo "✅ abd57e system is READY"
echo ""
echo "Run with:"
echo "   pyenv activate $ENV_NAME"
echo "   python abd57e.py"
