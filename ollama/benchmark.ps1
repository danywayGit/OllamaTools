<#
.SYNOPSIS
Benchmark Ollama models for coding with task mode or matrix mode.

.DESCRIPTION
This script supports two benchmark styles:
- tasks mode: runs coding tasks (completion/refactor/explain) and reports average latency and throughput.
- matrix mode: sweeps context and batch settings, prints CSV output, and ranks top configurations.

Use CompareModel to run head-to-head comparisons.

.EXAMPLE
./benchmark.ps1 -Mode tasks -Model "qwen3.6-27b-code" -NumCtx 32768 -Rounds 2 -SkipWarmup

Runs task benchmarks for one model with 32k context and 2 rounds.

.EXAMPLE
./benchmark.ps1 -Mode matrix -Model "qwen3.6:27b-q4_K_M" -CompareModel "qwen3.6-27b-code" -MatrixNumCtx 16384,32768 -MatrixNumBatch 256,512 -NumPredict 180 -PauseMs 250

Runs a head-to-head matrix sweep and prints ranking + CSV.
#>

param(
  [string]$Model = "qwen3-coder-30b-ctx128k",
  [int]$NumCtx = 128000,
  [int]$Rounds = 3,
  [double]$Temperature = 0.2,
  [double]$TopP = 0.9,
  [switch]$SkipWarmup,
  # Head-to-head comparison: supply a second model name to benchmark both side-by-side
  [string]$CompareModel = "",
  [int]$CompareNumCtx = 32768,
  [ValidateSet("tasks", "matrix")]
  [string]$Mode = "tasks",
  [int]$NumBatch = 512,
  [int]$NumPredict = 220,
  [int]$TopK = 40,
  [double]$RepeatPenalty = 1.1,
  [double]$MinP = 0.05,
  [string]$SystemPrompt = "You are a coding assistant. Return concise production-ready code.",
  [string]$MatrixPrompt = "Write a Python LRU cache with type hints and 3 pytest tests.",
  [int[]]$MatrixNumCtx = @(16384, 32768),
  [int[]]$MatrixNumBatch = @(256, 512),
  [int]$PauseMs = 500
)

function Invoke-OllamaPrompt {
  param(
    [string]$model,
    [string]$prompt,
    [int]$numCtx,
    [int]$numBatch,
    [int]$numPredict,
    [double]$temperature,
    [double]$topP,
    [int]$topK,
    [double]$repeatPenalty,
    [double]$minP,
    [string]$systemPrompt
  )

  $body = @{
    model   = $model
    prompt  = $prompt
    system  = $systemPrompt
    stream  = $false
    options = @{
      num_ctx     = $numCtx
      num_batch   = $numBatch
      num_predict = $numPredict
      temperature = $temperature
      top_p       = $topP
      top_k       = $topK
      repeat_penalty = $repeatPenalty
      min_p       = $minP
    }
  } | ConvertTo-Json -Depth 5

  try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body
    $sw.Stop()

    $tokens = if ($resp.eval_count) { $resp.eval_count } else { 0 }
    $promptTokS = if ($resp.prompt_eval_duration -gt 0) {
      [math]::Round($resp.prompt_eval_count / ($resp.prompt_eval_duration / 1e9), 2)
    } else { 0 }
    $genTokS = if ($resp.eval_duration -gt 0) {
      [math]::Round($resp.eval_count / ($resp.eval_duration / 1e9), 2)
    } else { 0 }
    $totalMs = if ($resp.total_duration -gt 0) {
      [math]::Round($resp.total_duration / 1e6, 1)
    } else { $sw.ElapsedMilliseconds }

    return @{
      ok         = $true
      text       = $resp.response
      ms         = $sw.ElapsedMilliseconds
      totalMs    = $totalMs
      tokens     = $tokens
      promptTokS = $promptTokS
      genTokS    = $genTokS
      error      = ""
    }
  } catch {
    Write-Host "Error: $_" -ForegroundColor Red
    return @{
      ok         = $false
      text       = ""
      ms         = 0
      totalMs    = 0
      tokens     = 0
      promptTokS = 0
      genTokS    = 0
      error      = $_.Exception.Message
    }
  }
}

$modelsToRun = @(@{ Name = $Model; NumCtx = $NumCtx })
if ($CompareModel -ne "") {
  $modelsToRun += @{ Name = $CompareModel; NumCtx = $CompareNumCtx }
  Write-Host "HEAD-TO-HEAD comparison mode" -ForegroundColor Magenta
  if ($Mode -eq "matrix") {
    Write-Host ("  Model A : {0} (matrix ctx={1})" -f $Model, ($MatrixNumCtx -join ",")) -ForegroundColor Cyan
    Write-Host ("  Model B : {0} (matrix ctx={1})" -f $CompareModel, ($MatrixNumCtx -join ",")) -ForegroundColor Cyan
  } else {
    Write-Host ("  Model A : {0} (num_ctx={1})" -f $Model, $NumCtx) -ForegroundColor Cyan
    Write-Host ("  Model B : {0} (num_ctx={1})" -f $CompareModel, $CompareNumCtx) -ForegroundColor Cyan
  }
} else {
  Write-Host "Benchmarking model: $Model (num_ctx=$NumCtx, temp=$Temperature, top_p=$TopP)" -ForegroundColor Cyan
}

