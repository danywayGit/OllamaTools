# Two-Model Trading Analysis Pipeline

Combine quantitative data analysis with visual chart analysis for better trading decisions.

## Architecture

```
Raw Data (CSV/JSON) → Qwen Text Model (Quant) → Numerical Context → Qwen-VL (Trading) + Chart → Final Analysis
```

## Models Setup

### Model 1: Quantitative Data Analyzer
**File:** `Modelfile.qwen3-coder-30b-ctx128k-quant`

**Purpose:** Analyze raw OHLCV data, calculate indicators, detect statistical patterns

**Create:**
```powershell
cd ollama
ollama create qwen3-coder-30b-ctx128k-quant -f ./Modelfile.qwen3-coder-30b-ctx128k-quant
```

### Model 2: Visual Chart Analyzer
**File:** `Modelfile.qwen3-vl-8b-ctx32k-trading`

**Purpose:** Analyze chart images, identify patterns, provide trade setups

**Already created:** `qwen3-vl-8b-ctx32k-trading`

## Key Differences

| Model | Purpose | Input | Output | Strength |
|-------|---------|-------|--------|----------|
| **qwen3-coder-quant** | Data analysis | CSV, JSON, numbers | Statistical insights, calculations | Precise math, patterns in numbers |
| **qwen3-vl-trading** | Chart analysis | Images + text | Visual patterns, trade setups | Pattern recognition, chart reading |

## Python Implementation

### Complete Workflow Script

```python
import ollama
import pandas as pd

def analyze_raw_data(df, symbol):
    """Step 1: Analyze OHLCV data with quant model"""
    
    # Prepare data summary
    recent = df.tail(100)
    
    data_summary = f"""
Recent 100 candles for {symbol}:
Open: {recent['open'].to_list()}
High: {recent['high'].to_list()}
Low: {recent['low'].to_list()}
Close: {recent['close'].to_list()}
Volume: {recent['volume'].to_list()}

Current price: {df['close'].iloc[-1]}
Current volume: {df['volume'].iloc[-1]}
"""
    
    prompt = f"""
Analyze {symbol} OHLCV data:

{data_summary}

Calculate and provide:
1. Momentum: 5/10/20 period % change
2. Volatility: ATR and percentile rank
3. Volume trend: current vs 20-period MA (% difference)
4. Key price levels: recent highs/lows, pivot points
5. Moving averages: 20/50/200 period positions
6. RSI estimation (if calculable from data)
7. Price structure: higher highs, lower lows?
8. Statistical anomalies or outliers

Output precise numbers with specific price levels.
"""
    
    response = ollama.chat(
        model='qwen3-coder-30b-ctx128k-quant',
        messages=[{'role': 'user', 'content': prompt}]
    )
    
    return response['message']['content']


def combined_trading_analysis(chart_image_path, quant_context, symbol, timeframe):
    """Step 2: Combine numerical analysis with visual chart analysis"""
    
    prompt = f"""
{symbol} {timeframe} Trading Analysis

QUANTITATIVE DATA CONTEXT:
{quant_context}

Now analyze the attached chart image and integrate with the numerical analysis above.

Questions:
1. Does the visual pattern align with the numerical momentum?
2. Are support/resistance levels visible on chart matching calculated pivots?
3. Does volume on chart confirm the data trend?
4. Any divergences between price action and indicators?

Provide INTEGRATED analysis:
- Overall trend (data + visual confirmation)
- Entry price (specific level)
- Stop loss (specific level and % risk)
- Take profit targets (TP1, TP2 with specific prices)
- Risk-reward ratio
- Position size recommendation
- Confidence level (1-10) based on data+visual alignment
- Key risks or cautions

If data and visual disagree, explain the conflict.
"""
    
    response = ollama.chat(
        model='qwen3-vl-8b-ctx32k-trading',
        messages=[{
            'role': 'user',
            'content': prompt,
            'images': [chart_image_path]
        }]
    )
    
    return response['message']['content']


# ====================
# MAIN WORKFLOW
# ====================

# Load your trading data
df = pd.read_csv('BTC_USDT_4H.csv')  # Your OHLCV data file

# Step 1: Quantitative analysis
print("=== ANALYZING RAW DATA ===")
quant_analysis = analyze_raw_data(df, 'BTC/USDT')
print(quant_analysis)

# Step 2: Visual + integrated analysis
print("\n=== ANALYZING CHART WITH DATA CONTEXT ===")
final_analysis = combined_trading_analysis(
    chart_image_path='btc_4h_chart.png',  # Your chart screenshot
    quant_context=quant_analysis,
    symbol='BTC/USDT',
    timeframe='4H'
)
print(final_analysis)

# Optional: Save results
with open('trade_analysis_result.txt', 'w') as f:
    f.write("=== QUANTITATIVE ANALYSIS ===\n")
    f.write(quant_analysis)
    f.write("\n\n=== INTEGRATED VISUAL ANALYSIS ===\n")
    f.write(final_analysis)
```

