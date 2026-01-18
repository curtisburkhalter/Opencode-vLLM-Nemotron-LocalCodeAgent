#!/bin/bash

# ============================================================================
# HP ZGX Nano + NVIDIA Nemotron 3 + OpenCode
# Script 2: Start/Restart Nemotron vLLM Server
# ============================================================================
# This script pulls the vLLM Docker image (if needed) and starts the
# Nemotron 3 Nano inference server. If a container is already running
# on port 8000, it will be stopped first.
# ============================================================================

echo "============================================"
echo "HP ZGX Nano - Nemotron Server"
echo "Part 2: Start vLLM Server"
echo "============================================"
echo ""

# ----------------------------------------------------------------------------
# Step 1: Check for existing container on port 8000
# ----------------------------------------------------------------------------
echo "[1/3] Checking for existing containers..."

EXISTING_CONTAINER=$(sudo docker ps -q --filter "publish=8000")

if [ -n "$EXISTING_CONTAINER" ]; then
    echo "Found existing container on port 8000. Stopping it..."
    sudo docker stop $EXISTING_CONTAINER
    echo "✓ Existing container stopped"
else
    echo "✓ No existing container on port 8000"
fi

echo ""

# ----------------------------------------------------------------------------
# Step 2: Pull the vLLM Docker image (if not already cached)
# ----------------------------------------------------------------------------
echo "[2/3] Checking Docker image..."

IMAGE_NAME="avarok/vllm-dgx-spark:v11"

if sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
    echo "✓ Docker image already cached: $IMAGE_NAME"
else
    echo "Pulling Docker image: $IMAGE_NAME"
    echo "This may take a few minutes on first run..."
    sudo docker pull $IMAGE_NAME
    echo "✓ Docker image pulled successfully"
fi

echo ""

# ----------------------------------------------------------------------------
# Step 3: Start the vLLM server
# ----------------------------------------------------------------------------
echo "[3/3] Starting Nemotron 3 Nano vLLM server..."
echo ""
echo "Server will be ready when you see:"
echo "  'Uvicorn running on http://0.0.0.0:8000'"
echo ""
echo "First startup downloads the model (~6-8GB) and takes a few minutes."
echo "Subsequent startups take ~1-2 minutes to load the model."
echo ""
echo "Press Ctrl+C to stop the server."
echo ""
echo "============================================"
echo ""

sudo docker run --rm -it --gpus all --ipc=host -p 8000:8000 \
  -e VLLM_FLASHINFER_MOE_BACKEND=latency \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  avarok/vllm-dgx-spark:v11 \
  serve cybermotaz/nemotron3-nano-nvfp4-w4a16 \
  --quantization modelopt_fp4 \
  --kv-cache-dtype fp8 \
  --trust-remote-code \
  --max-model-len 131072 \
  --gpu-memory-utilization 0.95 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --reasoning-parser deepseek_r1