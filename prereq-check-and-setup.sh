#!/bin/bash

# ============================================================================
# HP ZGX Nano + NVIDIA Nemotron 3 + OpenCode
# Script 1: Prerequisites Setup
# ============================================================================
# This script checks prerequisites, installs Docker and OpenCode if needed,
# and creates the OpenCode configuration file.
# ============================================================================

set -e  # Exit on any error

echo "============================================"
echo "HP ZGX Nano - Nemotron Setup Script"
echo "Part 1: Prerequisites"
echo "============================================"
echo ""

# ----------------------------------------------------------------------------
# Step 1: Check NVIDIA GPU and CUDA
# ----------------------------------------------------------------------------
echo "[1/5] Checking NVIDIA GPU and CUDA..."

if command -v nvidia-smi &> /dev/null; then
    echo "✓ nvidia-smi found"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    echo ""
else
    echo "✗ nvidia-smi not found. Please ensure NVIDIA drivers are installed."
    exit 1
fi

# ----------------------------------------------------------------------------
# Step 2: Install Docker if not present
# ----------------------------------------------------------------------------
echo "[2/5] Checking Docker..."

if command -v docker &> /dev/null; then
    echo "✓ Docker is already installed"
    docker --version
else
    echo "Docker not found. Installing docker.io..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✓ Docker installed successfully"
    docker --version
fi

# Ensure current user is in the docker group
if groups $USER | grep -q '\bdocker\b'; then
    echo "✓ User '$USER' is already in the docker group"
else
    echo "Adding user '$USER' to the docker group..."
    sudo usermod -aG docker $USER
    echo "✓ User added to docker group"
    echo "  Note: You may need to log out and back in for this to take effect"
fi

echo ""

# ----------------------------------------------------------------------------
# Step 3: Install NVIDIA Container Toolkit if not present
# ----------------------------------------------------------------------------
echo "[3/5] Checking NVIDIA Container Toolkit..."

if dpkg -l | grep -q nvidia-container-toolkit; then
    echo "✓ NVIDIA Container Toolkit is already installed"
else
    echo "NVIDIA Container Toolkit not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker
    echo "✓ NVIDIA Container Toolkit installed successfully"
fi

# Verify Docker can access GPU
echo "Verifying Docker GPU access..."
if sudo docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi &> /dev/null; then
    echo "✓ Docker can access the GPU"
else
    echo "✗ Docker cannot access the GPU. Please check NVIDIA Container Toolkit installation."
    exit 1
fi

echo ""

# ----------------------------------------------------------------------------
# Step 4: Install OpenCode if not present
# ----------------------------------------------------------------------------
echo "[4/5] Checking OpenCode..."

if command -v opencode &> /dev/null; then
    echo "✓ OpenCode is already installed"
    opencode --version
else
    echo "OpenCode not found. Installing..."
    curl -fsSL https://opencode.ai/install | bash
    
    # Source bashrc to make opencode available in current session
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi
    
    echo "✓ OpenCode installed successfully"
    echo "Note: You may need to run 'source ~/.bashrc' or open a new terminal"
fi

echo ""

# ----------------------------------------------------------------------------
# Step 5: Create OpenCode configuration file
# ----------------------------------------------------------------------------
echo "[5/5] Creating OpenCode configuration file..."

mkdir -p ~/.config/opencode

cat > ~/.config/opencode/opencode.json << 'EOF'
{
    "$schema": "https://opencode.ai/config.json",
    "provider": {
        "nemotron": {
            "npm": "@ai-sdk/openai-compatible",
            "name": "Nemotron 3 Nano (HP ZGX Nano)",
            "options": {
                "baseURL": "http://127.0.0.1:8000/v1"
            },
            "models": {
                "cybermotaz/nemotron3-nano-nvfp4-w4a16": {
                    "name": "NVIDIA Nemotron 3 Nano 30B",
                    "limit": {
                        "context": 131072,
                        "output": 32768
                    }
                }
            }
        }
    }
}
EOF

echo "✓ OpenCode configuration created at ~/.config/opencode/opencode.json"

echo ""
echo "============================================"
echo "Prerequisites setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Run the second script to start the vLLM server:"
echo "   ./02-start-nemotron-server.sh"
echo ""
echo "2. Open a new terminal and launch OpenCode:"
echo "   cd ~/your-project-directory"
echo "   opencode"
echo ""
echo "3. In OpenCode, press / and type 'models' to select Nemotron"
echo ""