if ($Mode -eq "matrix") {
  Write-Host "`n===== MATRIX MODE =====" -ForegroundColor Green
  Write-Host ("Prompt: {0}" -f $MatrixPrompt) -ForegroundColor DarkCyan

  $matrixResults = @()
  foreach ($mdl in $modelsToRun) {
    $mName = $mdl.Name
    Write-Host ("`n=== Model: {0} ===" -f $mName) -ForegroundColor Magenta

    foreach ($ctx in $MatrixNumCtx) {
      foreach ($batch in $MatrixNumBatch) {
        Write-Host ("  Run: ctx={0}, batch={1}" -f $ctx, $batch) -ForegroundColor Yellow

        $r = Invoke-OllamaPrompt `
          -model $mName `
          -prompt $MatrixPrompt `
          -numCtx $ctx `
          -numBatch $batch `
          -numPredict $NumPredict `
          -temperature $Temperature `
          -topP $TopP `
          -topK $TopK `
          -repeatPenalty $RepeatPenalty `
          -minP $MinP `
          -systemPrompt $SystemPrompt

        $matrixResults += [PSCustomObject]@{
          Model      = $mName
          NumCtx     = $ctx
          NumBatch   = $batch
          PromptTokS = $r.promptTokS
          GenTokS    = $r.genTokS
          Tokens     = $r.tokens
          TotalMs    = $r.totalMs
          Status     = if ($r.ok) { "OK" } else { "ERROR" }
          Error      = $r.error
        }

        if ($r.ok) {
          Write-Host ("    prompt tok/s={0}, gen tok/s={1}, total ms={2}" -f $r.promptTokS, $r.genTokS, $r.totalMs)
        }

        if ($PauseMs -gt 0) {
          Start-Sleep -Milliseconds $PauseMs
        }
      }
    }
  }

  Write-Host "`n===== RAW MATRIX =====" -ForegroundColor Green
  $matrixResults | Format-Table -Property Model, NumCtx, NumBatch, PromptTokS, GenTokS, Tokens, TotalMs, Status -AutoSize

  Write-Host "`n===== CSV =====" -ForegroundColor Green
  Write-Host "model,num_ctx,num_batch,prompt_tok_s,gen_tok_s,tokens,total_ms,status"
  $matrixResults | ForEach-Object {
    "{0},{1},{2},{3},{4},{5},{6},{7}" -f $_.Model, $_.NumCtx, $_.NumBatch, $_.PromptTokS, $_.GenTokS, $_.Tokens, $_.TotalMs, $_.Status
  }

  $okRows = $matrixResults | Where-Object Status -eq "OK"
  if ($okRows.Count -gt 0) {
    Write-Host "`n===== TOP 3 (gen tok/s desc, total ms asc) =====" -ForegroundColor Magenta
    $top3 = $okRows | Sort-Object -Property @{ Expression = "GenTokS"; Descending = $true }, @{ Expression = "TotalMs"; Descending = $false } | Select-Object -First 3
    $top3 | Format-Table -Property Model, NumCtx, NumBatch, GenTokS, PromptTokS, TotalMs -AutoSize

    $ctx16 = $okRows | Where-Object NumCtx -eq 16384 | Measure-Object GenTokS -Average
    $ctx32 = $okRows | Where-Object NumCtx -eq 32768 | Measure-Object GenTokS -Average
    if ($ctx16.Count -gt 0 -and $ctx32.Count -gt 0) {
      $deltaCtx = [math]::Round($ctx16.Average - $ctx32.Average, 2)
      Write-Host ("Context impact (16k - 32k gen tok/s): {0}" -f $deltaCtx) -ForegroundColor Cyan
    }

    $b256 = $okRows | Where-Object NumBatch -eq 256 | Measure-Object GenTokS -Average
    $b512 = $okRows | Where-Object NumBatch -eq 512 | Measure-Object GenTokS -Average
    if ($b256.Count -gt 0 -and $b512.Count -gt 0) {
      $deltaBatch = [math]::Round($b512.Average - $b256.Average, 2)
      Write-Host ("Batch impact (512 - 256 gen tok/s): {0}" -f $deltaBatch) -ForegroundColor Cyan
    }
  } else {
    Write-Host "No successful matrix runs to rank." -ForegroundColor Red
  }

  return
}

$longCode = @"
# Generate N primes (inefficient on purpose to test reasoning)
import math

def is_prime(n):
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    r = int(math.sqrt(n))
    f = 3
    while f <= r:
        if n % f == 0:
            return False
        f += 2
    return True

def primes(n):
    out = []
    x = 2
    while len(out) < n:
        if is_prime(x):
            out.append(x)
        x += 1
    return out

print(primes(1000))
"@

$tasks = @(
  @{ name = "Small completion"; prompt = "Write a Python function to reverse a string with type hints and tests." },
  @{ name = "Refactor"; prompt = "Refactor the following code for readability and performance:\n\n$longCode" },
  @{ name = "Explain"; prompt = "Explain time complexity and propose optimizations for the given code:\n\n$longCode" }
)

$results = @()
foreach ($mdl in $modelsToRun) {
  $mName   = $mdl.Name
  $mNumCtx = $mdl.NumCtx
  Write-Host ("`n=== Model: {0} (num_ctx={1}) ===" -f $mName, $mNumCtx) -ForegroundColor Magenta

  foreach ($t in $tasks) {
    Write-Host "`n  -- $($t.name) --" -ForegroundColor Yellow

    if (-not $SkipWarmup) {
      Write-Host "  Warmup..." -ForegroundColor DarkGray
      $null = Invoke-OllamaPrompt `
        -model $mName `
        -prompt $t.prompt `
        -numCtx $mNumCtx `
        -numBatch $NumBatch `
        -numPredict $NumPredict `
        -temperature $Temperature `
        -topP $TopP `
        -topK $TopK `
        -repeatPenalty $RepeatPenalty `
        -minP $MinP `
        -systemPrompt $SystemPrompt
    }

    for ($i = 1; $i -le $Rounds; $i++) {
      $r = Invoke-OllamaPrompt `
        -model $mName `
        -prompt $t.prompt `
        -numCtx $mNumCtx `
        -numBatch $NumBatch `
        -numPredict $NumPredict `
        -temperature $Temperature `
        -topP $TopP `
        -topK $TopK `
        -repeatPenalty $RepeatPenalty `
        -minP $MinP `
        -systemPrompt $SystemPrompt

      Write-Host ("  Round {0}: total={1} ms, tokens={2}, prompt tok/s={3}, gen tok/s={4}" -f $i, $r.totalMs, $r.tokens, $r.promptTokS, $r.genTokS)
      $results += [PSCustomObject]@{
        Model      = $mName
        Task       = $t.name
        Round      = $i
        Ms         = $r.ms
        TotalMs    = $r.totalMs
        Tokens     = $r.tokens
        PromptTokS = $r.promptTokS
        GenTokS    = $r.genTokS
      }
    }
  }
}

Write-Host "`n===== SUMMARY =====" -ForegroundColor Green
$results | Group-Object Model | ForEach-Object {
  $mName = $_.Name
  Write-Host ("`nModel: {0}" -f $mName) -ForegroundColor Cyan
  $_.Group | Group-Object Task | ForEach-Object {
    $avgMs   = ($_.Group | Measure-Object TotalMs -Average).Average
    $avgTok  = ($_.Group | Measure-Object Tokens -Average).Average
    $avgPromptTokS = ($_.Group | Measure-Object PromptTokS -Average).Average
    $avgGenTokS = ($_.Group | Measure-Object GenTokS -Average).Average
    "  {0}: avg={1:N0} ms, avg tokens={2:N0}, avg prompt tok/s={3:N1}, avg gen tok/s={4:N1}" -f $_.Name, $avgMs, $avgTok, $avgPromptTokS, $avgGenTokS
  }
}

# If comparison mode: print delta table
if ($CompareModel -ne "") {
  Write-Host "`n===== DELTA (B vs A, positive = B is faster/better) =====" -ForegroundColor Magenta
  $aggA = $results | Where-Object Model -eq $Model        | Group-Object Task
  $aggB = $results | Where-Object Model -eq $CompareModel | Group-Object Task

  foreach ($gA in $aggA) {
    $gB = $aggB | Where-Object Name -eq $gA.Name
    if (-not $gB) { continue }
    $avgMsA   = ($gA.Group | Measure-Object TotalMs -Average).Average
    $avgTokSA = ($gA.Group | Measure-Object GenTokS -Average).Average
    $avgMsB   = ($gB.Group | Measure-Object TotalMs -Average).Average
    $avgTokSB = ($gB.Group | Measure-Object GenTokS -Average).Average
    $deltaTokS = [math]::Round($avgTokSB - $avgTokSA, 2)
    $deltaMs   = [math]::Round($avgMsA   - $avgMsB,   0)   # positive = B is faster
    $sign      = if ($deltaTokS -ge 0) { "+" } else { "" }
    "  {0}: latency delta={1:N0} ms, gen tok/s delta={2}{3:N2}" -f $gA.Name, $deltaMs, $sign, $deltaTokS
  }
}
