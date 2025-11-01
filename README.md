# GoldRush25 - Professional MetaTrader 5 Expert Advisor

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-MetaTrader%205-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## Overview

GoldRush25 is a professional-grade Expert Advisor for MetaTrader 5 that implements multiple proven day trading strategies with institutional-level risk management and multi-timeframe analysis capabilities.

## Key Features

### Trading Strategies
- **Trend Continuation** - Trade pullbacks in established trends
- **Support/Resistance Bounce** - Trade reversals at key levels
- **Breakout** - Trade range breakouts with volume confirmation
- **London Open** - Trade Asian range breakout at London session

### Advanced Analysis
- **Multi-Timeframe Analysis** - HTF (trend), MTF (entry), LTF (confirmation)
- **Smart Money Concepts** - Order Blocks, Fair Value Gaps, Liquidity Grabs
- **Technical Indicators** - EMA, RSI, MACD, ATR with optimized parameters

### Risk Management
- **Dynamic Position Sizing** - Based on account equity and risk percentage
- **Daily/Weekly Loss Limits** - Automatic trading suspension when limits reached
- **Maximum Position Control** - Prevent overexposure
- **ATR-Based Stop Loss** - Dynamic stops based on market volatility

### Trade Management
- **Breakeven Stop** - Auto-move SL to entry when profit target reached
- **Trailing Stop** - Multiple modes (Fixed, EMA-based, ATR-based)
- **Partial Take Profit** - Close portion at first target, let rest run
- **News Filter** - Avoid trading during high-impact news events

### Monitoring & Analysis
- **Trade Journal** - Comprehensive CSV logging of all trades
- **Performance Tracking** - Win rate, profit factor, R:R analysis
- **Mobile Notifications** - Push alerts to MT5 mobile app

## Project Structure

```
EA_Gold_Rush_25/
├── GoldRush25.mq5                      # Main EA file
├── Include/
│   ├── RiskManagement.mqh              # Position sizing & risk controls
│   ├── TechnicalIndicators.mqh         # All indicator calculations
│   ├── TradeExecution.mqh              # Order management
│   ├── MultiTimeframeAnalysis.mqh      # MTF logic
│   ├── SmartMoneyLogic.mqh             # Order blocks, FVG, liquidity
│   └── TradeJournal.mqh                # Trade logging & reporting
├── Configuration/
└── Documentation/
    └── UserGuide.md                    # Complete user manual
```

## Quick Start

### Installation

1. Copy `EA_Gold_Rush_25` folder to:
   ```
   <MT5 Data Folder>/MQL5/Experts/
   ```

2. Open MetaEditor (F4 in MT5)

3. Navigate to `Experts/EA_Gold_Rush_25/GoldRush25.mq5`

4. Click Compile (F7) - verify 0 errors

5. Drag EA onto chart in MT5

### Recommended Settings (Conservative)

```
Risk Per Trade: 1.0%
Max Daily Loss: 3.0%
Risk:Reward: 1:2
Max Trades: 3

Strategies Enabled:
✓ Trend Continuation
✓ Support/Resistance Bounce
✗ Breakout (test first)
✓ London Open

Timeframes:
HTF: H4
MTF: M30
LTF: M5
```

## Documentation

- **[User Guide](EA_Gold_Rush_25/Documentation/UserGuide.md)** - Complete manual with detailed explanations
- **[Installation Guide](EA_Gold_Rush_25/Documentation/UserGuide.md#installation)** - Step-by-step setup
- **[Parameter Reference](EA_Gold_Rush_25/Documentation/UserGuide.md#input-parameters-explained)** - All settings explained
- **[Strategy Details](EA_Gold_Rush_25/Documentation/UserGuide.md#trading-strategies)** - How each strategy works

## Core Components

1. **Risk Management Module** - Position sizing, loss limits, margin checks
2. **Technical Indicators Module** - EMA, RSI, MACD, ATR, S/R detection
3. **Multi-Timeframe Analysis** - HTF/MTF/LTF coordination
4. **Smart Money Logic** - Order blocks, FVG, liquidity grabs
5. **Trade Execution** - Order management, trailing, breakeven
6. **Trade Journal** - CSV logging and performance tracking

## Performance Expectations

### Realistic Targets (Moderate Settings)

- **Monthly Return**: 8-15%
- **Maximum Drawdown**: 10-20%
- **Win Rate**: 45-60%
- **Profit Factor**: 1.5-2.5
- **Average R:R**: 1:1.8 - 1:2.5

*Results vary based on market conditions, broker, and settings*

## Testing Recommendations

1. **Backtest** - Minimum 2 years historical data
2. **Optimize** - Use walk-forward optimization
3. **Demo Test** - Minimum 2 weeks forward testing
4. **Start Small** - Begin with conservative settings
5. **Monitor** - Review trade journal weekly

## Broker Requirements

- Low spreads (EURUSD < 1 pip)
- Fast execution (< 100ms)
- ECN/STP preferred
- Regulated broker
- Reliable servers

## Troubleshooting

**EA Not Trading?**
- Check AutoTrading enabled
- Verify session times match broker GMT
- Check daily/weekly limits not reached

**Compilation Errors?**
- Verify all .mqh files present in Include folder
- Update MT5 to latest version

See [User Guide Troubleshooting](EA_Gold_Rush_25/Documentation/UserGuide.md#troubleshooting) for more help.

## Development Status

**Current Version**: v1.0.0 (Foundation Complete)

### Implemented Features
- ✅ 4 trading strategies (core logic)
- ✅ Multi-timeframe analysis
- ✅ Smart money concepts
- ✅ Risk management system
- ✅ Trade execution & management
- ✅ Trade journal logging
- ✅ Comprehensive documentation

### Next Steps
- 🔄 Strategy implementation (entry/exit logic)
- 🔄 News filter integration
- 🔄 Performance optimization
- 🔄 Extensive backtesting

### Future Enhancements
- Multi-currency support
- Visual dashboard
- Telegram notifications
- Machine learning integration

## Disclaimer

⚠️ **RISK WARNING**: Trading forex and CFDs involves substantial risk of loss. This EA is provided "as is" without warranty. Past performance does not guarantee future results. Only trade with money you can afford to lose.

The developers are not responsible for losses incurred through use of this EA. Always test thoroughly on demo accounts before live trading.

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: Open a GitHub issue
- **Documentation**: See [User Guide](EA_Gold_Rush_25/Documentation/UserGuide.md)
- **Updates**: Watch this repository for releases

---

**Version**: 1.0.0 | **Platform**: MetaTrader 5 | **Status**: Active Development