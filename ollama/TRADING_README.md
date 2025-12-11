# Trading Analysis with Qwen3-VL Vision Model

A specialized Ollama model for analyzing trading charts and identifying opportunities using computer vision.

## Model: `qwen3-vl-8b-ctx32k-trading`

This model is optimized for technical analysis with:
- **32k context window** - analyze multiple charts and timeframes
- **Low temperature (0.2)** - precise, consistent analysis
- **Vision capabilities** - reads charts, patterns, and indicators visually
- **Trading-focused system prompt** - trained to identify setups, support/resistance, and risk/reward

## Quick Start

### 1. Create the Model

```powershell
cd ollama
ollama create qwen3-vl-8b-ctx32k-trading -f ./Modelfile.qwen3-vl-8b-ctx32k-trading
```

### 2. Run Interactive Analysis

```powershell
ollama run qwen3-vl-8b-ctx32k-trading
```

Then drag-and-drop chart images into the terminal or provide image paths.

## How to Use

### Best Input Strategy

The model works best with **chart images + text context**. It analyzes visual patterns that are hard to convey with just numbers.

#### What to Feed It

✅ **Chart Screenshots** (Primary Input)
- Price charts with candlesticks (1H, 4H, Daily timeframes)
- Multiple indicators overlaid (RSI, MACD, volume, moving averages)
- Support/resistance lines you've drawn
- Multiple timeframe views in one image

✅ **Text Context** (Secondary Input)
- Current price and volume
- Market context (news, events, bias)
- Your trading style and risk tolerance
- Specific questions about entries/exits

❌ **What Doesn't Work**
- Raw CSV/JSON data (use images instead)
- Real-time streaming (static snapshots only)
- Fundamental analysis without context

## Example Usage

### Simple Analysis

```
[Attach chart image]

Analyze this BTC/USDT 4H chart. What's the trend? Any trade setups?
```

### Detailed Trade Setup

```
[Attach chart with indicators]

Symbol: ETH/USDT
Timeframe: 4H
Current Price: $2,350
Context: Bounced off $2,200 support, RSI recovering from oversold
Goal: Long entry for 5-10% swing trade

Analysis needed:
1. Current trend strength
2. Key support/resistance levels
3. Optimal entry price
4. Stop loss placement
5. Take profit targets (TP1, TP2)
6. Risk-reward ratio
```

### Multi-Chart Comparison

```
[Attach 4 charts in grid: BTC, ETH, SOL, BNB]

Which crypto shows the strongest setup for the next 24 hours?
Compare momentum, volume, and pattern strength.
```

### Pattern Recognition

```
[Attach daily chart]

Does this show a valid head and shoulders pattern?
If so, what's the neckline and price target?
```

## Prompt Template

Use this structure for best results:

```
[Attach clear chart image with indicators visible]

Symbol: [TICKER]
Timeframe: [1H/4H/Daily/Weekly]
Current Price: [$X,XXX]
24H Volume: [$XXM] (above/below average)
Context: [Recent price action, news, market conditions]
Trading Style: [Scalp/Day/Swing/Position]
Risk Tolerance: [X% per trade]
Bias: [Long/Short/Neutral]

Questions:
1. What's the current trend and strength?
2. Key support and resistance levels?
3. Any chart patterns forming?
4. Entry price recommendations?
5. Stop loss and take profit levels?
6. Risk-reward ratio for this setup?
```

## What the Model Analyzes

### Technical Patterns
- Head and shoulders, inverse H&S
- Triangles (ascending, descending, symmetrical)
- Flags and pennants
- Double tops/bottoms, triple tops/bottoms
- Cup and handle
- Wedges (rising, falling)

### Price Action
- Support and resistance zones
- Trend lines and channels
- Candlestick patterns (doji, hammer, engulfing, etc.)
- Market structure (higher highs/lows, lower highs/lows)
- Breakouts and fakeouts

### Technical Indicators
- Moving averages (SMA, EMA) and crossovers
- RSI (overbought/oversold, divergences)
- MACD (signal line crosses, histogram)
- Bollinger Bands (squeeze, breakout)
- Volume profile and trends
- Fibonacci retracements/extensions

### Trade Signals
- Entry points with specific prices
- Stop loss placement (below support, above resistance)
- Take profit targets (TP1, TP2, TP3)
- Risk-reward ratios (minimum 1:2 recommended)
- Position sizing recommendations

## Pro Tips