### Simplified Version

```python
import ollama
import pandas as pd

# Quick two-step analysis
df = pd.read_csv('ETH_USDT_1H.csv')

# Step 1: Get numbers
data_context = ollama.chat(
    model='qwen3-coder-30b-ctx128k-quant',
    messages=[{
        'role': 'user',
        'content': f"""
        Analyze ETH data:
        Last 50 closes: {df['close'].tail(50).to_list()}
        Last 50 volumes: {df['volume'].tail(50).to_list()}
        
        Calculate: momentum, volume trend, key levels.
        """
    }]
)['message']['content']

# Step 2: Visual + context
trade_setup = ollama.chat(
    model='qwen3-vl-8b-ctx32k-trading',
    messages=[{
        'role': 'user',
        'content': f"""
        Data Context: {data_context}
        
        Analyze chart and provide trade setup with entry/stop/targets.
        """,
        'images': ['eth_1h_chart.png']
    }]
)['message']['content']

print(trade_setup)
```

## PowerShell Implementation

### Simple Two-Step Analysis

```powershell
# Step 1: Analyze raw data
$symbol = "BTC/USDT"
$dataFile = "btc_4h_data.csv"

$dataContext = ollama run qwen3-coder-30b-ctx128k-quant @"
Analyze $symbol data from $dataFile:

Last 20 closes: 42350, 42380, 42290, 42450, 42380, 42510, 42420, 42560, 42490, 42630, 42580, 42710, 42650, 42780, 42720, 42850, 42790, 42920, 42860, 42950
Last 20 volumes: 1.5M, 1.8M, 1.2M, 2.1M, 1.6M, 1.9M, 1.4M, 2.3M, 1.7M, 2.5M, 1.8M, 2.7M, 1.9M, 2.9M, 2.1M, 3.1M, 2.2M, 3.3M, 2.4M, 3.5M

Calculate:
1. Momentum (5/10/20 period)
2. Volume trend vs average
3. Key support/resistance levels
4. ATR and volatility

Output precise numbers.
"@

# Step 2: Feed to visual model with chart
ollama run qwen3-vl-8b-ctx32k-trading @"
$symbol Analysis

QUANTITATIVE CONTEXT:
$dataContext

Analyze the attached chart image and integrate with data above.

Provide:
- Entry price
- Stop loss
- Take profit targets
- Risk-reward ratio
- Confidence score (1-10)

[User will drag-drop chart image here in interactive mode]
"@
```

### Automated Script

```powershell
# automated_trading_analysis.ps1

param(
    [string]$DataFile = "data.csv",
    [string]$ChartImage = "chart.png",
    [string]$Symbol = "BTC/USDT"
)

Write-Host "=== Step 1: Quantitative Analysis ===" -ForegroundColor Cyan

# Read data (simplified - you'd parse CSV properly)
$dataContent = Get-Content $DataFile -Raw

$quantAnalysis = ollama run qwen3-coder-30b-ctx128k-quant @"
Analyze $Symbol raw data:

$dataContent

Calculate momentum, volume trends, key levels, volatility.
"@

Write-Host $quantAnalysis
Write-Host "`n=== Step 2: Visual + Integrated Analysis ===" -ForegroundColor Cyan

# Note: For image input in PowerShell, you'd need to use the API
# This is a simplified interactive version
ollama run qwen3-vl-8b-ctx32k-trading @"
$Symbol Trading Setup

