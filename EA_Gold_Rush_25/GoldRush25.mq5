//+------------------------------------------------------------------+
//|                                                  GoldRush25.mq5  |
//|                                    Professional Day Trader EA    |
//|                                      https://www.yoursite.com    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"
#property description "Professional multi-strategy day trading EA"
#property description "Implements trend continuation, S/R bounce, breakout, and session strategies"

//+------------------------------------------------------------------+
//| Include Files                                                     |
//+------------------------------------------------------------------+
#include "Include/RiskManagement.mqh"
#include "Include/TechnicalIndicators.mqh"
#include "Include/TradeExecution.mqh"
#include "Include/MultiTimeframeAnalysis.mqh"
#include "Include/SmartMoneyLogic.mqh"
#include "Include/TradeJournal.mqh"

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ENUM_RISK_REWARD
{
   RR_1_TO_1 = 0,      // 1:1 Risk Reward
   RR_1_TO_15 = 1,     // 1:1.5 Risk Reward
   RR_1_TO_2 = 2,      // 1:2 Risk Reward
   RR_1_TO_25 = 3,     // 1:2.5 Risk Reward
   RR_1_TO_3 = 4       // 1:3 Risk Reward
};

enum ENUM_TRAIL_TYPE
{
   TRAIL_FIXED = 0,    // Fixed Pip Trailing
   TRAIL_BY_EMA = 1,   // Trail by EMA
   TRAIL_BY_ATR = 2    // Trail by ATR
};

enum ENUM_NEWS_IMPACT
{
   NEWS_LOW = 0,       // Low Impact
   NEWS_MEDIUM = 1,    // Medium Impact
   NEWS_HIGH = 2       // High Impact
};

enum ENUM_TREND_DIRECTION
{
   TREND_BULLISH = 1,  // Bullish Trend
   TREND_BEARISH = -1, // Bearish Trend
   TREND_NEUTRAL = 0   // Neutral/Sideways
};

enum ENUM_STRATEGY_TYPE
{
   STRATEGY_TREND_CONTINUATION = 0,  // Trend Continuation
   STRATEGY_SR_BOUNCE = 1,           // Support/Resistance Bounce
   STRATEGY_BREAKOUT = 2,            // Breakout
   STRATEGY_LONDON_OPEN = 3          // London Open
};

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

//--- Strategy Selection
input group "=== Strategy Selection ==="
input bool UseStrategy_TrendContinuation = true;      // Enable Trend Continuation Strategy
input bool UseStrategy_SupportResistance = true;      // Enable S/R Bounce Strategy
input bool UseStrategy_Breakout = false;              // Enable Breakout Strategy
input bool UseStrategy_LondonOpen = true;             // Enable London Open Strategy

//--- Risk Management
input group "=== Risk Management ==="
input double RiskPercent = 1.0;                       // Risk Per Trade (%)
input double MaxDailyLossPercent = 3.0;               // Max Daily Loss (%)
input double MaxWeeklyLossPercent = 5.0;              // Max Weekly Loss (%)
input int MaxSimultaneousTrades = 3;                  // Max Open Trades
input ENUM_RISK_REWARD RiskRewardRatio = RR_1_TO_2;   // Risk:Reward Ratio

//--- Multi-Timeframe Analysis
input group "=== Multi-Timeframe Analysis ==="
input ENUM_TIMEFRAMES HTF_Period = PERIOD_H4;         // Higher Timeframe (Trend)
input ENUM_TIMEFRAMES MTF_Period = PERIOD_M30;        // Medium Timeframe (Entry)
input ENUM_TIMEFRAMES LTF_Period = PERIOD_M5;         // Lower Timeframe (Confirmation)

//--- Technical Indicators
input group "=== Technical Indicators ==="
input int EMA_Fast = 20;                              // Fast EMA Period
input int EMA_Slow = 50;                              // Slow EMA Period
input int EMA_Trend = 200;                            // Trend EMA Period
input int RSI_Period = 14;                            // RSI Period
input int RSI_Oversold = 30;                          // RSI Oversold Level
input int RSI_Overbought = 70;                        // RSI Overbought Level
input int MACD_Fast = 12;                             // MACD Fast Period
input int MACD_Slow = 26;                             // MACD Slow Period
input int MACD_Signal = 9;                            // MACD Signal Period
input int ATR_Period = 14;                            // ATR Period
input double ATR_StopLossMultiplier = 1.5;            // ATR SL Multiplier

//--- Trading Sessions
input group "=== Trading Sessions ==="
input bool Trade_LondonSession = true;                // Trade London Session
input bool Trade_NewYorkSession = true;               // Trade New York Session
input bool Trade_AsianSession = false;                // Trade Asian Session
input string London_StartTime = "03:00";              // London Start (Broker Time)
input string London_EndTime = "12:00";                // London End (Broker Time)
input string NewYork_StartTime = "08:00";             // NY Start (Broker Time)
input string NewYork_EndTime = "17:00";               // NY End (Broker Time)

//--- Smart Money Concepts
input group "=== Smart Money Concepts ==="
input bool Use_OrderBlocks = true;                    // Enable Order Block Detection
input bool Use_FairValueGaps = true;                  // Enable Fair Value Gaps
input bool Use_LiquidityGrabs = true;                 // Enable Liquidity Grab Detection
input int OrderBlock_Lookback = 20;                   // Order Block Lookback Bars

