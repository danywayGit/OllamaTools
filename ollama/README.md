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
ollama pull qwen3.8:27b-q4_K_M

# Create custom models
ollama create qwen3-coder-30b-ctx128k -f ./Modelfile.qwen3-coder-30b-ctx128k
ollama create qwen3-30b-ctx128k -f ./Modelfile.qwen3-30b-ctx128k
ollama create gpt-oss-latest-ctx128k -f ./Modelfile.gpt-oss-latest-ctx128k
ollama create qwen3.5-uncensured -f ./Modelfile.qwen3.5-ctx32k-uncensured
```

## qwen3.8: Code + Finance Models (Thinking & Non-Thinking)

Hybrid Modelfiles built on `qwen3.8:27b-q4_K_M` (18GB, 256K native context) tuned for
**coding + quantitative finance**. Four context sizes (16k / 20k / 24k / 32k), each in two
thinking variants. Context is **reduced** from the native 256K to save VRAM and speed up
inference — no quality loss, just a smaller window.

- `-think` — reasoning enabled (default for Qwen3.8). Better for complex code design and
  multi-step financial analysis; uses more context/tokens for the reasoning step.
- `-nothink` — thinking disabled via a system-prompt directive. Rapid, deterministic
  responses, ideal for high-volume or real-time finance calls.

```powershell
# Pull the base model first (Run once)
ollama pull qwen3.8:27b-q4_K_M

# Thinking variants
ollama create qwen3.8-27b-ctx16k-code-finance-think   -f ./Modelfile.qwen3.8-27b-ctx16k-code-finance-think
ollama create qwen3.8-27b-ctx20k-code-finance-think   -f ./Modelfile.qwen3.8-27b-ctx20k-code-finance-think
ollama create qwen3.8-27b-ctx24k-code-finance-think   -f ./Modelfile.qwen3.8-27b-ctx24k-code-finance-think
ollama create qwen3.8-27b-ctx32k-code-finance-think   -f ./Modelfile.qwen3.8-27b-ctx32k-code-finance-think
ollama create qwen3.8-27b-ctx64k-code-finance-think   -f ./Modelfile.qwen3.8-27b-ctx64k-code-finance-think

# Non-thinking variants (faster / deterministic)
ollama create qwen3.8-27b-ctx16k-code-finance-nothink -f ./Modelfile.qwen3.8-27b-ctx16k-code-finance-nothink
ollama create qwen3.8-27b-ctx20k-code-finance-nothink -f ./Modelfile.qwen3.8-27b-ctx20k-code-finance-nothink
ollama create qwen3.8-27b-ctx24k-code-finance-nothink -f ./Modelfile.qwen3.8-27b-ctx24k-code-finance-nothink
ollama create qwen3.8-27b-ctx32k-code-finance-nothink -f ./Modelfile.qwen3.8-27b-ctx32k-code-finance-nothink
ollama create qwen3.8-27b-ctx64k-code-finance-nothink -f ./Modelfile.qwen3.8-27b-ctx64k-code-finance-nothink
```

Quick smoke-test one model:

```powershell
ollama run qwen3.8-27b-ctx32k-code-finance-nothink \
  "Write a Python function computing SMA, RSI(14) and max drawdown from a list of OHLCV dicts."
```

### Benchmarking the qwen3.8 models

The benchmark script now supports a `-Think` switch to pass the `think` API flag, which is the
reliable way to control Qwen3.8's reasoning mode (the baked SOMETIMES system-prompt directive
is bypassed when `-SystemPrompt` overrides it in the API call).

```powershell
# Fast path: non-thinking model, task mode
./benchmark.ps1 -Mode tasks -Model qwen3.8-27b-ctx32k-code-finance-nothink -NumCtx 32768 -Rounds 2 -Think off

# Head-to-head thinking vs non-thinking at 16k context
./benchmark.ps1 -Mode tasks -Model qwen3.8-27b-ctx16k-code-finance-think -CompareModel qwen3.8-27b-ctx16k-code-finance-nothink -NumCtx 16384 -CompareNumCtx 16384 -Think auto

# Parameter/context sweep across all four context sizes
./benchmark.ps1 -Mode matrix -Model qwen3.8-27b-ctx16k-code-finance-nothink -MatrixNumCtx 16384,20480,24576,32768 -MatrixNumBatch 256,512 -Think off
```

### qwen3.8 benchmark results (2026-08)

Hardware: local, 27B q4 K_M (~18 GB). Reference Apple-to-Apple gen tok/s through the API with
the same prompt (max drawdown + RSI(14) in Python).

| Context | Batch | Prompt tok/s | Gen tok/s | Total ms | Notes |
|--------:|------:|-------------:|----------:|---------:|-------|
| 16384 | 256 | 215.2 | 33.8 | 18 360 | Latency worst for small ctx |
| 16384 | 512 | 302.0 | 42.8 | 10 642 | **batch 512 much faster** |
| 20480 | 512 | 305.8 | **44.3** | 10 444 | Best gen tok/s |
| 24576 | 256 | 315.5 | 43.8 | 10 540 | |
| 32768 | 512 | 296.3 | 44.3 | 10 476 | Fastest total; ctx scales w/o collapse |

> **Context impact** (16k → 32k): generation stays ~44 tok/s at batch 512 — context scaling does
> not collapse throughput through 32k. **Batch 512 is strongly preferred** over 256 (+3 tok/s and
> much lower latency at small ctx).

**Thinking vs. non-thinking overhead** (identical prompt, `think` flag via API):

| Variant | Eval tokens | Gen tok/s | Total ms | Thinking output |
|---------|-----------:|----------:|--------:|-----------------|
| `-think` 16k | 1829 | 42.9 | 43 404 | Reasoning trace (~1 479 chars) |
| `-nothink` 16k | 2270 | 41.9 | 54 673 | None (direct answer) |

**How to read these numbers:**
- All 8 variants share the **same base weights + quantization**, so raw generation throughput is
  uniform (~42-44 tok/s). The differentiators are **context size** and **thinking behavior**.
- `-think` returns a reasoning trace before the answer (better for complex design/analysis), but
  thinking token counts are not strictly higher — `-nothink` often elaborates *more in prose*.
- Choose `-nothink` for routine/fast/call-time work, `-think` for hard multi-step problems.

> **Note:** These models share the same base tag and code+finance system prompt; they differ
> only in `num_ctx` and the thinking directive. Pick a single `-nothink` size for routine work
> and a `-think` size for hard problems to avoid duplicating VRAM usage.

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