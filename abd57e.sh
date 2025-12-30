#!/usr/bin/env bash
set -e

echo "🧬 Project Synapse Extended Models Installer"

# Load pyenv into current shell
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Ensure project exists
cd "$HOME"
if [ ! -d "Project-Synapse-Real-Time-Brainwave-Decoder-with-Android" ]; then
    echo "📥 Cloning Project Synapse repository..."
    git clone https://github.com/mikey-7x/Project-Synapse-Real-Time-Brainwave-Decoder-with-Android.git
fi

cd Project-Synapse-Real-Time-Brainwave-Decoder-with-Android

# Activate environment
ENV_NAME="tf-env"
if ! pyenv versions | grep -q "$ENV_NAME"; then
    echo "❌ Environment '$ENV_NAME' not found. Run main installer first."
    exit 1
fi

echo "🔒 Activating environment: $ENV_NAME"
pyenv activate "$ENV_NAME"

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
    numpy \
    pandas \
    scipy \
    joblib \
    scikit-learn \
    xgboost \
    tensorflow==2.13.1

echo "✅ All extended model dependencies installed successfully."
echo ""
echo "🧠 To start extended decoder:"
echo "➡️ pyenv activate tf-env"
echo "
if ! pyenv versions | grep -q "$ENV_NAME"; then
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