### 📊 Chart Preparation
- **Use high-quality screenshots** - clear, readable text
- **Include multiple timeframes** in one image (context + detail)
- **Show relevant indicators** - don't clutter, pick 3-5 key ones
- **Mark important zones** - draw your own S/R lines before asking

### 🎯 Better Questions
- **Be specific about goals** - "5% scalp" vs "20% swing trade"
- **Mention your bias** - helps model align with your view
- **Ask for risk management** - not just entries
- **Request multiple scenarios** - "If breaks $X, then what?"

### ⚡ Advanced Workflows

**Multi-Timeframe Analysis:**
```
[Attach 3 charts: Daily, 4H, 1H]

Top-down analysis for ETH:
- Daily: Overall trend
- 4H: Swing structure
- 1H: Precise entry timing
```

**Comparative Analysis:**
```
[Attach sector charts: AAPL, MSFT, GOOGL, NVDA]

Which tech stock has the cleanest breakout setup?
Rank by: pattern quality, volume confirmation, R:R ratio
```

**Portfolio Review:**
```
[Attach 6 charts of current positions]

Review my open trades. Which should I:
1. Take profit early
2. Move stop to breakeven
3. Add to position
4. Exit immediately
```

## Integration Ideas

### With Trading Platforms

1. **TradingView** - Screenshot charts with indicators → Analyze
2. **MetaTrader** - Export chart images → Get second opinion
3. **ThinkOrSwim** - Grid layout charts → Comparative analysis

### Automated Workflows

```powershell
# Example: Analyze chart every 4 hours
$chartPath = "C:\Screenshots\BTC_4H_latest.png"

ollama run qwen3-vl-8b-ctx32k-trading "
Analyze this BTC/USDT 4H chart for:
- Trend continuation or reversal signals
- New support/resistance levels
- Any trade setups with >1:3 R:R
Image: $chartPath
"
```

### API Usage (Python)

```python
import ollama

def analyze_chart(image_path, symbol, timeframe, context):
    response = ollama.chat(
        model='qwen3-vl-8b-ctx32k-trading',
        messages=[{
            'role': 'user',
            'content': f"""
            Symbol: {symbol}
            Timeframe: {timeframe}
            Context: {context}
            
            Provide: trend, key levels, entry/exit, R:R ratio
            """,
            'images': [image_path]
        }]
    )
    return response['message']['content']

# Usage
analysis = analyze_chart(
    'btc_4h.png',
    'BTC/USDT',
    '4H',
    'Price bounced off $40K support zone'
)
print(analysis)
```

## Limitations

⚠️ **This model provides analysis, not financial advice**
- Always verify signals with your own research
- Use proper risk management (1-2% per trade)
- Markets are unpredictable - no system is 100% accurate
- Past patterns don't guarantee future results

⚠️ **Technical Limitations**
- Analyzes static images only (not live data)
- Can't access real-time news or fundamentals
- Limited to visual information in the chart
- May misread low-quality or cluttered charts

## Example Outputs

**Input:** Daily BTC chart with RSI divergence

**Model Output:**
```
Analysis of BTC/USDT Daily Chart:

TREND: Downtrend weakening
- Lower highs at $48K → $45K → $43K
- RSI showing bullish divergence (price lower low, RSI higher low)
- Volume declining on down moves

KEY LEVELS:
- Resistance: $42,800 (previous support turned resistance)
- Support: $40,000 (psychological level + volume shelf)

SETUP: Counter-trend long (risky)
Entry: $40,500 (bounce confirmation needed)
Stop Loss: $39,200 (below support, -3.2%)
TP1: $42,800 (+5.7%, R:R = 1.8:1)
TP2: $45,000 (+11.1%, R:R = 3.5:1)

RECOMMENDATION: Wait for confirmation
- Watch for bullish engulfing candle above $40,500
- RSI must break above 45
- Volume spike on reversal candle
- Risk: 2% max position size due to counter-trend nature
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Model can't read indicators | Use larger, clearer screenshots |
| Vague analysis | Provide more context in prompt |
| Conflicting signals | Ask model to explain uncertainty |
| Too bullish/bearish | Request neutral, balanced view |
| Missing key levels | Upload chart with broader time range |

## See Also

- [Ollama Documentation](https://ollama.ai/docs)
- [Main README](../README.md) - Other Ollama models and benchmarks
- [TradingView](https://tradingview.com) - Charting platform

---

**Disclaimer:** This model is a tool for technical analysis education and research. It does not provide financial advice. Trading involves significant risk. Always do your own research and consult licensed financial advisors before making investment decisions.
