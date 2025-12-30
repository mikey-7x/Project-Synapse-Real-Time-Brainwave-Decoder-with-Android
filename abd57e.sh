#!/usr/bin/env bash
set -e

echo "🧬 Project Synapse Extended Models Installer"

# Load pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Activate environment
pyenv activate mikey-7x

echo "🔧 Installing native dependencies for XGBoost..."

if command -v apt &> /dev/null; then
    sudo apt install -y cmake ninja-build libomp-dev
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm cmake ninja libomp
elif command -v dnf &> /dev/null; then
    sudo dnf install -y cmake ninja-build libomp-devel
elif command -v emerge &> /dev/null; then
    sudo emerge --ask dev-util/cmake dev-util/ninja sys-devel/llvm
else
    echo "❌ Unsupported distro for XGBoost native dependencies"
    exit 1
fi

echo "📦 Installing missing Python packages..."

pip install --upgrade pip

pip install \
    xgboost \
    scikit-learn \
    numpy \
    pandas \
    scipy \
    joblib \
    tensorflow==2.13.1

echo "✅ All extended model dependencies installed successfully."
echo "🧠 You can now run:  python abd57e.py"
