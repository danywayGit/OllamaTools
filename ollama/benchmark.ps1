param(
  [string]$Model = "qwen3-coder-30b-ctx128k",
  [int]$NumCtx = 128000,
  [int]$Rounds = 3,
  [double]$Temperature = 0.2,
  [double]$TopP = 0.9,
  [switch]$SkipWarmup
)

function Invoke-OllamaPrompt {
  param(
    [string]$model,
    [string]$prompt,
    [int]$numCtx,
    [double]$temperature,
    [double]$topP
  )
  $body = @{
    model   = $model
    prompt  = $prompt
    stream  = $false
    options = @{
      num_ctx     = $numCtx
      temperature = $temperature
      top_p       = $topP
    }
  } | ConvertTo-Json -Depth 3

  try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body
    $sw.Stop()
    # eval_count = tokens generated; prompt_eval_count = prompt tokens
    $tokens = if ($resp.eval_count) { $resp.eval_count } else { 0 }
    return @{
      text   = $resp.response
      ms     = $sw.ElapsedMilliseconds
      tokens = $tokens
    }
  } catch {
    Write-Host "Error: $_" -ForegroundColor Red
    return @{ text = ""; ms = 0; tokens = 0 }
  }
}

Write-Host "Benchmarking model: $Model (num_ctx=$NumCtx, temp=$Temperature, top_p=$TopP)" -ForegroundColor Cyan

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
foreach ($t in $tasks) {
  Write-Host "`n== $($t.name) ==" -ForegroundColor Yellow

  # Warmup run (not counted) to avoid first-load latency skew
  if (-not $SkipWarmup) {
    Write-Host "Warmup..." -ForegroundColor DarkGray
    $null = Invoke-OllamaPrompt -model $Model -prompt $t.prompt -numCtx $NumCtx -temperature $Temperature -topP $TopP
  }

  for ($i=1; $i -le $Rounds; $i++) {
    $r = Invoke-OllamaPrompt -model $Model -prompt $t.prompt -numCtx $NumCtx -temperature $Temperature -topP $TopP
    $tokSec = if ($r.ms -gt 0 -and $r.tokens -gt 0) { [math]::Round($r.tokens / ($r.ms / 1000), 1) } else { 0 }
    Write-Host ("Round {0}: {1} ms, {2} tokens, {3} tok/s" -f $i, $r.ms, $r.tokens, $tokSec)
    $results += [PSCustomObject]@{ Task = $t.name; Round = $i; Ms = $r.ms; Tokens = $r.tokens; TokSec = $tokSec }
  }
}

Write-Host "`nSummary:" -ForegroundColor Green
$results | Group-Object Task | ForEach-Object {
  $avgMs   = ($_.Group | Measure-Object Ms -Average).Average
  $avgTok  = ($_.Group | Measure-Object Tokens -Average).Average
  $avgTokS = ($_.Group | Measure-Object TokSec -Average).Average
  "{0}: avg={1:N0} ms, avg tokens={2:N0}, avg tok/s={3:N1}" -f $_.Name, $avgMs, $avgTok, $avgTokS
}
