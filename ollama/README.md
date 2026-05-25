# Ollama Modelfiles and Benchmark

Build Ollama models with **custom context windows** (128k, 256k, etc.) and use them with VS Code + GitHub Copilot.

## Prerequisites

- [Ollama](https://ollama.ai/) installed
- VS Code with GitHub Copilot extension

## Creating a Custom Context Model (Step-by-Step)

Follow these steps to create any Ollama model with a custom context window:

### Step 1: Start Ollama Server

```powershell
ollama serve
```

### Step 2: Pull the Base Model

```powershell
# Pull the model you want to customize
ollama pull qwen3-coder:30b      # For coding
ollama pull qwen3:30b            # For general use
ollama pull qwen3-vl:32b         # For vision/multimodal
```

### Step 3: Create a Modelfile

Create a text file named `Modelfile.<your-model-name>` with the following structure:

**Example 1: Coding Model (128k context)**
```
FROM qwen3-coder:30b
PARAMETER num_ctx 128000
PARAMETER temperature 0.2
PARAMETER top_p 0.9
SYSTEM You are a helpful coding assistant. Prefer clear, correct code with minimal dependencies. Explain briefly when asked.
```

**Example 2: Vision/Multimodal Model (256k context)**
```
FROM qwen3-vl:32b
PARAMETER num_ctx 256000
PARAMETER temperature 0.3
PARAMETER top_p 0.9
SYSTEM You are a helpful multimodal assistant with vision capabilities. You can analyze images and provide detailed descriptions, answer questions about visual content, and assist with tasks that require both text and image understanding.
```

> **Note:** Use hyphens `-` in filenames, not colons `:` (Windows doesn't allow colons in filenames).

### Step 4: Create the Custom Model

```powershell
cd ollama

# Create model from your Modelfile
ollama create qwen3-coder-30b-ctx128k -f ./Modelfile.qwen3-coder-30b-ctx128k
ollama create qwen3-vl-32b-ctx256k -f ./Modelfile.qwen3-vl-32b-ctx256k
ollama create qwen3.5-uncensured -f ./Modelfile.qwen3.5-ctx32k-uncensured
```

### Step 5: Verify Your Model

```powershell
ollama list
# You should see your custom model (e.g., qwen3-coder-30b-ctx128k)
```

## Quick Start (Using Existing Modelfiles)

If you want to use the pre-made Modelfiles in this repo:

```powershell
cd ollama

# Pull base models first
ollama pull qwen3-coder:30b
ollama pull qwen3:30b
ollama pull qwen3-vl:8b

# Create custom models
ollama create qwen3-coder-30b-ctx128k -f ./Modelfile.qwen3-coder-30b-ctx128k
ollama create qwen3-30b-ctx128k -f ./Modelfile.qwen3-30b-ctx128k
ollama create gpt-oss-latest-ctx128k -f ./Modelfile.gpt-oss-latest-ctx128k
ollama create qwen3.5-uncensured -f ./Modelfile.qwen3.5-ctx32k-uncensured
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

Run latency and throughput benchmarks against your models.

The script supports two modes:
- `tasks` (default): scenario-style coding tasks (completion, refactor, explain)
- `matrix`: parameter sweep across context and batch sizes with ranking + CSV output

```powershell
# Task mode (default): 3 rounds per task, warmup enabled
./benchmark.ps1 -Mode tasks -Model qwen3-coder-30b-ctx128k -NumCtx 128000 -Rounds 3

# Task mode, skip warmup for faster iteration
./benchmark.ps1 -Mode tasks -Model qwen3-coder-30b-ctx128k -Rounds 2 -SkipWarmup

# Matrix mode: head-to-head sweep for qwen3.6 27b variants
./benchmark.ps1 -Mode matrix -Model qwen3.6:27b-q4_K_M -CompareModel qwen3.6-27b-code -MatrixNumCtx 16384,32768 -MatrixNumBatch 256,512 -NumPredict 180 -PauseMs 250

# Matrix mode with custom prompt/system tuning
./benchmark.ps1 -Mode matrix -Model qwen3.6-27b-code -MatrixPrompt "Write a robust async HTTP retry helper in Python." -SystemPrompt "You are a coding assistant. Return concise production-ready code." -MatrixNumCtx 16384 -MatrixNumBatch 256,512
```

### Benchmark Output

In both modes, the script reports:
- `total_ms` (end-to-end latency)
- generated token count
- prompt throughput (`prompt tok/s`)
- generation throughput (`gen tok/s`)

`matrix` mode additionally prints:
- raw result table
- CSV lines for easy export
- top 3 ranked configurations (by `gen tok/s`, tie-breaker `total_ms`)
- context impact (`16k - 32k`) and batch impact (`512 - 256`)

Task mode sample:
```
=== Model: qwen3.6-27b-code (num_ctx=32768) ===

	-- Small completion --
Warmup...
Round 1: total=11742.3 ms, tokens=180, prompt tok/s=504.1, gen tok/s=31.8
Round 2: total=11406.8 ms, tokens=180, prompt tok/s=497.6, gen tok/s=32.5

===== SUMMARY =====
Small completion: avg=11,575 ms, avg tokens=180, avg prompt tok/s=500.9, avg gen tok/s=32.1
```

Matrix mode sample:
```
===== TOP 3 (gen tok/s desc, total ms asc) =====

Model            NumCtx NumBatch GenTokS PromptTokS  TotalMs
-----            ------ -------- ------- ----------  -------
qwen3.6-27b-code  32768      512   36.05     479.03 11179.50
qwen3.6-27b-code  32768      256   36.04     391.08 11326.60
qwen3.6-27b-code  16384      256   32.16     518.51 11858.20
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