//--- Trade Management
input group "=== Trade Management ==="
input bool UseBreakevenStop = true;                   // Move to Breakeven
input double BreakevenTriggerRR = 1.0;                // Breakeven at RR Ratio
input bool UseTrailingStop = true;                    // Enable Trailing Stop
input ENUM_TRAIL_TYPE TrailingType = TRAIL_BY_EMA;    // Trailing Stop Type
input double TrailingStopDistance = 20.0;             // Trailing Distance (pips)
input bool PartialTakeProfit = true;                  // Enable Partial TP
input double PartialTP_Percent = 50.0;                // Close % at First TP
input double PartialTP_RR = 1.5;                      // First TP RR Ratio

//--- News Filter
input group "=== News Filter ==="
input bool AvoidHighImpactNews = true;                // Avoid High Impact News
input int NewsAvoidanceMinutes = 30;                  // Minutes Before/After News

//--- Advanced Settings
input group "=== Advanced Settings ==="
input int MagicNumber = 123456;                       // EA Magic Number
input string TradeComment = "GoldRush25";             // Trade Comment
input int Slippage = 30;                              // Max Slippage (points)
input bool SendNotifications = true;                  // Send Phone Notifications
input bool WriteTradeJournal = true;                  // Write CSV Trade Journal

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

// EA State Management
bool g_IsInitialized = false;
datetime g_LastBarTime = 0;

// Daily/Weekly Tracking
double g_DailyStartBalance = 0.0;
double g_WeeklyStartBalance = 0.0;
datetime g_LastDailyReset = 0;
datetime g_LastWeeklyReset = 0;

// Session Time Variables
int g_LondonStartHour, g_LondonStartMinute;
int g_LondonEndHour, g_LondonEndMinute;
int g_NewYorkStartHour, g_NewYorkStartMinute;
int g_NewYorkEndHour, g_NewYorkEndMinute;

// Asian Session Range (for London Open strategy)
double g_AsianHigh = 0.0;
double g_AsianLow = 0.0;
bool g_AsianRangeMarked = false;

// Trading Flags
bool g_TradingAllowed = true;
bool g_DailyLossLimitReached = false;
bool g_WeeklyLossLimitReached = false;

// Module Objects
CRiskManagement* g_RiskManager = NULL;
CTechnicalIndicators* g_Indicators = NULL;
CTradeExecution* g_TradeExecutor = NULL;
CMultiTimeframeAnalysis* g_MTFAnalysis = NULL;
CSmartMoneyLogic* g_SmartMoney = NULL;
CTradeJournal* g_Journal = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=================================================");
   Print("GoldRush25 EA - Initialization Starting");
   Print("=================================================");

   // Initialize module objects
   if(!InitializeModules())
   {
      Print("ERROR: Failed to initialize EA modules");
      return(INIT_FAILED);
   }

   // Parse session times
   if(!ParseSessionTimes())
   {
      Print("ERROR: Failed to parse session times");
      return(INIT_FAILED);
   }

   // Initialize daily/weekly tracking
   InitializePeriodTracking();

   // Validate input parameters
   if(!ValidateInputParameters())
   {
      Print("ERROR: Invalid input parameters");
      return(INIT_FAILED);
   }

   // Initialize indicators
   if(!g_Indicators.Initialize(_Symbol, HTF_Period, MTF_Period, LTF_Period))
   {
      Print("ERROR: Failed to initialize indicators");
      return(INIT_FAILED);
   }

   // Set indicator parameters
   g_Indicators.SetIndicatorParameters(EMA_Fast, EMA_Slow, EMA_Trend, RSI_Period,
                                       MACD_Fast, MACD_Slow, MACD_Signal, ATR_Period);

   // Initialize risk management
   g_RiskManager.SetParameters(_Symbol, MagicNumber, RiskPercent, MaxDailyLossPercent,
                               MaxWeeklyLossPercent, MaxSimultaneousTrades);

   // Initialize trade execution
   g_TradeExecutor.Initialize(_Symbol, MagicNumber, Slippage);

   // Initialize MTF analysis
   g_MTFAnalysis.Initialize(_Symbol, HTF_Period, MTF_Period, LTF_Period);
   g_MTFAnalysis.SetIndicatorsReference(g_Indicators);

   // Initialize Smart Money Logic
   g_SmartMoney.Initialize(_Symbol, OrderBlock_Lookback);

   // Initialize trade journal
   if(WriteTradeJournal)
   {
      if(!g_Journal.Initialize(_Symbol, MagicNumber))
      {
         Print("WARNING: Failed to initialize trade journal");
      }
   }

   g_IsInitialized = true;

   Print("=================================================");
   Print("GoldRush25 EA - Initialization Successful");
   Print("Symbol: ", _Symbol);
   Print("Magic Number: ", MagicNumber);
   Print("Risk per Trade: ", RiskPercent, "%");
   Print("Risk:Reward Ratio: ", GetRRRatioString(RiskRewardRatio));
   Print("Strategies Enabled:");
   if(UseStrategy_TrendContinuation) Print("  - Trend Continuation");
   if(UseStrategy_SupportResistance) Print("  - Support/Resistance Bounce");
   if(UseStrategy_Breakout) Print("  - Breakout");
   if(UseStrategy_LondonOpen) Print("  - London Open");
   Print("=================================================");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=================================================");
   Print("GoldRush25 EA - Deinitialization");
   Print("Reason: ", GetDeinitReasonText(reason));
   Print("=================================================");

   // Release indicator handles
   if(g_Indicators != NULL)
   {
      g_Indicators.Release();
      delete g_Indicators;
      g_Indicators = NULL;
   }

   // Clean up other modules
   if(g_RiskManager != NULL)
   {
      delete g_RiskManager;
      g_RiskManager = NULL;
   }

   if(g_TradeExecutor != NULL)
   {
      delete g_TradeExecutor;
      g_TradeExecutor = NULL;
   }

   if(g_MTFAnalysis != NULL)
   {
      delete g_MTFAnalysis;
      g_MTFAnalysis = NULL;
   }

   if(g_SmartMoney != NULL)
   {
      delete g_SmartMoney;
      g_SmartMoney = NULL;
   }

   if(g_Journal != NULL)
   {
      g_Journal.Close();
      delete g_Journal;
      g_Journal = NULL;
   }

   Print("GoldRush25 EA - Deinitialization Complete");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if EA is properly initialized
   if(!g_IsInitialized) return;

   // Check for new bar (optional - uncomment to trade only on new bars)
   // if(!IsNewBar()) return;

   // Update period tracking (daily/weekly resets)
   UpdatePeriodTracking();

   // Pre-trading checks
   if(!IsTradingAllowed()) return;
   if(IsHighImpactNewsTime()) return;
   if(!IsWithinTradingSession()) return;
   if(DailyLossLimitReached()) return;
   if(WeeklyLossLimitReached()) return;

   // Manage existing open trades
   ManageOpenTrades();

   // Check if we can open new positions
   if(MaxPositionsReached()) return;

   // Strategy Detection and Execution
   CheckAndExecuteStrategies();
}

