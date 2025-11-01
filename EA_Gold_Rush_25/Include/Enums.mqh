//+------------------------------------------------------------------+
//|                                                       Enums.mqh  |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Common Enumerations                                               |
//+------------------------------------------------------------------+

// Trend Direction
enum ENUM_TREND_DIRECTION
{
   TREND_BULLISH = 1,  // Bullish Trend
   TREND_BEARISH = -1, // Bearish Trend
   TREND_NEUTRAL = 0   // Neutral/Sideways
};

// Trailing Stop Types
enum ENUM_TRAIL_TYPE
{
   TRAIL_FIXED = 0,    // Fixed Pip Trailing
   TRAIL_BY_EMA = 1,   // Trail by EMA
   TRAIL_BY_ATR = 2    // Trail by ATR
};

// Risk Reward Ratios
enum ENUM_RISK_REWARD
{
   RR_1_TO_1 = 0,      // 1:1 Risk Reward
   RR_1_TO_15 = 1,     // 1:1.5 Risk Reward
   RR_1_TO_2 = 2,      // 1:2 Risk Reward
   RR_1_TO_25 = 3,     // 1:2.5 Risk Reward
   RR_1_TO_3 = 4       // 1:3 Risk Reward
};

// News Impact Levels
enum ENUM_NEWS_IMPACT
{
   NEWS_LOW = 0,       // Low Impact
   NEWS_MEDIUM = 1,    // Medium Impact
   NEWS_HIGH = 2       // High Impact
};

// Strategy Types
enum ENUM_STRATEGY_TYPE
{
   STRATEGY_TREND_CONTINUATION = 0,  // Trend Continuation
   STRATEGY_SR_BOUNCE = 1,           // Support/Resistance Bounce
   STRATEGY_BREAKOUT = 2,            // Breakout
   STRATEGY_LONDON_OPEN = 3          // London Open
};
//+------------------------------------------------------------------+