QUANTITATIVE CONTEXT:
$quantAnalysis

Analyze chart at: $ChartImage

Provide complete trade setup with entry, stop, targets, and confidence.
"@
```

## Benefits of Two-Model Approach

✅ **Better Context** - VL model gets numerical backing from raw data
✅ **Confirmation** - Visual patterns confirmed by statistical analysis
✅ **Precision** - Exact levels from calculations + chart validation
✅ **Divergence Detection** - Spot when chart and data disagree (key insight!)
✅ **Confidence Scoring** - Higher confidence when both models align
✅ **Comprehensive** - Covers both quantitative and qualitative analysis

## When to Use Each Model

### Quant Model Alone
- Backtesting strategies with historical data
- Calculating indicators not visible on chart
- Statistical analysis (correlations, distributions)
- Automated signal generation from databases
- Screening hundreds of symbols

### VL Model Alone
- Quick chart pattern recognition
- Manual chart review during trading hours
- Learning and education about chart patterns
- Analyzing charts from social media/Discord
- When you don't have raw data

### Both Models (Recommended)
- High-conviction trades with capital at risk
- Complex multi-timeframe analysis
- When data and visuals might diverge (important signals!)
- Systematic trading with visual confirmation
- Building trading systems that combine approaches
- When precision matters (exact entry/stop levels)

## Workflow Tips

### Data Preparation
1. **Format:** CSV with columns: timestamp, open, high, low, close, volume
2. **Timeframe:** Match chart timeframe (don't analyze 1H data with 4H chart)
3. **Length:** Include 100-200 periods for good statistical analysis
4. **Quality:** Clean data (no gaps, outliers handled)

### Chart Preparation
1. **Indicators:** Show relevant indicators (RSI, MACD, volume)
2. **Timeframe:** Label clearly on chart
3. **Quality:** High resolution, readable text
4. **Context:** Include enough history (not just last 10 candles)

### Integration Strategy
1. Run quant model first (gets context)
2. Save quant results to variable/file
3. Pass quant results as context to VL model
4. VL model confirms/refutes quant findings
5. Pay attention when models disagree (key insights!)

## Example Use Cases

### Use Case 1: Divergence Detection
```
Quant: "RSI showing lower lows, price momentum weakening -15% over 20 periods"
Visual: "Chart shows higher highs, bullish pattern forming"
→ BEARISH DIVERGENCE - potential reversal signal
```

### Use Case 2: Confirmation
```
Quant: "Strong volume +45% vs average, momentum +8% over 5 periods"
Visual: "Bullish flag breakout with volume spike confirmed"
→ HIGH CONFIDENCE - both models align
```

### Use Case 3: Multi-Timeframe
```
Quant on Daily: "Uptrend, +25% momentum over 20 days"
Visual on 4H: "Pullback to support zone visible"
Quant on 4H: "Oversold RSI, volume declining on pullback"
→ LONG ENTRY - daily trend + 4H pullback opportunity
```

## Next Steps

1. **Create the quant model:**
   ```powershell
   ollama create qwen3-coder-30b-ctx128k-quant -f ./Modelfile.qwen3-coder-30b-ctx128k-quant
   ```

2. **Test with sample data:**
   - Download OHLCV data from exchange
   - Take chart screenshot of same period
   - Run both models and compare

3. **Build automation:**
   - Schedule analysis every 4H/daily
   - Save results to log file
   - Alert on high-confidence setups

4. **Iterate and improve:**
   - Adjust prompts based on results
   - Fine-tune temperature settings
   - Add more specific indicators

## Files Created

- `Modelfile.qwen3-coder-30b-ctx128k-quant` - Quantitative data analysis model
- `Modelfile.qwen3-vl-8b-ctx32k-trading` - Visual chart analysis model
- `TRADING_README.md` - Guide for visual model usage
- `TWO_MODEL_PIPELINE.md` - This file

## Resources

- [Ollama Python Library](https://github.com/ollama/ollama-python)
- [Ollama API Docs](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Example OHLCV Data Sources](https://www.binance.com/en/landing/data)

---

**Remember:** This is analysis tooling, not financial advice. Always validate signals, use proper risk management, and never risk more than you can afford to lose.
