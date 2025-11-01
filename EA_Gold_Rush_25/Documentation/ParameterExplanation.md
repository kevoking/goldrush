# GoldRush25 Expert Advisor - Parameter Explanation

## Complete Parameter Reference Guide

This document provides detailed explanations for every input parameter in the GoldRush25 Expert Advisor. For general usage and strategy information, see the [User Guide](UserGuide.md).

---

## Table of Contents

1. [Strategy Selection](#strategy-selection)
2. [Risk Management](#risk-management)
3. [Multi-Timeframe Analysis](#multi-timeframe-analysis)
4. [Technical Indicators](#technical-indicators)
5. [Trading Sessions](#trading-sessions)
6. [Smart Money Concepts](#smart-money-concepts)
7. [Trade Management](#trade-management)
8. [News Filter](#news-filter)
9. [Advanced Settings](#advanced-settings)
10. [Parameter Optimization Guide](#parameter-optimization-guide)

---

## Strategy Selection

### UseStrategy_TrendContinuation
- **Type:** Boolean (true/false)
- **Default:** `true`
- **Description:** Enables or disables the Trend Continuation strategy
- **How it works:**
  - Identifies strong trends on higher timeframes (H4)
  - Waits for price to pull back to key EMAs (20 or 50)
  - Enters when price resumes in trend direction with confirmation
- **When to enable:** Best for trending markets, strong directional moves
- **When to disable:** During choppy, sideways markets
- **Risk level:** Low to Medium
- **Recommended:** `true` for most users

### UseStrategy_SupportResistance
- **Type:** Boolean (true/false)
- **Default:** `true`
- **Description:** Enables or disables the Support/Resistance Bounce strategy
- **How it works:**
  - Detects key S/R zones from historical price action
  - Waits for price to reach these zones
  - Enters on rejection candles (pin bars, engulfing patterns)
- **When to enable:** Best for range-bound or consolidating markets
- **When to disable:** During strong trending conditions where levels break frequently
- **Risk level:** Medium
- **Recommended:** `true` for balanced approach

### UseStrategy_Breakout
- **Type:** Boolean (true/false)
- **Default:** `false`
- **Description:** Enables or disables the Breakout strategy
- **How it works:**
  - Identifies consolidation ranges (tight price action)
  - Waits for volume surge and price breakout
  - Enters on confirmed breakout with momentum
- **When to enable:** Before major news events, after long consolidations
- **When to disable:** During volatile, whipsaw conditions
- **Risk level:** Medium to High (higher false breakout risk)
- **Recommended:** `false` initially; enable after testing
- **Note:** Lower win rate but higher reward potential

### UseStrategy_LondonOpen
- **Type:** Boolean (true/false)
- **Default:** `true`
- **Description:** Enables or disables the London Open strategy
- **How it works:**
  - Marks Asian session range (00:00-07:00 GMT)
  - Trades breakout at London open (07:00-09:00 GMT)
  - Targets 1.5x Asian range size
- **When to enable:** If you trade during London hours
- **When to disable:** If outside London session hours or broker time doesn't align
- **Risk level:** Medium
- **Recommended:** `true` if trading London session
- **Important:** Adjust session times to match your broker's GMT offset

---

## Risk Management

### RiskPercent
- **Type:** Double
- **Range:** 0.1 - 10.0
- **Default:** `1.0`
- **Description:** Percentage of account balance risked per trade
- **Calculation:** Risk Amount = Account Balance × (RiskPercent / 100)
- **Examples:**
  - 0.5% = Conservative (small accounts, risk-averse traders)
  - 1.0% = Moderate (recommended for most traders)
  - 2.0% = Aggressive (experienced traders, larger accounts)
- **Impact:** Directly affects position size (lot calculation)
- **Recommendation:** Never exceed 2% per trade
- **Note:** This is the maximum potential loss if stop loss is hit

### MaxDailyLossPercent
- **Type:** Double
- **Range:** 1.0 - 20.0
- **Default:** `3.0`
- **Description:** Maximum allowed daily loss before trading stops
- **How it works:**
  - EA tracks daily P&L from midnight reset
  - If total daily loss reaches limit, all new trades blocked
  - Automatically resets at start of new trading day
- **Examples:**
  - Account: $10,000, MaxDaily: 3% = $300 max daily loss
  - After $300 loss, EA stops trading until next day
- **Recommendation:**
  - Conservative: 2.0%
  - Moderate: 3.0%
  - Aggressive: 5.0%
- **Purpose:** Prevents catastrophic losses during bad trading days

### MaxWeeklyLossPercent
- **Type:** Double
- **Range:** 2.0 - 30.0
- **Default:** `5.0`
- **Description:** Maximum allowed weekly loss before trading stops
- **How it works:**
  - Tracks cumulative P&L from Monday
  - Blocks new trades if weekly loss limit reached
  - Resets every Monday at midnight
- **Examples:**
  - Account: $10,000, MaxWeekly: 5% = $500 max weekly loss
- **Recommendation:**
  - Conservative: 4.0%
  - Moderate: 5.0%
  - Aggressive: 8.0%
- **Purpose:** Protects against extended losing streaks

### MaxSimultaneousTrades
- **Type:** Integer
- **Range:** 1 - 10
- **Default:** `3`
- **Description:** Maximum number of open positions allowed at once
- **Purpose:**
  - Prevents overexposure to single market
  - Limits correlation risk
  - Controls total capital at risk
- **Calculation:** Max risk = RiskPercent × MaxSimultaneousTrades
  - Example: 1% risk × 3 trades = 3% total exposure
- **Recommendation by account size:**
  - Small (<$5,000): 1-2 trades
  - Medium ($5,000-$20,000): 2-3 trades
  - Large (>$20,000): 3-5 trades
- **Note:** EA will not open new trades when limit is reached

### RiskRewardRatio
- **Type:** Enumeration
- **Options:**
  - `RR_1_TO_1` = 1:1 Risk Reward
  - `RR_1_TO_15` = 1:1.5 Risk Reward
  - `RR_1_TO_2` = 1:2 Risk Reward (Default)
  - `RR_1_TO_25` = 1:2.5 Risk Reward
  - `RR_1_TO_3` = 1:3 Risk Reward
- **Default:** `RR_1_TO_2`
- **Description:** Target profit relative to risk (stop loss)
- **Examples:**
  - Stop Loss: 50 pips
  - 1:1 = 50 pip target
  - 1:2 = 100 pip target
  - 1:3 = 150 pip target
- **Win Rate vs. RR:**
  - 1:1 requires ~55% win rate to profit
  - 1:2 requires ~40% win rate to profit
  - 1:3 requires ~30% win rate to profit
- **Recommendation:** 1:2 for balanced risk/reward
- **Trade-off:** Higher RR = lower win rate but better long-term profitability

---

## Multi-Timeframe Analysis

### HTF_Period (Higher Timeframe)
- **Type:** Enumeration (Timeframe)
- **Options:** M30, H1, H4, D1
- **Default:** `PERIOD_H4`
- **Description:** Timeframe used to identify overall trend direction
- **Purpose:**
  - Determines market bias (bullish/bearish/neutral)
  - Acts as trend filter for trade entries
  - Higher timeframe = more reliable trend
- **Recommendations:**
  - Day Trading: H1 or H4
  - Swing Trading: H4 or Daily
  - Scalping: M30 or H1
- **Rule:** Must be higher than MTF_Period
- **Impact:** Defines the "big picture" trend context

### MTF_Period (Medium Timeframe)
- **Type:** Enumeration (Timeframe)
- **Options:** M5, M15, M30, H1
- **Default:** `PERIOD_M30`
- **Description:** Timeframe used to identify entry setups
- **Purpose:**
  - Spots pullbacks in HTF trend
  - Identifies S/R levels and patterns
  - Entry timing optimization
- **Recommendations:**
  - Fast-paced trading: M15
  - Balanced: M30 (Default)
  - Conservative: H1
- **Rule:** HTF > MTF > LTF
- **Impact:** Primary timeframe for trade setup detection

### LTF_Period (Lower Timeframe)
- **Type:** Enumeration (Timeframe)
- **Options:** M1, M5, M15
- **Default:** `PERIOD_M5`
- **Description:** Timeframe used for entry confirmation
- **Purpose:**
  - Fine-tunes entry timing
  - Confirms reversal patterns
  - Validates entry signals
- **Recommendations:**
  - Precise entries: M1 or M5
  - Less noise: M15
- **Rule:** Must be lower than MTF_Period
- **Impact:** Improves entry accuracy and reduces slippage

**Important Notes on Timeframe Selection:**
- Maintain proper hierarchy: HTF > MTF > LTF
- Larger timeframe gaps = fewer but higher quality signals
- Smaller gaps = more signals but potentially lower quality
- Test different combinations in demo before live trading

---

## Technical Indicators

### EMA_Fast
- **Type:** Integer
- **Range:** 10 - 50
- **Default:** `20`
- **Description:** Period for fast Exponential Moving Average
- **Purpose:**
  - Identifies short-term pullbacks
  - Dynamic support/resistance in trends
  - Entry trigger when price touches
- **Behavior:**
  - Lower values (15-20): More responsive, more signals
  - Higher values (30-40): Smoother, fewer false signals
- **Recommendation:** 20 is optimal for most markets
- **Used in:** Trend Continuation strategy

### EMA_Slow
- **Type:** Integer
- **Range:** 30 - 100
- **Default:** `50`
- **Description:** Period for slow Exponential Moving Average
- **Purpose:**
  - Secondary pullback level
  - Trend confirmation
  - Deeper retracement entries
- **Behavior:**
  - Lower values (40-50): More entries, higher risk
  - Higher values (60-80): Fewer entries, higher quality
- **Recommendation:** 50 is standard across markets
- **Used in:** Trend Continuation strategy

### EMA_Trend
- **Type:** Integer
- **Range:** 100 - 300
- **Default:** `200`
- **Description:** Period for long-term trend identification
- **Purpose:**
  - Major trend filter (bullish if price > EMA200)
  - No trades against 200 EMA trend
  - Market structure reference
- **Behavior:**
  - 200 is industry standard
  - Lower values (150-180): More trend changes
  - Higher values (220-250): Slower, more stable
- **Recommendation:** Keep at 200 (widely used by institutions)
- **Critical:** Primary trend filter for all strategies

### RSI_Period
- **Type:** Integer
- **Range:** 7 - 21
- **Default:** `14`
- **Description:** Period for Relative Strength Index calculation
- **Purpose:**
  - Momentum confirmation
  - Overbought/oversold detection
  - Divergence identification
- **Behavior:**
  - Lower values (10-12): More sensitive, more signals
  - Standard (14): Balanced
  - Higher values (18-21): Smoother, less noise
- **Recommendation:** 14 is standard (default for most platforms)
- **Used in:** All strategies for momentum confirmation

### RSI_Oversold
- **Type:** Integer
- **Range:** 20 - 40
- **Default:** `30`
- **Description:** RSI level considered oversold (potential buy)
- **Purpose:**
  - Identifies extreme selling conditions
  - Bounce trade signals at support
- **Behavior:**
  - Lower values (20-25): Extreme oversold, fewer signals
  - Standard (30): Balanced
  - Higher values (35-40): More signals, less extreme
- **Recommendation:** 30 for standard markets, 20 for volatile markets
- **Used in:** S/R Bounce strategy

### RSI_Overbought
- **Type:** Integer
- **Range:** 60 - 80
- **Default:** `70`
- **Description:** RSI level considered overbought (potential sell)
- **Purpose:**
  - Identifies extreme buying conditions
  - Reversal signals at resistance
- **Behavior:**
  - Lower values (60-65): More signals, earlier reversals
  - Standard (70): Balanced
  - Higher values (75-80): Extreme overbought, fewer signals
- **Recommendation:** 70 for standard markets, 80 for strong trends
- **Used in:** S/R Bounce strategy

### MACD_Fast
- **Type:** Integer
- **Range:** 8 - 16
- **Default:** `12`
- **Description:** Fast EMA period for MACD calculation
- **Purpose:** Part of MACD momentum indicator
- **Recommendation:** Keep at default (12) - industry standard
- **Used in:** All strategies for momentum confirmation

### MACD_Slow
- **Type:** Integer
- **Range:** 20 - 35
- **Default:** `26`
- **Description:** Slow EMA period for MACD calculation
- **Purpose:** Part of MACD momentum indicator
- **Recommendation:** Keep at default (26) - industry standard
- **Used in:** All strategies for momentum confirmation

### MACD_Signal
- **Type:** Integer
- **Range:** 5 - 15
- **Default:** `9`
- **Description:** Signal line period for MACD
- **Purpose:** Trigger line for MACD crossovers
- **Recommendation:** Keep at default (9) - industry standard
- **Used in:** All strategies for entry timing

### ATR_Period
- **Type:** Integer
- **Range:** 7 - 21
- **Default:** `14`
- **Description:** Period for Average True Range calculation
- **Purpose:**
  - Measures market volatility
  - Dynamic stop loss calculation
  - Position sizing adjustment
- **Behavior:**
  - Lower values (10-12): More responsive to volatility changes
  - Standard (14): Balanced
  - Higher values (18-21): Smoother, slower adaptation
- **Recommendation:** 14 is optimal for most markets
- **Critical:** Directly affects stop loss placement

### ATR_StopLossMultiplier
- **Type:** Double
- **Range:** 0.5 - 3.0
- **Default:** `1.5`
- **Description:** Multiplier for ATR-based stop loss calculation
- **Formula:** Stop Loss Distance = ATR × Multiplier
- **Examples:**
  - ATR = 20 pips, Multiplier = 1.5 → SL = 30 pips
  - ATR = 20 pips, Multiplier = 2.0 → SL = 40 pips
- **Behavior:**
  - Lower values (1.0-1.5): Tighter stops, more stop-outs
  - Standard (1.5-2.0): Balanced
  - Higher values (2.5-3.0): Wider stops, fewer stop-outs
- **Recommendation:**
  - Volatile markets: 2.0 - 2.5
  - Normal markets: 1.5 - 2.0
  - Calm markets: 1.0 - 1.5
- **Trade-off:** Tighter stops = more losses, wider stops = larger losses when hit

---

## Trading Sessions

### Trade_LondonSession
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enables trading during London session
- **Session characteristics:**
  - High volatility
  - Strong directional moves
  - Best for trend and breakout strategies
- **Recommendation:** `true` for active trading
- **Note:** Adjust times to match broker GMT offset

### Trade_NewYorkSession
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enables trading during New York session
- **Session characteristics:**
  - High volume
  - Strong trends
  - Overlap with London creates volatility
- **Recommendation:** `true` for day trading
- **Note:** Adjust times to match broker GMT offset

### Trade_AsianSession
- **Type:** Boolean
- **Default:** `false`
- **Description:** Enables trading during Asian session
- **Session characteristics:**
  - Lower volatility
  - Range-bound price action
  - Best for S/R bounce strategies
- **Recommendation:** `false` for trend traders, `true` for range traders
- **Note:** Asian session is primarily for marking range in London Open strategy

### London_StartTime
- **Type:** String (HH:MM format)
- **Default:** `"03:00"`
- **Description:** London session start time in broker server time
- **How to set:**
  1. Find your broker's GMT offset
  2. London opens at 07:00 GMT (winter) / 08:00 GMT (summer)
  3. Adjust accordingly
- **Examples:**
  - Broker GMT+0: "07:00"
  - Broker GMT+2: "09:00"
  - Broker GMT+3: "10:00"
- **Important:** Must match your broker's server time exactly

### London_EndTime
- **Type:** String (HH:MM format)
- **Default:** `"12:00"`
- **Description:** London session end time in broker server time
- **Standard:** London closes around 16:00 GMT
- **Recommendation:** Adjust based on broker time zone

### NewYork_StartTime
- **Type:** String (HH:MM format)
- **Default:** `"08:00"`
- **Description:** New York session start time in broker server time
- **Standard:** NY opens at 13:00 GMT (winter) / 12:00 GMT (summer)
- **Recommendation:** Adjust based on broker time zone

### NewYork_EndTime
- **Type:** String (HH:MM format)
- **Default:** `"17:00"`
- **Description:** New York session end time in broker server time
- **Standard:** NY closes around 22:00 GMT
- **Recommendation:** Adjust based on broker time zone

**Critical Note on Session Times:**
Always verify your broker's server time and adjust session parameters accordingly. Incorrect session times will result in missed trades or trades at wrong times.

---

## Smart Money Concepts

### Use_OrderBlocks
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enables order block detection and analysis
- **What are order blocks:**
  - Zones where institutions placed large orders
  - Identified by impulsive moves from consolidation
  - Act as high-probability reversal zones
- **How EA uses them:**
  - Confirms entry setups when price reaches order blocks
  - Adds conviction to S/R bounce trades
  - Filters out low-quality setups
- **Recommendation:** `true` for institutional-style trading
- **Impact:** Reduces trade frequency but increases quality

### Use_FairValueGaps
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enables Fair Value Gap (FVG) detection
- **What are FVGs:**
  - Price imbalances (gaps in order flow)
  - Areas price tends to revisit ("fill the gap")
  - Created by fast institutional moves
- **How EA uses them:**
  - Identifies potential pullback targets
  - Entry zones in trend continuation
  - Target zones for take profit
- **Recommendation:** `true` for smart money analysis
- **Impact:** Improves entry timing in trends

### Use_LiquidityGrabs
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enables liquidity grab detection
- **What are liquidity grabs:**
  - Stop hunts (sweeping obvious stop loss levels)
  - Institutions trigger retail stops before reversing
  - Appear as false breakouts or spikes
- **How EA uses them:**
  - Identifies high-probability reversal points
  - Confirms trend continuation after stop hunt
  - Filters false breakout trades
- **Recommendation:** `true` for avoiding traps
- **Impact:** Reduces false breakout losses

### OrderBlock_Lookback
- **Type:** Integer
- **Range:** 10 - 100
- **Default:** `20`
- **Description:** Number of bars to scan for order block detection
- **Behavior:**
  - Lower values (10-15): Recent order blocks only
  - Standard (20-30): Balanced
  - Higher values (40-100): Historical blocks included
- **Recommendation:** 20-30 for most timeframes
- **Trade-off:** More lookback = more blocks detected but some may be outdated

---

## Trade Management

### UseBreakevenStop
- **Type:** Boolean
- **Default:** `true`
- **Description:** Automatically moves stop loss to entry (breakeven) when trade reaches profit target
- **Purpose:**
  - Protects against reversals
  - Locks in risk-free trades
  - Reduces emotional stress
- **How it works:**
  - When profit reaches BreakevenTriggerRR level
  - Stop loss moved to entry price (± small buffer)
  - Trade becomes risk-free
- **Recommendation:** `true` for most traders
- **Note:** May exit profitable trades early during pullbacks

### BreakevenTriggerRR
- **Type:** Double
- **Range:** 0.5 - 2.0
- **Default:** `1.0`
- **Description:** Profit level (in R:R) when breakeven is triggered
- **Examples:**
  - 0.5 = Move to BE when trade is +0.5R (50% of SL distance)
  - 1.0 = Move to BE when trade is +1R (equal to risk)
  - 1.5 = Move to BE when trade is +1.5R
- **Behavior:**
  - Lower values (0.5-0.8): Earlier protection, more early exits
  - Standard (1.0): Balanced
  - Higher values (1.5-2.0): Less early exits, more risk exposure
- **Recommendation:** 1.0 for balanced approach
- **Trade-off:** Earlier BE = more protection but potentially smaller profits

### UseTrailingStop
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enables trailing stop to lock in profits as trade moves favorably
- **Purpose:**
  - Maximizes profit on winning trades
  - Adapts to market movement
  - Reduces manual monitoring
- **How it works:**
  - Stop loss follows price at fixed distance
  - Never moves against you (only in profit direction)
  - Locks in increasing profit as trade progresses
- **Recommendation:** `true` for trend-following strategies
- **Note:** May reduce average profit per trade if too tight

### TrailingType
- **Type:** Enumeration
- **Options:**
  - `TRAIL_FIXED` = Fixed pip trailing
  - `TRAIL_BY_EMA` = Trail using EMA
  - `TRAIL_BY_ATR` = Trail using ATR
- **Default:** `TRAIL_BY_EMA`
- **Description:** Method used for trailing stop calculation
- **TRAIL_FIXED:**
  - Uses TrailingStopDistance in pips
  - Simple and predictable
  - Best for ranging markets
- **TRAIL_BY_EMA:**
  - Trails below/above EMA (20 typically)
  - Adapts to market structure
  - Best for trending markets
- **TRAIL_BY_ATR:**
  - Uses ATR for dynamic distance
  - Adjusts to volatility
  - Best for varying market conditions
- **Recommendation:** TRAIL_BY_EMA for trends, TRAIL_FIXED for testing

### TrailingStopDistance
- **Type:** Double (pips)
- **Range:** 5.0 - 100.0
- **Default:** `20.0`
- **Description:** Distance (in pips) for trailing stop when using TRAIL_FIXED
- **Behavior:**
  - Lower values (10-15): Locks profit faster, early exits
  - Standard (20-30): Balanced
  - Higher values (40-50): Gives trade more room, larger pullbacks
- **Recommendation:**
  - Scalping: 10-15 pips
  - Day trading: 20-30 pips
  - Swing trading: 40-60 pips
- **Trade-off:** Tighter = more small wins, wider = fewer larger wins

### PartialTakeProfit
- **Type:** Boolean
- **Default:** `true`
- **Description:** Closes portion of position at first target, lets rest run
- **Purpose:**
  - Secures partial profit early
  - Reduces psychological pressure
  - Allows for larger wins on remainder
- **How it works:**
  - When PartialTP_RR level reached
  - Closes PartialTP_Percent of position
  - Remaining position runs to final TP or trailing stop
- **Recommendation:** `true` for balanced profit-taking
- **Example:** Close 50% at 1.5R, let 50% run to 2.5R+

### PartialTP_Percent
- **Type:** Double
- **Range:** 25.0 - 75.0
- **Default:** `50.0`
- **Description:** Percentage of position to close at first target
- **Examples:**
  - 25% = Close quarter, let ¾ run
  - 50% = Close half, let half run (Default)
  - 75% = Close most, let small portion run
- **Recommendation:**
  - Conservative: 50-60% (secure profit early)
  - Balanced: 40-50%
  - Aggressive: 25-33% (maximize winners)
- **Trade-off:** Higher % = more secured profit but less runner potential

### PartialTP_RR
- **Type:** Double
- **Range:** 0.5 - 3.0
- **Default:** `1.5`
- **Description:** R:R level to trigger partial take profit
- **Examples:**
  - 1.0 = Take partial profit at 1:1
  - 1.5 = Take partial profit at 1:1.5 (Default)
  - 2.0 = Take partial profit at 1:2
- **Recommendation:** 1.5 for balanced approach
- **Strategy:** Should be less than final RiskRewardRatio
- **Example setup:** PartialTP at 1.5R, final TP at 2.5R

---

## News Filter

### AvoidHighImpactNews
- **Type:** Boolean
- **Default:** `true`
- **Description:** Prevents trading around high-impact news events
- **Purpose:**
  - Avoids unpredictable volatility spikes
  - Reduces slippage and stop hunting
  - Protects against irrational market moves
- **How it works (currently):**
  - Manual implementation (see code placeholder)
  - Requires updating news event array
  - Blocks trades within NewsAvoidanceMinutes window
- **Recommendation:** `true` for all traders
- **Note:** Current version requires manual news event input

### NewsAvoidanceMinutes
- **Type:** Integer
- **Range:** 15 - 120
- **Default:** `30`
- **Description:** Minutes before and after news to avoid trading
- **Examples:**
  - News at 14:30, Avoidance: 30 → No trades 14:00-15:00
  - News at 14:30, Avoidance: 60 → No trades 13:30-15:30
- **Recommendation:**
  - Standard news: 30 minutes
  - High-impact (NFP, FOMC): 60 minutes
  - Medium-impact: 20-30 minutes
- **Trade-off:** Larger window = fewer missed opportunities but better protection

**Major News Events to Avoid:**
- Non-Farm Payrolls (NFP)
- FOMC Rate Decisions
- CPI (Inflation) Reports
- GDP Releases
- Central Bank Announcements

---

## Advanced Settings

### MagicNumber
- **Type:** Integer
- **Range:** 100000 - 999999
- **Default:** `123456`
- **Description:** Unique identifier for EA's trades
- **Purpose:**
  - Distinguishes this EA's trades from others
  - Allows multiple EAs on same account
  - Used for trade filtering and management
- **When to change:**
  - Running multiple instances of same EA
  - Running different EAs on same account
  - Want to separate trade tracking
- **Recommendation:** Change if running multiple EAs
- **Note:** Must be unique per EA instance

### TradeComment
- **Type:** String
- **Default:** `"GoldRush25"`
- **Description:** Comment attached to all trades
- **Purpose:**
  - Trade identification
  - Journal tracking
  - Performance analysis
- **Recommendation:** Keep descriptive but short
- **Examples:**
  - "GR25_GOLD"
  - "GoldRush_Live"
  - "GR25_Demo"
- **Note:** Visible in MT5 trade history and journal

### Slippage
- **Type:** Integer (points)
- **Range:** 5 - 100
- **Default:** `30`
- **Description:** Maximum allowed price slippage for order execution
- **What is slippage:**
  - Difference between requested and executed price
  - Measured in points (1 point = 0.1 pip for 5-digit quotes)
- **Examples:**
  - 30 points = 3 pips maximum slippage
  - 50 points = 5 pips maximum slippage
- **Recommendation:**
  - Fast brokers: 20-30 points
  - Standard brokers: 30-50 points
  - Volatile markets: 50-100 points
- **Impact:** Order rejected if slippage exceeds this value

### SendNotifications
- **Type:** Boolean
- **Default:** `true`
- **Description:** Sends push notifications to MT5 mobile app
- **What is sent:**
  - Trade opened/closed
  - Daily/weekly loss limits reached
  - Important EA events
- **Setup required:**
  1. Open MT5 → Tools → Options → Notifications
  2. Enable notifications
  3. Get MetaQuotes ID from mobile app
  4. Enter ID in MT5 settings
- **Recommendation:** `true` if you want mobile alerts
- **Note:** Requires MT5 mobile app installation

### WriteTradeJournal
- **Type:** Boolean
- **Default:** `true`
- **Description:** Logs all trade data to CSV file for analysis
- **What is logged:**
  - Entry/exit times and prices
  - Profit, commission, swap
  - Strategy used
  - Indicator values at entry
  - R:R achieved
  - Maximum favorable/adverse excursion
- **File location:** `MQL5/Files/TradeJournal_[SYMBOL]_[MAGIC]_[DATE].csv`
- **Recommendation:** `true` for serious traders
- **Purpose:**
  - Performance tracking
  - Strategy optimization
  - Identifying improvement areas
- **Note:** Essential for reviewing and improving trading performance

---

## Parameter Optimization Guide

### Getting Started with Optimization

**1. Start with Default Settings**
- Test defaults for 2-4 weeks
- Analyze results before changing
- Change one parameter at a time

**2. Identify What to Optimize**
- Win rate too low → Adjust entry filters (RSI, MACD)
- Profit factor low → Adjust R:R ratio
- Too few trades → Loosen filters (RSI levels, timeframes)
- Too many trades → Tighten filters

**3. Use Strategy Tester**
- MT5 → View → Strategy Tester
- Select "Every tick based on real ticks" mode
- Test minimum 2 years of data
- Enable optimization mode

### Parameters to Optimize (Priority Order)

**High Priority:**
1. **RiskRewardRatio** - Most impact on profitability
2. **ATR_StopLossMultiplier** - Balance between stop-outs and losses
3. **EMA periods** - Affects entry timing and frequency
4. **RSI levels** - Filters trade quality

**Medium Priority:**
5. **Timeframe combinations** - Affects signal quality
6. **TrailingStopDistance** - Optimizes profit capture
7. **PartialTP settings** - Balances profit security and potential

**Low Priority:**
8. **MaxSimultaneousTrades** - Mainly risk management
9. **News filter timing** - Safety feature
10. **Smart money settings** - Fine-tuning

### Optimization Best Practices

**DO:**
- Test on multiple years of data
- Use walk-forward optimization
- Verify results on out-of-sample data
- Keep parameters within reasonable ranges
- Document all changes

**DON'T:**
- Over-optimize (curve fitting)
- Use too short testing periods (< 1 year)
- Optimize on small samples
- Change multiple parameters simultaneously
- Trust results without forward testing

### Parameter Ranges for Optimization

```
Conservative Ranges (Start Here):
- RiskPercent: 0.5-1.5
- RiskRewardRatio: 1:1.5 to 1:2.5
- ATR_StopLossMultiplier: 1.5-2.5
- EMA_Fast: 15-25
- EMA_Slow: 40-60
- RSI_Oversold: 25-35
- RSI_Overbought: 65-75

Aggressive Ranges (Advanced Users):
- RiskPercent: 1.0-2.5
- RiskRewardRatio: 1:1 to 1:3
- ATR_StopLossMultiplier: 1.0-3.0
- EMA_Fast: 10-30
- EMA_Slow: 30-70
- RSI_Oversold: 20-40
- RSI_Overbought: 60-80
```

### Evaluating Optimization Results

**Key Metrics to Track:**
1. **Profit Factor** - Target: > 1.5 (Good: > 2.0)
2. **Win Rate** - Target: > 40% for 1:2 RR
3. **Maximum Drawdown** - Keep under 20-30%
4. **Recovery Factor** - Higher is better
5. **Number of Trades** - Minimum 100 for statistical significance

**Red Flags:**
- Win rate > 80% (likely curve-fitted)
- Profit factor > 5.0 (unrealistic)
- Drawdown > 50% (too risky)
- Fewer than 50 trades in 1 year (insufficient data)
- Results vastly different on out-of-sample data

---

## Market-Specific Recommendations

### Gold (XAUUSD)
```
RiskPercent: 0.5-1.0 (volatile)
ATR_StopLossMultiplier: 2.0-2.5
TrailingStopDistance: 30-50 pips
Sessions: London + NY
Strategies: All (Gold responds well to all 4)
```

### EURUSD
```
RiskPercent: 1.0-1.5
ATR_StopLossMultiplier: 1.5-2.0
TrailingStopDistance: 20-30 pips
Sessions: London + NY
Strategies: Trend + S/R + London Open
```

### GBPUSD
```
RiskPercent: 0.75-1.25 (higher volatility)
ATR_StopLossMultiplier: 2.0-2.5
TrailingStopDistance: 25-40 pips
Sessions: London primarily
Strategies: All (very active during London)
```

### USDJPY
```
RiskPercent: 1.0-1.5
ATR_StopLossMultiplier: 1.5-2.0
TrailingStopDistance: 20-35 pips
Sessions: Asian + London + NY
Strategies: Trend + S/R
```

---

## Troubleshooting Parameter Issues

### Issue: Too Many Trades
**Solution:**
- Increase RSI neutral zone (35-65 instead of 40-60)
- Use only HTF trend-aligned trades
- Disable one or more strategies
- Tighten volume confirmation (2.0x instead of 1.5x)

### Issue: Too Few Trades
**Solution:**
- Decrease RSI requirements
- Enable more strategies
- Lower volume confirmation (1.3x instead of 1.5x)
- Use smaller timeframe for MTF

### Issue: Low Win Rate
**Solution:**
- Increase ATR_StopLossMultiplier (wider stops)
- Add more confirmation filters
- Only trade highest quality setups
- Check session times alignment

### Issue: Low Profit Factor
**Solution:**
- Increase RiskRewardRatio (target higher profits)
- Improve entry timing (optimize EMA periods)
- Better trade management (adjust trailing stop)
- Reduce trading frequency (quality over quantity)

### Issue: High Drawdown
**Solution:**
- Reduce RiskPercent
- Lower MaxSimultaneousTrades
- Stricter loss limits (daily/weekly)
- Avoid trading during volatile news
- Use higher timeframes (more stable)

---

## Quick Reference Card

### Conservative Settings
```
Risk: 0.5%
Max Daily Loss: 2%
Max Positions: 2
R:R: 1:2
Timeframes: H4/H1/M15
Strategies: Trend + S/R only
ATR Multiplier: 2.0
```

### Balanced Settings (Default)
```
Risk: 1.0%
Max Daily Loss: 3%
Max Positions: 3
R:R: 1:2
Timeframes: H4/M30/M5
Strategies: Trend + S/R + London
ATR Multiplier: 1.5
```

### Aggressive Settings
```
Risk: 2.0%
Max Daily Loss: 5%
Max Positions: 5
R:R: 1:1.5
Timeframes: H1/M15/M5
Strategies: All enabled
ATR Multiplier: 1.0
```

---

## Additional Resources

### Recommended Reading Order:
1. Start with [User Guide](UserGuide.md) - Overall EA understanding
2. Read this Parameter Guide - Deep parameter knowledge
3. Test on demo account - Practical experience
4. Optimize parameters - Customization for your needs
5. Review trade journal - Continuous improvement

### Getting Help:
- Check parameter validation errors in Experts log
- Verify session times match broker GMT offset
- Test one parameter change at a time
- Keep detailed notes of changes and results

---

**Last Updated:** November 2025
**Version:** 1.00
**EA:** GoldRush25

---

**Disclaimer:** Trading involves substantial risk. These parameters are starting points and should be optimized for your specific market, risk tolerance, and trading style. Always test thoroughly on demo accounts before live trading.
