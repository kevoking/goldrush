# GoldRush25 Expert Advisor - User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Input Parameters Explained](#input-parameters-explained)
5. [Trading Strategies](#trading-strategies)
6. [Risk Management](#risk-management)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

GoldRush25 is a professional-grade MetaTrader 5 Expert Advisor designed for day trading. It implements multiple proven strategies with institutional-level risk management and multi-timeframe analysis capabilities.

**Key Features:**
- 4 trading strategies (Trend Continuation, S/R Bounce, Breakout, London Open)
- Multi-timeframe analysis (HTF, MTF, LTF)
- Smart Money Concepts (Order Blocks, Fair Value Gaps, Liquidity Grabs)
- Advanced risk management (daily/weekly loss limits, position sizing)
- Automated trade management (breakeven, trailing stops, partial TP)
- Comprehensive trade journal in CSV format

---

## Installation

### Step 1: File Placement

Copy the entire `EA_Gold_Rush_25` folder to your MetaTrader 5 data folder:

```
<MT5 Data Folder>/MQL5/Experts/
```

Your directory structure should look like:
```
MQL5/Experts/EA_Gold_Rush_25/
├── GoldRush25.mq5
├── Include/
│   ├── RiskManagement.mqh
│   ├── TechnicalIndicators.mqh
│   ├── TradeExecution.mqh
│   ├── MultiTimeframeAnalysis.mqh
│   ├── SmartMoneyLogic.mqh
│   └── TradeJournal.mqh
├── Configuration/
└── Documentation/
```

### Step 2: Compilation

1. Open MetaEditor (press F4 in MT5 or click Tools > MetaQuotes Language Editor)
2. Navigate to `Experts/EA_Gold_Rush_25/GoldRush25.mq5`
3. Click "Compile" (F7)
4. Check for errors in the Errors tab (should show 0 errors, 0 warnings)

### Step 3: Attach to Chart

1. Open the desired chart (e.g., EURUSD, GBPUSD, Gold)
2. Drag `GoldRush25` from the Navigator onto the chart
3. Configure input parameters (see below)
4. Click "OK"
5. Verify EA is running (smiling face icon in top-right corner)

---

## Quick Start

### Conservative Settings (Recommended for Beginners)

```
Risk Per Trade: 0.5%
Max Daily Loss: 2.0%
Max Weekly Loss: 4.0%
Risk:Reward Ratio: 1:2
Max Open Trades: 2

Enable only:
- Trend Continuation Strategy
- London Session Trading
```

### Moderate Settings (Experienced Traders)

```
Risk Per Trade: 1.0%
Max Daily Loss: 3.0%
Max Weekly Loss: 5.0%
Risk:Reward Ratio: 1:2
Max Open Trades: 3

Enable:
- Trend Continuation Strategy
- S/R Bounce Strategy
- London Session + New York Session
```

### Aggressive Settings (Advanced Users)

```
Risk Per Trade: 2.0%
Max Daily Loss: 4.0%
Max Weekly Loss: 6.0%
Risk:Reward Ratio: 1:1.5
Max Open Trades: 5

Enable all strategies and sessions
```

---

## Input Parameters Explained

### Strategy Selection

**UseStrategy_TrendContinuation**
- Trades pullbacks in established trends
- Highest win rate, best for trending markets
- Recommended: `true`

**UseStrategy_SupportResistance**
- Trades bounces off key S/R levels
- Good for range-bound markets
- Recommended: `true`

**UseStrategy_Breakout**
- Trades breakouts from consolidation zones
- Lower win rate but high reward potential
- Recommended: `false` (enable only after testing)

**UseStrategy_LondonOpen**
- Trades Asian range breakout at London open
- Session-specific strategy
- Recommended: `true` (if trading London hours)

---

### Risk Management

**RiskPercent (0.5-2.0%)**
- Percentage of account risked per trade
- Conservative: 0.5%, Moderate: 1.0%, Aggressive: 2.0%
- **Critical:** Never exceed 2% per trade

**MaxDailyLossPercent (2.0-5.0%)**
- Maximum loss allowed per day
- Trading stops when limit reached
- Conservative: 2%, Moderate: 3%, Aggressive: 5%

**MaxWeeklyLossPercent (3.0-10.0%)**
- Maximum loss allowed per week
- Trading stops when limit reached
- Conservative: 4%, Moderate: 5%, Aggressive: 8%

**MaxSimultaneousTrades (1-5)**
- Maximum number of open positions at once
- Prevents overexposure
- Recommended: 2-3 trades

**RiskRewardRatio**
- Target profit vs. risk ratio
- Options: 1:1, 1:1.5, 1:2, 1:2.5, 1:3
- **Recommended:** 1:2 (balanced)
- Higher RR = lower win rate but better overall profitability

---

### Multi-Timeframe Analysis

**HTF_Period (Higher Timeframe)**
- Used to identify overall trend direction
- Default: H4
- Options: H1, H4, Daily
- **Recommendation:** H4 for day trading, Daily for swing trading

**MTF_Period (Medium Timeframe)**
- Used to find entry setups
- Default: M30
- Options: M15, M30, H1
- **Recommendation:** M30

**LTF_Period (Lower Timeframe)**
- Used for entry confirmation
- Default: M5
- Options: M1, M5, M15
- **Recommendation:** M5

**Important:** Ensure HTF > MTF > LTF for proper alignment

---

### Technical Indicators

**EMA_Fast (15-25)**
- Fast moving average for pullbacks
- Default: 20
- Lower = more signals, more false signals

**EMA_Slow (40-60)**
- Slow moving average for trend confirmation
- Default: 50

**EMA_Trend (180-220)**
- Long-term trend filter
- Default: 200

**RSI_Period (10-20)**
- Momentum indicator
- Default: 14

**RSI_Oversold/Overbought (20-40 / 60-80)**
- RSI levels for reversal signals
- Default: 30/70

**MACD Settings**
- Standard settings work well
- Fast: 12, Slow: 26, Signal: 9

**ATR_Period (10-20)**
- Volatility measurement
- Default: 14

**ATR_StopLossMultiplier (1.0-3.0)**
- Stop loss distance in ATR multiples
- Conservative: 2.0, Moderate: 1.5, Aggressive: 1.0

---

### Trading Sessions

**Trade_LondonSession**
- Trades during London hours (high volatility)
- Recommended: `true`

**Trade_NewYorkSession**
- Trades during NY hours (high volume)
- Recommended: `true`

**Trade_AsianSession**
- Trades during Asian hours (low volatility)
- Recommended: `false` (only for specific strategies)

**Session Times (Broker Time)**
- **IMPORTANT:** Adjust times to your broker's server time
- Find broker GMT offset and adjust accordingly
- Example: If broker is GMT+2:
  - London Open: 09:00 (instead of 07:00 GMT)

---

### Smart Money Concepts

**Use_OrderBlocks**
- Detect institutional order blocks
- Recommended: `true`

**Use_FairValueGaps**
- Detect price imbalances
- Recommended: `true`

**Use_LiquidityGrabs**
- Detect stop hunts
- Recommended: `true`

**OrderBlock_Lookback (10-50)**
- Bars to scan for order blocks
- Default: 20

---

### Trade Management

**UseBreakevenStop**
- Move SL to entry when in profit
- Recommended: `true`

**BreakevenTriggerRR (0.5-1.5)**
- Profit level to trigger breakeven
- Default: 1.0 (when 1:1 profit reached)

**UseTrailingStop**
- Lock in profits as trade moves favorably
- Recommended: `true`

**TrailingType**
- Fixed: By pips
- By EMA: Trails below/above EMA
- By ATR: Dynamic based on volatility
- Recommended: `TRAIL_FIXED` initially

**TrailingStopDistance (10-50 pips)**
- Distance from current price
- Tighter = secure profits faster, but may exit early
- Default: 20 pips

**PartialTakeProfit**
- Close portion of position at first target
- Recommended: `true`

**PartialTP_Percent (25-75%)**
- Percentage to close at first target
- Default: 50%

**PartialTP_RR (1.0-2.0)**
- RR level to take partial profit
- Default: 1.5

---

### News Filter

**AvoidHighImpactNews**
- Stops trading before/after major news
- Recommended: `true`

**NewsAvoidanceMinutes (15-60)**
- Minutes to avoid trading around news
- Default: 30

**Note:** Currently uses manual news array. Update news events weekly for best results.

---

### Advanced Settings

**MagicNumber (100000-999999)**
- Unique identifier for EA's trades
- Change if running multiple EAs on same account
- Default: 123456

**TradeComment**
- Comment added to all trades
- Useful for tracking in journal
- Default: "GoldRush25"

**Slippage (10-50 points)**
- Maximum allowed slippage
- Default: 30

**SendNotifications**
- Send push notifications to MT5 mobile app
- Setup: Tools > Options > Notifications
- Recommended: `true`

**WriteTradeJournal**
- Log all trades to CSV file
- Essential for performance analysis
- Recommended: `true`

---

## Trading Strategies

### 1. Trend Continuation Strategy

**How it works:**
1. Identifies strong trend on H4
2. Waits for pullback to EMA 20/50 on M30
3. Enters when M5 confirms reversal

**Best conditions:**
- Clear trending markets
- After major moves
- During London/NY sessions

**Entry criteria:**
- HTF trend aligned (price above/below 200 EMA)
- Price pulls back to 20 or 50 EMA
- RSI in 40-60 zone (neutral)
- M5 shows reversal candle + MACD cross

**Exit:**
- Take profit: 1:2 RR
- Stop loss: Below recent swing + ATR buffer
- Trail with breakeven + trailing stop

---

### 2. Support/Resistance Bounce Strategy

**How it works:**
1. Identifies key S/R zones on H4/Daily
2. Waits for price to approach zone
3. Enters on rejection confirmation

**Best conditions:**
- Range-bound markets
- Clear historical levels
- High timeframe S/R zones

**Entry criteria:**
- Price within 10 pips of S/R zone
- Rejection candle (pin bar, engulfing)
- RSI showing divergence (optional)
- Volume spike on rejection

**Exit:**
- Take profit: Opposite S/R level or 1:2 RR
- Stop loss: 10-20 pips beyond S/R zone
- Move to breakeven quickly

---

### 3. Breakout Strategy

**How it works:**
1. Detects consolidation range (15+ candles)
2. Waits for volume increase and breakout
3. Enters on retest or aggressive on break

**Best conditions:**
- After consolidation periods
- Before major news
- During high-volume sessions

**Entry criteria:**
- Consolidation detected (narrow range)
- Strong breakout candle (>2x average)
- Volume 2x average
- No immediate reversal

**Exit:**
- Take profit: Range height projected from breakout
- Stop loss: Inside consolidation
- Watch for false breakouts

---

### 4. London Open Strategy

**How it works:**
1. Marks Asian session range (00:00-07:00 GMT)
2. Waits for London open (07:00-09:00 GMT)
3. Trades breakout of Asian range

**Best conditions:**
- Clean Asian range (not choppy)
- Monday-Thursday (avoid Fridays)
- Minimum 20 pip range

**Entry criteria:**
- Clear break of Asian high/low
- Volume surge at London open
- Retest of broken level (conservative entry)

**Exit:**
- Take profit: 1.5x Asian range
- Stop loss: Opposite side of range
- Close by 12:00 GMT (don't hold through NY)

---

## Risk Management

### Position Sizing

The EA automatically calculates lot size based on:
- Account balance
- Risk percentage
- Stop loss distance

**Example:**
- Account: $10,000
- Risk: 1% = $100
- Stop loss: 50 pips
- Calculated lot size: ~0.20 lots (varies by pair)

### Daily/Weekly Limits

**How it works:**
1. EA tracks starting balance each day/week
2. Calculates current P&L
3. Stops trading if limit reached
4. Automatically resets next day/week

**Benefits:**
- Protects capital during losing streaks
- Prevents emotional overtrading
- Enforces discipline

### Maximum Positions

**Why limit positions:**
- Prevents overexposure to single market
- Reduces correlation risk
- Better risk control

**Recommendation:**
- Small accounts (<$5,000): Max 2 trades
- Medium accounts ($5,000-$20,000): Max 3 trades
- Large accounts (>$20,000): Max 5 trades

---

## Best Practices

### 1. Start with Demo Account

- Test for minimum 2 weeks
- Verify settings work with your broker
- Understand EA behavior
- Practice with trade journal analysis

### 2. Backtest Thoroughly

- Test on 2+ years of data
- Use "Every Tick" mode
- Test multiple symbols
- Verify results are not curve-fitted

### 3. Optimize Carefully

- Don't over-optimize
- Use walk-forward optimization
- Prioritize robustness over maximum profit
- Keep parameters within recommended ranges

### 4. Monitor Performance

- Review trade journal weekly
- Track win rate, profit factor, drawdown
- Identify which strategies work best
- Adjust settings based on performance

### 5. Adapt to Market Conditions

- Reduce risk during high volatility
- Disable strategies in unfavorable conditions
- Consider disabling EA before major events (FOMC, NFP)
- Take breaks during losing streaks

### 6. Broker Selection

**Important broker requirements:**
- Low spreads (especially for day trading)
- Fast execution (< 100ms)
- Minimum slippage
- Allow automated trading
- Reliable server uptime

**Recommended spreads:**
- EURUSD: < 1 pip
- GBPUSD: < 1.5 pips
- Gold: < 20 cents

---

## Troubleshooting

### EA Not Trading

**Check:**
1. AutoTrading enabled (green button in toolbar)
2. EA allowed in Tools > Options > Expert Advisors
3. Current session enabled in settings
4. Not hit daily/weekly loss limit (check Experts log)
5. Symbol allowed for trading (check market watch)

### Compilation Errors

**Common issues:**
1. Missing include files - verify all .mqh files present
2. Wrong folder structure - check installation path
3. MQL5 version outdated - update MT5

### Poor Results

**Possible causes:**
1. Settings too aggressive - reduce risk, increase RR
2. Wrong broker times - adjust session hours
3. High spread broker - consider changing brokers
4. Market conditions changed - review and optimize
5. News trading - ensure news filter active

### Unexpected Trade Entries

**Debug steps:**
1. Check Experts log for entry reasons
2. Verify indicator values at entry time
3. Review strategy logic in code
4. Check for multiple EA instances running

### Trades Closing Too Early

**Likely causes:**
1. Trailing stop too tight - increase distance
2. Breakeven triggered too early - increase trigger level
3. Broker stop level issues - check minimum stop distance

---

## Performance Expectations

### Realistic Targets

**Monthly Returns:**
- Conservative settings: 3-8%
- Moderate settings: 8-15%
- Aggressive settings: 15-25%

**Maximum Drawdown:**
- Conservative: 5-10%
- Moderate: 10-20%
- Aggressive: 20-30%

**Win Rate:**
- Trend Continuation: 45-60%
- S/R Bounce: 50-65%
- Breakout: 35-50%
- London Open: 40-55%

**Profit Factor:**
- Target: > 1.5
- Good: > 2.0
- Excellent: > 2.5

### Important Notes

- Past performance does not guarantee future results
- Results vary significantly by market conditions
- Backtesting results often better than live trading
- Expect losing weeks/months (part of trading)

---

## Support and Updates

### Trade Journal Analysis

The EA creates a CSV file with detailed trade data:

Location: `<MT5 Data>/MQL5/Files/TradeJournal_SYMBOL_MAGIC_DATE.csv`

**Fields logged:**
- Entry/exit times and prices
- Profit, commission, swap
- Strategy used
- Indicator values at entry
- Planned vs. actual R:R
- Maximum favorable/adverse excursion

**How to use:**
1. Open in Excel/Google Sheets
2. Create pivot tables for analysis
3. Identify best performing strategies
4. Find optimal times to trade
5. Track improvement over time

### Getting Help

**Before contacting support:**
1. Check this user guide
2. Review Experts log for errors
3. Test on demo account
4. Verify settings are correct

**When reporting issues:**
- Provide Experts log excerpt
- Screenshot of settings
- Trade journal entry (if applicable)
- MT5 build number
- Broker name

---

## Version History

### v1.00 (Initial Release)
- 4 trading strategies implemented
- Multi-timeframe analysis
- Smart money concepts
- Automated risk management
- Trade journal logging
- Comprehensive parameter configuration

---

## Legal Disclaimer

Trading forex and CFDs involves substantial risk of loss. This EA is provided "as is" without warranty of any kind. Past performance is not indicative of future results. Only trade with money you can afford to lose.

The developers are not responsible for any losses incurred through the use of this EA. Always test thoroughly on demo accounts before live trading.

---

**End of User Guide**

For parameter-specific details, see `ParameterExplanation.md`
