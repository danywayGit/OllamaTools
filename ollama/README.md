# Ollama Modelfiles and Benchmark

Build Ollama models with **128k context window** and use them with VS Code + GitHub Copilot.

## Prerequisites

- [Ollama](https://ollama.ai/) installed and running
- Base models pulled (e.g., `ollama pull qwen3-coder:30b`)
- VS Code with GitHub Copilot extension

## Quick Start

### 1. Build Custom 128k Context Models

```powershell
cd ollama

# Create models with 128k context baked in
ollama create qwen3-coder-30b-ctx128k -f ./Modelfile.qwen3-coder-30b-ctx128k
ollama create qwen3-30b-ctx128k -f ./Modelfile.qwen3-30b-ctx128k
ollama create gpt-oss-latest-ctx128k -f ./Modelfile.gpt-oss-latest-ctx128k
```

### 2. Verify Models

```powershell
ollama list
# You should see qwen3-coder-30b-ctx128k, etc.
```

### 3. Start Ollama Server

```powershell
ollama serve
```

## Using with VS Code + GitHub Copilot

VS Code's Copilot Chat supports Ollama as a built-in model provider.

### Setup

1. Open **Copilot Chat** in VS Code
2. Click the **model picker** (model name in chat input)
3. Select **Manage Models**
4. Find **Ollama** in the provider list → click the **gear icon**
5. VS Code will detect your running Ollama models
6. Select `qwen3-coder-30b-ctx128k` from the list

### Usage

Once configured, select your 128k model from the Copilot model picker. The 128k context is automatically used because it's baked into the Modelfile — no extra settings needed.

> **Note:** Using Ollama with Copilot still requires a GitHub account with Copilot access (Free tier works) and internet connectivity for some Copilot features.

## Benchmark

Run latency and throughput benchmarks against your models:

```powershell
# Basic benchmark (3 rounds per task, warmup enabled)
./benchmark.ps1 -Model qwen3-coder-30b-ctx128k -NumCtx 128000 -Rounds 3

# Skip warmup for faster runs
./benchmark.ps1 -Model qwen3-coder-30b-ctx128k -Rounds 2 -SkipWarmup

# Custom temperature/top_p
./benchmark.ps1 -Model qwen3-30b-ctx128k -Temperature 0.3 -TopP 0.95 -Rounds 3
```

### Benchmark Output

The script runs three tasks (small completion, refactor, explain) and reports:
- Latency (ms)
- Tokens generated
- Throughput (tokens/sec)

Example output:
```
== Small completion ==
Warmup...
Round 1: 14801 ms, 429 tokens, 29 tok/s
Round 2: 15261 ms, 427 tokens, 28 tok/s

Summary:
Small completion: avg=15031 ms, avg tokens=428, avg tok/s=28.5
```

## Modelfile Configuration

Each Modelfile sets:
- `num_ctx 128000` — 128k token context window
- `temperature` — controls randomness (0.2 for code, 0.3 for general)
- `top_p` — nucleus sampling threshold
- `SYSTEM` — role-specific system prompt

Example (`Modelfile.qwen3-coder-30b-ctx128k`):
```
FROM qwen3-coder:30b
PARAMETER num_ctx 128000
PARAMETER temperature 0.2
PARAMETER top_p 0.9
SYSTEM You are a helpful coding assistant...
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| OOM errors | Reduce `num_ctx` in Modelfile or use smaller quantization |
| Model not in Copilot | Ensure `ollama serve` is running, then refresh Manage Models |
| Slow first response | Normal — first call loads model into VRAM; use warmup |
| Model not found | Run `ollama list` to verify model name exactly |

## Notes

- 128k context requires significant VRAM (~20-40GB for 30B models)
- The `-ctx128k` suffix is just a naming convention — context is set in the Modelfile
- You can create multiple variants with different settings (e.g., `-ctx64k`, `-creative`)\n