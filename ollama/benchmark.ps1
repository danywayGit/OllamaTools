param(
  [string]$Model = "qwen3-coder-30b-ctx128k",
  [int]$NumCtx = 128000,
  [int]$Rounds = 3
)

function Invoke-OllamaPrompt($model, $prompt) {
  $body = @{ model = $model; prompt = $prompt; stream = $false } | ConvertTo-Json
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body
  $sw.Stop()
  return @{ text = $resp.response; ms = $sw.ElapsedMilliseconds }
}

Write-Host "Benchmarking model: $Model (num_ctx=$NumCtx)" -ForegroundColor Cyan

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
  for ($i=1; $i -le $Rounds; $i++) {
    $r = Invoke-OllamaPrompt -model $Model -prompt $t.prompt
    Write-Host ("Round $i: {0} ms" -f $r.ms)
    $results += [PSCustomObject]@{ Task = $t.name; Round = $i; Ms = $r.ms }
  }
}

Write-Host "`nSummary (ms):" -ForegroundColor Green
$results | Group-Object Task | ForEach-Object {
  $avg = ($_.Group | Measure-Object Ms -Average).Average
  "{0}: avg={1:N0} ms" -f $_.Name, $avg
}