//+------------------------------------------------------------------+
//| Trade event handler                                               |
//+------------------------------------------------------------------+
void OnTrade()
{
   // This function is called when trade operations are performed
   // Useful for tracking trade events and logging

   if(WriteTradeJournal && g_Journal != NULL)
   {
      g_Journal.OnTradeEvent();
   }
}

//+------------------------------------------------------------------+
//| Initialize all EA modules                                         |
//+------------------------------------------------------------------+
bool InitializeModules()
{
   g_RiskManager = new CRiskManagement();
   if(g_RiskManager == NULL)
   {
      Print("ERROR: Failed to create RiskManagement object");
      return false;
   }

   g_Indicators = new CTechnicalIndicators();
   if(g_Indicators == NULL)
   {
      Print("ERROR: Failed to create TechnicalIndicators object");
      return false;
   }

   g_TradeExecutor = new CTradeExecution();
   if(g_TradeExecutor == NULL)
   {
      Print("ERROR: Failed to create TradeExecution object");
      return false;
   }

   g_MTFAnalysis = new CMultiTimeframeAnalysis();
   if(g_MTFAnalysis == NULL)
   {
      Print("ERROR: Failed to create MultiTimeframeAnalysis object");
      return false;
   }

   g_SmartMoney = new CSmartMoneyLogic();
   if(g_SmartMoney == NULL)
   {
      Print("ERROR: Failed to create SmartMoneyLogic object");
      return false;
   }

   g_Journal = new CTradeJournal();
   if(g_Journal == NULL)
   {
      Print("ERROR: Failed to create TradeJournal object");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Parse session time strings                                        |
//+------------------------------------------------------------------+
bool ParseSessionTimes()
{
   // Parse London session times
   string parts[];

   if(StringSplit(London_StartTime, ':', parts) == 2)
   {
      g_LondonStartHour = (int)StringToInteger(parts[0]);
      g_LondonStartMinute = (int)StringToInteger(parts[1]);
   }
   else
   {
      Print("ERROR: Invalid London start time format. Use HH:MM");
      return false;
   }

   if(StringSplit(London_EndTime, ':', parts) == 2)
   {
      g_LondonEndHour = (int)StringToInteger(parts[0]);
      g_LondonEndMinute = (int)StringToInteger(parts[1]);
   }
   else
   {
      Print("ERROR: Invalid London end time format. Use HH:MM");
      return false;
   }

   // Parse New York session times
   if(StringSplit(NewYork_StartTime, ':', parts) == 2)
   {
      g_NewYorkStartHour = (int)StringToInteger(parts[0]);
      g_NewYorkStartMinute = (int)StringToInteger(parts[1]);
   }
   else
   {
      Print("ERROR: Invalid New York start time format. Use HH:MM");
      return false;
   }

   if(StringSplit(NewYork_EndTime, ':', parts) == 2)
   {
      g_NewYorkEndHour = (int)StringToInteger(parts[0]);
      g_NewYorkEndMinute = (int)StringToInteger(parts[1]);
   }
   else
   {
      Print("ERROR: Invalid New York end time format. Use HH:MM");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Initialize period tracking variables                              |
//+------------------------------------------------------------------+
void InitializePeriodTracking()
{
   g_DailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_WeeklyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_LastDailyReset = TimeCurrent();
   g_LastWeeklyReset = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Validate input parameters                                         |
//+------------------------------------------------------------------+
bool ValidateInputParameters()
{
   if(RiskPercent <= 0 || RiskPercent > 10)
   {
      Print("ERROR: Risk percent must be between 0 and 10");
      return false;
   }

   if(MaxDailyLossPercent <= 0 || MaxDailyLossPercent > 20)
   {
      Print("ERROR: Max daily loss must be between 0 and 20");
      return false;
   }

   if(MaxWeeklyLossPercent <= 0 || MaxWeeklyLossPercent > 30)
   {
      Print("ERROR: Max weekly loss must be between 0 and 30");
      return false;
   }

   if(MaxSimultaneousTrades < 1 || MaxSimultaneousTrades > 10)
   {
      Print("ERROR: Max simultaneous trades must be between 1 and 10");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if new bar has formed                                       |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBarTime != g_LastBarTime)
   {
      g_LastBarTime = currentBarTime;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Update daily and weekly tracking                                  |
//+------------------------------------------------------------------+
void UpdatePeriodTracking()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Check for new trading day (reset at midnight)
   if(dt.hour == 0 && dt.min == 0)
   {
      MqlDateTime lastResetDt;
      TimeToStruct(g_LastDailyReset, lastResetDt);

      if(lastResetDt.day != dt.day)
      {
         g_DailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         g_LastDailyReset = TimeCurrent();
         g_DailyLossLimitReached = false;
         Print("Daily reset - New trading day. Starting balance: ", g_DailyStartBalance);
      }
   }

   // Check for new week (reset on Monday)
   if(dt.day_of_week == 1 && dt.hour == 0)
   {
      MqlDateTime lastWeekResetDt;
      TimeToStruct(g_LastWeeklyReset, lastWeekResetDt);

      if(lastWeekResetDt.day_of_week != 1 || lastWeekResetDt.day != dt.day)
      {
         g_WeeklyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         g_LastWeeklyReset = TimeCurrent();
         g_WeeklyLossLimitReached = false;
         Print("Weekly reset - New trading week. Starting balance: ", g_WeeklyStartBalance);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                       |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   // Check if terminal connected
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
   {
      return false;
   }

   // Check if trading is allowed for the EA
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      return false;
   }

   // Check if automated trading is enabled
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      return false;
   }

   // Check if trading is allowed for the symbol
   if(!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
   {
      return false;
   }

   return g_TradingAllowed;
}

//+------------------------------------------------------------------+
//| Check if high impact news time (placeholder)                      |
//+------------------------------------------------------------------+
bool IsHighImpactNewsTime()
{
   if(!AvoidHighImpactNews) return false;

   // TODO: Implement news filter logic
   // This is a placeholder - implement based on manual news array
   // or API integration as described in documentation

   return false;
}

//+------------------------------------------------------------------+
//| Check if within trading session                                   |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int currentMinutes = dt.hour * 60 + dt.min;

   // Check London session
   if(Trade_LondonSession)
   {
      int londonStart = g_LondonStartHour * 60 + g_LondonStartMinute;
      int londonEnd = g_LondonEndHour * 60 + g_LondonEndMinute;

      if(currentMinutes >= londonStart && currentMinutes < londonEnd)
         return true;
   }

   // Check New York session
   if(Trade_NewYorkSession)
   {
      int nyStart = g_NewYorkStartHour * 60 + g_NewYorkStartMinute;
      int nyEnd = g_NewYorkEndHour * 60 + g_NewYorkEndMinute;

      if(currentMinutes >= nyStart && currentMinutes < nyEnd)
         return true;
   }

   // Asian session (00:00 - 07:00 GMT typically)
   if(Trade_AsianSession)
   {
      if(dt.hour >= 0 && dt.hour < 7)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if daily loss limit reached                                 |
//+------------------------------------------------------------------+
bool DailyLossLimitReached()
{
   if(g_DailyLossLimitReached) return true;

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyPnL = currentBalance - g_DailyStartBalance;
   double maxLossAmount = g_DailyStartBalance * (MaxDailyLossPercent / 100.0);

   if(dailyPnL <= -maxLossAmount)
   {
      g_DailyLossLimitReached = true;

      if(SendNotifications)
      {
         SendNotification("GoldRush25: Daily loss limit reached! Trading suspended.");
      }

      Print("WARNING: Daily loss limit reached. Trading suspended until next day.");
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if weekly loss limit reached                                |
//+------------------------------------------------------------------+
bool WeeklyLossLimitReached()
{
   if(g_WeeklyLossLimitReached) return true;

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double weeklyPnL = currentBalance - g_WeeklyStartBalance;
   double maxLossAmount = g_WeeklyStartBalance * (MaxWeeklyLossPercent / 100.0);

   if(weeklyPnL <= -maxLossAmount)
   {
      g_WeeklyLossLimitReached = true;

      if(SendNotifications)
      {
         SendNotification("GoldRush25: Weekly loss limit reached! Trading suspended.");
      }

      Print("WARNING: Weekly loss limit reached. Trading suspended until next week.");
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if max positions reached                                    |
//+------------------------------------------------------------------+
bool MaxPositionsReached()
{
   int openPositions = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            openPositions++;
         }
      }
   }

   return (openPositions >= MaxSimultaneousTrades);
}

//+------------------------------------------------------------------+
//| Manage open trades (trailing, breakeven, partial TP)             |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            // Move to breakeven
            if(UseBreakevenStop)
            {
               g_TradeExecutor.CheckAndMoveToBreakeven(ticket, BreakevenTriggerRR);
            }

            // Apply trailing stop
            if(UseTrailingStop)
            {
               g_TradeExecutor.ApplyTrailingStop(ticket, TrailingType, TrailingStopDistance);
            }

            // Check partial take profit
            if(PartialTakeProfit)
            {
               g_TradeExecutor.CheckPartialTakeProfit(ticket, PartialTP_RR, PartialTP_Percent);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check and execute strategies                                      |
//+------------------------------------------------------------------+
void CheckAndExecuteStrategies()
{
   // Strategy A: Trend Continuation
   if(UseStrategy_TrendContinuation)
   {
      if(CheckTrendContinuationSetup())
      {
         ExecuteStrategy(STRATEGY_TREND_CONTINUATION);
      }
   }

   // Strategy B: Support/Resistance Bounce
   if(UseStrategy_SupportResistance)
   {
      if(CheckSRBounceSetup())
      {
         ExecuteStrategy(STRATEGY_SR_BOUNCE);
      }
   }

   // Strategy C: Breakout
   if(UseStrategy_Breakout)
   {
      if(CheckBreakoutSetup())
      {
         ExecuteStrategy(STRATEGY_BREAKOUT);
      }
   }

   // Strategy D: London Open
   if(UseStrategy_LondonOpen)
   {
      if(CheckLondonOpenSetup())
      {
         ExecuteStrategy(STRATEGY_LONDON_OPEN);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Trend Continuation Setup                                    |
//+------------------------------------------------------------------+
bool CheckTrendContinuationSetup()
{
   // Step 1: Get higher timeframe trend
   ENUM_TREND_DIRECTION htfTrend = g_MTFAnalysis.GetHigherTimeframeTrend();

   // No trade if HTF is neutral
   if(htfTrend == TREND_NEUTRAL) return false;

   // Step 2: Check if we have a valid pullback
   if(!g_MTFAnalysis.DetectPullback(htfTrend)) return false;
   if(!g_MTFAnalysis.IsPullbackValid(htfTrend)) return false;

   // Step 3: Check if pullback is complete (price near EMA on MTF)
   if(!g_MTFAnalysis.IsPullbackComplete(htfTrend)) return false;

   // Step 4: Check MTF indicators
   // Price should be near 20 or 50 EMA on MTF
   bool nearEMA20 = g_Indicators.IsPriceNearEMA(MTF_Period, EMA_Fast, 10.0);
   bool nearEMA50 = g_Indicators.IsPriceNearEMA(MTF_Period, EMA_Slow, 15.0);

   if(!nearEMA20 && !nearEMA50) return false;

   // Step 5: RSI should be in neutral zone (not overbought/oversold)
   double rsiValue = g_Indicators.GetRSIValue(MTF_Period, 0);
   if(rsiValue < 40 || rsiValue > 60) return false;

   // Step 6: Check LTF confirmation
   if(!g_MTFAnalysis.ConfirmEntryOnLowerTimeframe(htfTrend)) return false;

   // Step 7: Check for reversal pattern on LTF
   if(!g_MTFAnalysis.HasReversalPattern(LTF_Period, htfTrend)) return false;

   // Step 8: MACD cross confirmation on LTF
   bool bullishSetup = (htfTrend == TREND_BULLISH);
   if(!g_Indicators.CheckMACDCross(LTF_Period, bullishSetup)) return false;

   // Step 9: Volume confirmation
   if(!g_MTFAnalysis.HasVolumeConfirmation(LTF_Period)) return false;

   // Step 10: Optional - Smart Money confirmation
   if(Use_OrderBlocks || Use_FairValueGaps)
   {
      if(bullishSetup)
      {
         if(!g_SmartMoney.IsSmartMoneyBullish(MTF_Period)) return false;
      }
      else
      {
         if(!g_SmartMoney.IsSmartMoneyBearish(MTF_Period)) return false;
      }
   }

   // All conditions met
   Print("TREND CONTINUATION SETUP DETECTED - ", bullishSetup ? "BULLISH" : "BEARISH");
   return true;
}

//+------------------------------------------------------------------+
//| Check Support/Resistance Bounce Setup                             |
//+------------------------------------------------------------------+
bool CheckSRBounceSetup()
{
   // Step 1: Update and detect S/R levels
   g_Indicators.UpdateSRLevels(HTF_Period);

   // Step 2: Check if price is near an S/R level
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool isSupport = false;
   bool isResistance = false;

   if(!g_Indicators.IsPriceAtSRLevel(currentPrice, 15.0, isSupport, isResistance))
      return false;

   // Need to be at a clear level
   if(!isSupport && !isResistance) return false;

   // Step 3: Check for rejection candle pattern on MTF
   bool bullishRejection = false;
   bool bearishRejection = false;

   if(isSupport)
   {
      // Looking for bullish rejection at support
      bullishRejection = g_Indicators.IsPinBar(MTF_Period, 1, true) ||
                         g_Indicators.IsBullishEngulfing(MTF_Period, 1) ||
                         g_Indicators.IsHammer(MTF_Period, 1);

      if(!bullishRejection) return false;
   }

   if(isResistance)
   {
      // Looking for bearish rejection at resistance
      bearishRejection = g_Indicators.IsPinBar(MTF_Period, 1, false) ||
                         g_Indicators.IsBearishEngulfing(MTF_Period, 1) ||
                         g_Indicators.IsShootingStar(MTF_Period, 1);

      if(!bearishRejection) return false;
   }

   // Step 4: Check RSI for divergence (optional but adds confirmation)
   if(isSupport)
   {
      if(g_Indicators.CheckRSIDivergence(MTF_Period, true, 20))
      {
         Print("BULLISH RSI DIVERGENCE detected at support - strong signal");
      }
   }
   else if(isResistance)
   {
      if(g_Indicators.CheckRSIDivergence(MTF_Period, false, 20))
      {
         Print("BEARISH RSI DIVERGENCE detected at resistance - strong signal");
      }
   }

   // Step 5: Volume confirmation
   if(!g_Indicators.IsVolumeAboveAverage(MTF_Period, 1.5))
   {
      // Volume spike on rejection is preferred but not required
      Print("WARNING: Low volume on S/R rejection - weaker signal");
   }

   // Step 6: LTF confirmation
   if(isSupport && !g_MTFAnalysis.ConfirmEntryOnLowerTimeframe(TREND_BULLISH))
      return false;

   if(isResistance && !g_MTFAnalysis.ConfirmEntryOnLowerTimeframe(TREND_BEARISH))
      return false;

   // Step 7: Optional - Check smart money concepts
   if(Use_OrderBlocks)
   {
      bool isBullishBlock = false;
      double blockHigh = 0, blockLow = 0;

      if(g_SmartMoney.IsInOrderBlock(currentPrice, isBullishBlock, blockHigh, blockLow))
      {
         // Order block at S/R level adds confidence
         Print("Order block aligned with S/R level - high probability setup");
      }
   }

   // All conditions met
   Print("S/R BOUNCE SETUP DETECTED - ", isSupport ? "SUPPORT BOUNCE (BUY)" : "RESISTANCE BOUNCE (SELL)");
   return true;
}

//+------------------------------------------------------------------+
//| Check Breakout Setup                                              |
//+------------------------------------------------------------------+
bool CheckBreakoutSetup()
{
   // Step 1: Detect consolidation range on MTF
   int consolidationBars = 0;
   double rangeHigh = 0, rangeLow = 0;

   // Look for at least 15 candles in a tight range
   double atrValue = g_Indicators.GetATRValue(MTF_Period, 1);
   double avgRange = atrValue * 2.0; // Average expected range

   // Find the consolidation high and low
   rangeHigh = iHigh(_Symbol, MTF_Period, iHighest(_Symbol, MTF_Period, MODE_HIGH, 20, 1));
   rangeLow = iLow(_Symbol, MTF_Period, iLowest(_Symbol, MTF_Period, MODE_LOW, 20, 1));

   double rangeSize = rangeHigh - rangeLow;

   // Range should be relatively narrow (less than 2x ATR)
   if(rangeSize > avgRange)
   {
      // Not a tight consolidation
      return false;
   }

   // Minimum range requirement (at least 20 pips for gold, adjust for other pairs)
   double minRangePips = 20.0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;
   double minRange = minRangePips * pipSize;

   if(rangeSize < minRange)
   {
      // Range too small
      return false;
   }

   // Step 2: Check if price is breaking out
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double previousClose = iClose(_Symbol, MTF_Period, 1);

   bool bullishBreakout = (currentPrice > rangeHigh && previousClose <= rangeHigh);
   bool bearishBreakout = (currentPrice < rangeLow && previousClose >= rangeLow);

   if(!bullishBreakout && !bearishBreakout)
      return false;

   // Step 3: Check for strong breakout candle (larger than average)
   double currentCandleSize = MathAbs(iClose(_Symbol, MTF_Period, 0) - iOpen(_Symbol, MTF_Period, 0));
   double avgCandleSize = 0;

   for(int i = 1; i <= 10; i++)
   {
      avgCandleSize += MathAbs(iClose(_Symbol, MTF_Period, i) - iOpen(_Symbol, MTF_Period, i));
   }
   avgCandleSize /= 10;

   if(currentCandleSize < avgCandleSize * 1.5)
   {
      // Breakout candle not strong enough
      return false;
   }

   // Step 4: Volume confirmation - must be significantly above average
   if(!g_Indicators.IsVolumeAboveAverage(MTF_Period, 1.8))
   {
      Print("Breakout rejected: insufficient volume");
      return false;
   }

   // Step 5: Check for momentum confirmation with MACD
   if(bullishBreakout && !g_Indicators.IsMACDAligned(MTF_Period, TREND_BULLISH))
      return false;

   if(bearishBreakout && !g_Indicators.IsMACDAligned(MTF_Period, TREND_BEARISH))
      return false;

   // Step 6: Check for immediate reversal (false breakout)
   // If the current candle has already reversed significantly, skip
   double currentHigh = iHigh(_Symbol, MTF_Period, 0);
   double currentLow = iLow(_Symbol, MTF_Period, 0);
   double currentRange = currentHigh - currentLow;

   if(bullishBreakout)
   {
      // Check if price hasn't pulled back too much
      if(currentPrice < currentHigh - (currentRange * 0.5))
      {
         Print("Breakout rejected: price already retraced 50%");
         return false;
      }
   }

   if(bearishBreakout)
   {
      // Check if price hasn't pulled back too much
      if(currentPrice > currentLow + (currentRange * 0.5))
      {
         Print("Breakout rejected: price already retraced 50%");
         return false;
      }
   }

   // Step 7: LTF confirmation
   if(bullishBreakout && !g_MTFAnalysis.ConfirmEntryOnLowerTimeframe(TREND_BULLISH))
      return false;

   if(bearishBreakout && !g_MTFAnalysis.ConfirmEntryOnLowerTimeframe(TREND_BEARISH))
      return false;

   // All conditions met
   Print("BREAKOUT SETUP DETECTED - ", bullishBreakout ? "BULLISH BREAKOUT" : "BEARISH BREAKOUT");
   Print("Range: ", rangeLow, " - ", rangeHigh, " (", DoubleToString(rangeSize/pipSize, 1), " pips)");
   return true;
}

//+------------------------------------------------------------------+
//| Check London Open Setup                                           |
//+------------------------------------------------------------------+
bool CheckLondonOpenSetup()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Step 1: Mark Asian session range (00:00 - 07:00 GMT)
   // Asian session is 0-7 hours, adjust based on broker time
   int currentHour = dt.hour;

   // During Asian session (adjust for broker GMT offset)
   if(currentHour >= 0 && currentHour < 7)
   {
      // Update Asian range
      double asianHigh = iHigh(_Symbol, PERIOD_H1, iHighest(_Symbol, PERIOD_H1, MODE_HIGH, currentHour + 1, 0));
      double asianLow = iLow(_Symbol, PERIOD_H1, iLowest(_Symbol, PERIOD_H1, MODE_LOW, currentHour + 1, 0));

      if(asianHigh > 0 && asianLow > 0)
      {
         g_AsianHigh = asianHigh;
         g_AsianLow = asianLow;
         g_AsianRangeMarked = true;
      }

      // Don't trade during Asian session
      return false;
   }

   // Step 2: Check if we're in London open window (07:00 - 09:00 GMT)
   if(currentHour < 7 || currentHour > 9)
   {
      // Reset flag if past London open window
      if(currentHour >= 12)
      {
         g_AsianRangeMarked = false;
         g_AsianHigh = 0;
         g_AsianLow = 0;
      }
      return false;
   }

   // Step 3: Verify Asian range was marked
   if(!g_AsianRangeMarked || g_AsianHigh <= 0 || g_AsianLow <= 0)
   {
      Print("Asian range not properly marked");
      return false;
   }

   // Step 4: Check Asian range size (minimum 20 pips)
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;

   double asianRangeSize = g_AsianHigh - g_AsianLow;
   double asianRangePips = asianRangeSize / pipSize;

   if(asianRangePips < 20)
   {
      Print("Asian range too small: ", DoubleToString(asianRangePips, 1), " pips (min 20)");
      return false;
   }

   // Avoid if Asian range is too large (choppy/unclear)
   if(asianRangePips > 150)
   {
      Print("Asian range too large: ", DoubleToString(asianRangePips, 1), " pips - likely choppy");
      return false;
   }

   // Step 5: Check for breakout of Asian range
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   bool bullishBreakout = (currentAsk > g_AsianHigh);
   bool bearishBreakout = (currentPrice < g_AsianLow);

   if(!bullishBreakout && !bearishBreakout)
   {
      // No breakout yet
      return false;
   }

   // Step 6: Volume surge confirmation
   if(!g_Indicators.IsVolumeAboveAverage(PERIOD_M15, 1.5))
   {
      Print("London Open: Insufficient volume for breakout");
      return false;
   }

   // Step 7: Check that breakout is clean (not whipsaw)
   // Look at the last few M5 candles to ensure directional move
   int consecutiveBars = 0;
   if(bullishBreakout)
   {
      for(int i = 0; i < 3; i++)
      {
         if(iClose(_Symbol, PERIOD_M5, i) > iOpen(_Symbol, PERIOD_M5, i))
            consecutiveBars++;
      }
   }
   else if(bearishBreakout)
   {
      for(int i = 0; i < 3; i++)
      {
         if(iClose(_Symbol, PERIOD_M5, i) < iOpen(_Symbol, PERIOD_M5, i))
            consecutiveBars++;
      }
   }

   if(consecutiveBars < 2)
   {
      Print("London Open: Not enough directional momentum");
      return false;
   }

   // Step 8: Optional - Avoid Fridays (less reliable)
   if(dt.day_of_week == 5)
   {
      Print("WARNING: Friday London Open - lower reliability");
      // Still allow trade but with caution
   }

   // Step 9: MACD confirmation
   if(bullishBreakout && !g_Indicators.IsMACDAligned(PERIOD_M15, TREND_BULLISH))
      return false;

   if(bearishBreakout && !g_Indicators.IsMACDAligned(PERIOD_M15, TREND_BEARISH))
      return false;

   // All conditions met
   Print("LONDON OPEN SETUP DETECTED - ", bullishBreakout ? "BULLISH BREAKOUT" : "BEARISH BREAKOUT");
   Print("Asian Range: ", g_AsianLow, " - ", g_AsianHigh, " (", DoubleToString(asianRangePips, 1), " pips)");
   return true;
}

//+------------------------------------------------------------------+
//| Execute strategy                                                   |
//+------------------------------------------------------------------+
void ExecuteStrategy(ENUM_STRATEGY_TYPE strategy)
{
   // Determine trade direction based on market conditions
   ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
   string strategyName = "";
   double entryPrice = 0;
   double stopLoss = 0;
   double takeProfit = 0;

   // Get current prices
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Determine order type based on strategy
   switch(strategy)
   {
      case STRATEGY_TREND_CONTINUATION:
      {
         strategyName = "TrendContinuation";
         ENUM_TREND_DIRECTION trend = g_MTFAnalysis.GetHigherTimeframeTrend();

         if(trend == TREND_BULLISH)
         {
            orderType = ORDER_TYPE_BUY;
            entryPrice = ask;
         }
         else if(trend == TREND_BEARISH)
         {
            orderType = ORDER_TYPE_SELL;
            entryPrice = bid;
         }
         else
         {
            Print("ERROR: Cannot determine trend direction for Trend Continuation");
            return;
         }
         break;
      }

      case STRATEGY_SR_BOUNCE:
      {
         strategyName = "SR_Bounce";
         bool isSupport = false, isResistance = false;

         if(g_Indicators.IsPriceAtSRLevel(bid, 15.0, isSupport, isResistance))
         {
            if(isSupport)
            {
               orderType = ORDER_TYPE_BUY;
               entryPrice = ask;
            }
            else if(isResistance)
            {
               orderType = ORDER_TYPE_SELL;
               entryPrice = bid;
            }
         }
         else
         {
            Print("ERROR: No S/R level found for execution");
            return;
         }
         break;
      }

      case STRATEGY_BREAKOUT:
      {
         strategyName = "Breakout";
         double rangeHigh = iHigh(_Symbol, MTF_Period, iHighest(_Symbol, MTF_Period, MODE_HIGH, 20, 1));
         double rangeLow = iLow(_Symbol, MTF_Period, iLowest(_Symbol, MTF_Period, MODE_LOW, 20, 1));

         if(ask > rangeHigh)
         {
            orderType = ORDER_TYPE_BUY;
            entryPrice = ask;
         }
         else if(bid < rangeLow)
         {
            orderType = ORDER_TYPE_SELL;
            entryPrice = bid;
         }
         else
         {
            Print("ERROR: No breakout detected for execution");
            return;
         }
         break;
      }

      case STRATEGY_LONDON_OPEN:
      {
         strategyName = "LondonOpen";

         if(ask > g_AsianHigh)
         {
            orderType = ORDER_TYPE_BUY;
            entryPrice = ask;
         }
         else if(bid < g_AsianLow)
         {
            orderType = ORDER_TYPE_SELL;
            entryPrice = bid;
         }
         else
         {
            Print("ERROR: No London Open breakout for execution");
            return;
         }
         break;
      }
   }

   // Calculate Stop Loss
   double atrValue = g_Indicators.GetATRValue(MTF_Period, 1);
   stopLoss = g_RiskManager.CalculateStopLoss(orderType, atrValue, ATR_StopLossMultiplier);

   // Validate and adjust stop loss
   stopLoss = g_TradeExecutor.AdjustStopLoss(orderType, stopLoss);

   // Calculate position size based on risk
   double lotSize = g_RiskManager.CalculatePositionSizeByDistance(entryPrice, stopLoss, RiskPercent);

   // Validate lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(lotSize < minLot)
   {
      Print("ERROR: Calculated lot size ", lotSize, " is below minimum ", minLot);
      return;
   }

   if(lotSize > maxLot)
   {
      Print("WARNING: Calculated lot size ", lotSize, " exceeds maximum ", maxLot, " - adjusting");
      lotSize = maxLot;
   }

   // Calculate Take Profit based on Risk:Reward ratio
   double rrMultiplier = 2.0; // Default 1:2
   switch(RiskRewardRatio)
   {
      case RR_1_TO_1:   rrMultiplier = 1.0; break;
      case RR_1_TO_15:  rrMultiplier = 1.5; break;
      case RR_1_TO_2:   rrMultiplier = 2.0; break;
      case RR_1_TO_25:  rrMultiplier = 2.5; break;
      case RR_1_TO_3:   rrMultiplier = 3.0; break;
   }

   takeProfit = g_RiskManager.CalculateTakeProfit(entryPrice, stopLoss, rrMultiplier);

   // Validate and adjust take profit
   takeProfit = g_TradeExecutor.AdjustTakeProfit(orderType, takeProfit);

   // Final validation
   if(!g_TradeExecutor.ValidateStopLoss(orderType, entryPrice, stopLoss))
   {
      Print("ERROR: Invalid stop loss for order");
      return;
   }

   if(!g_TradeExecutor.ValidateTakeProfit(orderType, entryPrice, takeProfit))
   {
      Print("ERROR: Invalid take profit for order");
      return;
   }

   // Build comment
   string comment = TradeComment + "_" + strategyName;

   // Execute the trade
   Print("=================================================");
   Print("EXECUTING TRADE - ", strategyName);
   Print("Order Type: ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"));
   Print("Entry Price: ", entryPrice);
   Print("Stop Loss: ", stopLoss);
   Print("Take Profit: ", takeProfit);
   Print("Lot Size: ", lotSize);
   Print("Risk:Reward: 1:", rrMultiplier);
   Print("=================================================");

   ulong ticket = g_TradeExecutor.OpenMarketOrder(orderType, lotSize, stopLoss, takeProfit, comment);

   if(ticket > 0)
   {
      Print("SUCCESS: Trade opened with ticket #", ticket);

      // Log to journal if enabled
      if(WriteTradeJournal && g_Journal != NULL)
      {
         // Journal will automatically log via OnTrade event
      }

      // Send notification if enabled
      if(SendNotifications)
      {
         string direction = (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL");
         string notification = "GoldRush25: " + direction + " " + strategyName +
                             " | Entry: " + DoubleToString(entryPrice, 2) +
                             " | SL: " + DoubleToString(stopLoss, 2) +
                             " | TP: " + DoubleToString(takeProfit, 2);
         SendNotification(notification);
      }
   }
   else
   {
      Print("ERROR: Failed to open trade - ", g_TradeExecutor.GetLastErrorDescription());
   }
}

//+------------------------------------------------------------------+
//| Get Risk:Reward ratio as string                                   |
//+------------------------------------------------------------------+
string GetRRRatioString(ENUM_RISK_REWARD rr)
{
   switch(rr)
   {
      case RR_1_TO_1: return "1:1";
      case RR_1_TO_15: return "1:1.5";
      case RR_1_TO_2: return "1:2";
      case RR_1_TO_25: return "1:2.5";
      case RR_1_TO_3: return "1:3";
      default: return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Get deinitialization reason text                                  |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM: return "Program stopped";
      case REASON_REMOVE: return "Program removed from chart";
      case REASON_RECOMPILE: return "Program recompiled";
      case REASON_CHARTCHANGE: return "Chart period or symbol changed";
      case REASON_CHARTCLOSE: return "Chart closed";
      case REASON_PARAMETERS: return "Input parameters changed";
      case REASON_ACCOUNT: return "Account changed";
      case REASON_TEMPLATE: return "Template changed";
      case REASON_INITFAILED: return "Initialization failed";
      case REASON_CLOSE: return "Terminal closed";
      default: return "Unknown reason";
   }
}
//+------------------------------------------------------------------+
