# HP ZGX Nano + NVIDIA Nemotron 3 + OpenCode

A fully local, enterprise-grade AI coding assistant running on HP ZGX Nano hardware with NVIDIA's Nemotron 3 Nano model.

## Overview

This repository contains setup scripts and demo materials for deploying a local AI coding assistant using:

| Component | Role | Key Specs |
|-----------|------|-----------|
| **HP ZGX Nano** | Hardware Platform | NVIDIA GB10 Grace Blackwell, ~120GB unified VRAM, CUDA 13.0 |
| **Nemotron 3 Nano** | LLM Backend | 30B params (3B active), 128K context, hybrid Mamba-Transformer MoE |
| **vLLM (Docker)** | Inference Server | High-throughput serving, OpenAI-compatible API |
| **OpenCode** | Coding Interface | Open-source TUI, agentic coding, tool calling |

**Value Proposition:** Zero cloud dependency, zero per-token costs, full data sovereignty, enterprise-grade performance.

## Performance

| Metric | Value |
|--------|-------|
| Prompt Throughput | 1,000-3,500 tokens/s |
| Generation Throughput | 25-57 tokens/s |
| VRAM Usage | ~11-12GB (FP4 quantization) |
| Context Window | 128K tokens |
| Time to First Token | <1s |

## Quick Start

### 1. Run Prerequisites Setup (One-Time)

```bash
chmod +x prereq-check-and-setup.sh
./prereq-check-and-setup.sh
```

This script will:
- Verify NVIDIA GPU and drivers
- Install Docker if not present
- Add current user to docker group
- Install NVIDIA Container Toolkit if not present
- Install OpenCode if not present
- Create the OpenCode configuration file

### 2. Start the Nemotron Server

```bash
chmod +x start-nemotron-server.sh
./start-nemotron-server.sh
```

Wait for the message: `Uvicorn running on http://0.0.0.0:8000`

**Note:** First startup downloads the model (~6-8GB) and takes a few minutes. Subsequent startups take ~1-2 minutes.

### 3. Launch OpenCode

In a new terminal:

```bash
cd ~/your-project-directory
opencode
```

Type `/models`, and select **NVIDIA Nemotron 3 Nano 30B**.

## Repository Contents

```
├── prereq-check-and-setup.sh    # Prerequisites and installation script
├── start-nemotron-server.sh     # vLLM server startup script
├── quick-test-opencode-prompts.txt   # Test prompts for verification
├── multifile-analysis-prompt.txt     # Demo scenario for multi-file analysis
└── README.md
```

## Test Prompts

After setup, verify the system is working with these prompts in OpenCode:

```
# Test 1: Basic code generation
Create a Python class for managing a simple todo list with add, remove, and list methods.

# Test 2: File operations
Read the contents of README.md and summarize it.

# Test 3: Reasoning mode
Analyze this codebase and suggest three improvements for maintainability.
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     HP ZGX Nano                             │
│                  (NVIDIA GB10 Superchip)                    │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │   OpenCode      │───▶│  vLLM Server (Docker)           ││
│  │   (TUI Client)  │    │  Port 8000                      ││
│  │                 │◀───│                                 ││
│  └─────────────────┘    │  ┌───────────────────────────┐ ││
│                         │  │ Nemotron 3 Nano           │ ││
│                         │  │ (FP4 Quantization)        │ ││
│                         │  └───────────────────────────┘ ││
│                         └─────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Key Commands

```bash
# Start the server
./start-nemotron-server.sh

# Stop the server
sudo docker stop $(sudo docker ps -q)

# View server logs
sudo docker logs -f $(sudo docker ps -q)

# Monitor GPU usage
watch -n 1 nvidia-smi

# Check model endpoint
curl http://localhost:8000/v1/models
```

## Troubleshooting

### OpenCode can't connect
```bash
# Verify server is running
curl http://localhost:8000/v1/models

# Check config file
cat ~/.config/opencode/opencode.json
```

### "Model does not exist" error
The model name in OpenCode config must exactly match what vLLM reports. Verify with:
```bash
curl http://localhost:8000/v1/models
```

### Slow first request
This is normal, the first request warms up the cache. Subsequent requests will be faster (2-20 seconds with reasoning).

### Permission denied on Docker
```bash
# Either use sudo, or ensure you're in the docker group
sudo docker ps

# If not in docker group, add yourself and re-login
sudo usermod -aG docker $USER
```

## License

This project uses:
- **Nemotron 3 Nano**: [NVIDIA Open Model License](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/)
- **vLLM**: Apache 2.0
- **OpenCode**: MIT

## Author

Curtis Burkhalter,Ph.D., Technical Product Marketing Manager — AI Developer Tools & HP ZGX Nano; curtis.burkhalter@hp.com or curtisburkhalter@gmail.com
