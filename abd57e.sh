#!/usr/bin/env bash
set -e

echo "🧬 Project Synapse — abd57e Full Builder"

# ===============================
# 0. Detect distro correctly
# ===============================
if grep -qi "archarm" /etc/os-release || grep -qi "alarm" /etc/os-release; then
    DISTRO="archarm"
elif grep -qi arch /etc/os-release; then
    DISTRO="arch"
elif grep -qiE "debian|ubuntu|kali" /etc/os-release; then
    DISTRO="debian"
elif grep -qi fedora /etc/os-release; then
    DISTRO="fedora"
elif grep -qi gentoo /etc/os-release; then
    DISTRO="gentoo"
else
    echo "❌ Unsupported Linux distro"
    exit 1
fi

echo "📦 Detected distro: $DISTRO"

# ===============================
# 1. Install system dependencies
# ===============================
case "$DISTRO" in
debian)
    sudo apt update
    sudo apt install -y \
        git curl wget build-essential \
        libbz2-dev libssl-dev libreadline-dev libsqlite3-dev \
        zlib1g-dev tk-dev liblzma-dev \
        cmake ninja-build libomp-dev
    ;;
arch)
    sudo pacman -Sy --noconfirm \
        base-devel git curl wget openssl zlib \
        tk xz cmake ninja llvm-openmp
    ;;
archarm)
    sudo pacman -Sy --noconfirm \
        base-devel git curl wget openssl zlib \
        tk xz cmake ninja openmp
    ;;
fedora)
    sudo dnf install -y \
        gcc gcc-c++ make git curl wget \
        zlib-devel bzip2 bzip2-devel readline-devel \
        sqlite sqlite-devel openssl-devel \
        tk-devel xz-devel cmake ninja-build libomp-devel
    ;;
gentoo)
    sudo emerge --ask \
        dev-vcs/git dev-lang/python curl wget \
        dev-util/cmake dev-util/ninja sys-devel/llvm
    ;;
esac

# ===============================
# 2. Install & init pyenv
# ===============================
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# ===============================
# 3. Build Python + environment
# ===============================
PYTHON_VERSION="3.10.13"
ENV_NAME="abd57e-env"

if ! pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
    pyenv install "$PYTHON_VERSION"
fi

if ! pyenv virtualenvs --bare | grep -qx "$ENV_NAME"; then
    pyenv virtualenv "$PYTHON_VERSION" "$ENV_NAME"
fi

pyenv activate "$ENV_NAME"

# ===============================
# 4. Install Python dependencies
# ===============================
pip install --upgrade pip

pip install \
    numpy pandas scipy joblib scikit-learn \
    xgboost \
    tensorflow==2.13.1

# ===============================
# 5. Fetch program                                                                                                                        # ===============================
cd "$HOME"
wget -O abd57e.py \
https://raw.githubusercontent.com/mikey-7x/Project-Synapse-Real-Time-Brainwave-Decoder-with-Android/main/abd57e.py

# ===============================
# 6. Done
# ===============================
echo ""
echo "✅ abd57e system is READY"
echo ""
echo "Run with:"
echo "   pyenv activate $ENV_NAME"
echo "   python abd57e.py"

