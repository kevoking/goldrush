//+------------------------------------------------------------------+
//|                                          SmartMoneyLogic.mqh     |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Structures for Smart Money Concepts                              |
//+------------------------------------------------------------------+
struct OrderBlock
{
   datetime time;
   double highPrice;
   double lowPrice;
   bool isBullish;
   int strength;          // 1-5 rating
   bool tested;
   datetime lastTest;
};

struct FairValueGap
{
   datetime time;
   double upperLevel;
   double lowerLevel;
   bool isBullish;
   bool filled;
   datetime filledTime;
};

struct LiquidityGrab
{
   datetime time;
   double level;
   bool isBullish;       // True if sweep low then up, false if sweep high then down
   bool confirmed;
};

//+------------------------------------------------------------------+
//| Smart Money Logic Class                                           |
//+------------------------------------------------------------------+
class CSmartMoneyLogic
{
private:
   string m_symbol;
   int m_lookbackBars;

   // Storage arrays
   OrderBlock m_orderBlocks[];
   FairValueGap m_fvGaps[];
   LiquidityGrab m_liquidityGrabs[];

   // Helper functions
   bool IsImpulsiveMove(ENUM_TIMEFRAMES timeframe, int startBar, int endBar);
   int CalculateBlockStrength(double blockSize, long volume);

public:
   // Constructor/Destructor
   CSmartMoneyLogic();
   ~CSmartMoneyLogic();

   // Initialization
   void Initialize(string symbol, int lookback);

   // Order Block Detection
   bool DetectOrderBlocks(ENUM_TIMEFRAMES timeframe);
   int GetOrderBlockCount();
   bool IsInOrderBlock(double price, bool &isBullish, double &blockHigh, double &blockLow);
   bool CheckOrderBlockRetest(double currentPrice);
   void UpdateOrderBlocks(ENUM_TIMEFRAMES timeframe);

   // Fair Value Gap Detection
   bool DetectFairValueGaps(ENUM_TIMEFRAMES timeframe);
   int GetFVGCount();
   bool IsInFairValueGap(double price, bool &isBullish);
   bool HasUnfilledFVG(bool bullish);

   // Liquidity Grab Detection
   bool DetectLiquidityGrabs(ENUM_TIMEFRAMES timeframe);
   bool WasRecentLiquidityGrab(int barsBack);
   bool IsLiquidityGrabSetup(ENUM_TIMEFRAMES timeframe, bool &bullish);

   // Analysis functions
   bool IsSmartMoneyBullish(ENUM_TIMEFRAMES timeframe);
   bool IsSmartMoneyBearish(ENUM_TIMEFRAMES timeframe);
   void PrintSmartMoneyAnalysis();

   // Utility
   void ClearOldData(int maxAge);
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CSmartMoneyLogic::CSmartMoneyLogic()
{
   m_symbol = _Symbol;
   m_lookbackBars = 20;

   ArrayResize(m_orderBlocks, 0);
   ArrayResize(m_fvGaps, 0);
   ArrayResize(m_liquidityGrabs, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CSmartMoneyLogic::~CSmartMoneyLogic()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                         |
//+------------------------------------------------------------------+
void CSmartMoneyLogic::Initialize(string symbol, int lookback)
{
   m_symbol = symbol;
   m_lookbackBars = lookback;
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                              |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::DetectOrderBlocks(ENUM_TIMEFRAMES timeframe)
{
   ArrayResize(m_orderBlocks, 0);

   // Scan for order blocks
   for(int i = 3; i < m_lookbackBars; i++)
   {
      // Bullish Order Block:
      // Last bullish candle before strong bearish move, then strong bullish reversal

      double open = iOpen(m_symbol, timeframe, i);
      double close = iClose(m_symbol, timeframe, i);
      double high = iHigh(m_symbol, timeframe, i);
      double low = iLow(m_symbol, timeframe, i);

      // Check for bullish candle
      if(close > open)
      {
         // Check if followed by bearish move (next 2-3 candles down)
         bool bearishMove = true;
         for(int j = i - 1; j >= i - 2 && j >= 0; j--)
         {
            if(iClose(m_symbol, timeframe, j) >= iClose(m_symbol, timeframe, j + 1))
            {
               bearishMove = false;
               break;
            }
         }

         if(bearishMove)
         {
            // This is a potential bullish order block
            OrderBlock block;
            block.time = iTime(m_symbol, timeframe, i);
            block.highPrice = high;
            block.lowPrice = low;
            block.isBullish = true;
            block.tested = false;
            block.lastTest = 0;

            // Calculate strength based on candle size and volume
            long volume = iVolume(m_symbol, timeframe, i);
            block.strength = CalculateBlockStrength(high - low, volume);

            int size = ArraySize(m_orderBlocks);
            ArrayResize(m_orderBlocks, size + 1);
            m_orderBlocks[size] = block;
         }
      }
      // Check for bearish candle (bearish order block)
      else if(close < open)
      {
         // Check if followed by bullish move
         bool bullishMove = true;
         for(int j = i - 1; j >= i - 2 && j >= 0; j--)
         {
            if(iClose(m_symbol, timeframe, j) <= iClose(m_symbol, timeframe, j + 1))
            {
               bullishMove = false;
               break;
            }
         }

         if(bullishMove)
         {
            // This is a potential bearish order block
            OrderBlock block;
            block.time = iTime(m_symbol, timeframe, i);
            block.highPrice = high;
            block.lowPrice = low;
            block.isBullish = false;
            block.tested = false;
            block.lastTest = 0;

            long volume = iVolume(m_symbol, timeframe, i);
            block.strength = CalculateBlockStrength(high - low, volume);

            int size = ArraySize(m_orderBlocks);
            ArrayResize(m_orderBlocks, size + 1);
            m_orderBlocks[size] = block;
         }
      }
   }

   return (ArraySize(m_orderBlocks) > 0);
}

//+------------------------------------------------------------------+
//| Calculate order block strength                                   |
//+------------------------------------------------------------------+
int CSmartMoneyLogic::CalculateBlockStrength(double blockSize, long volume)
{
   // Get average candle size
   double avgSize = 0;
   for(int i = 1; i <= 20; i++)
   {
      avgSize += iHigh(m_symbol, PERIOD_CURRENT, i) - iLow(m_symbol, PERIOD_CURRENT, i);
   }
   avgSize /= 20;

   // Get average volume
   long avgVolume = 0;
   for(int i = 1; i <= 20; i++)
   {
      avgVolume += iVolume(m_symbol, PERIOD_CURRENT, i);
   }
   avgVolume /= 20;

   int strength = 1;

   // Increase strength based on size
   if(blockSize > avgSize * 1.5) strength++;
   if(blockSize > avgSize * 2.0) strength++;

   // Increase strength based on volume
   if(volume > avgVolume * 1.5) strength++;
   if(volume > avgVolume * 2.0) strength++;

   return MathMin(strength, 5);
}

//+------------------------------------------------------------------+
//| Get order block count                                            |
//+------------------------------------------------------------------+
int CSmartMoneyLogic::GetOrderBlockCount()
{
   return ArraySize(m_orderBlocks);
}

//+------------------------------------------------------------------+
//| Check if price is in an order block                              |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::IsInOrderBlock(double price, bool &isBullish, double &blockHigh, double &blockLow)
{
   for(int i = 0; i < ArraySize(m_orderBlocks); i++)
   {
      if(price >= m_orderBlocks[i].lowPrice && price <= m_orderBlocks[i].highPrice)
      {
         isBullish = m_orderBlocks[i].isBullish;
         blockHigh = m_orderBlocks[i].highPrice;
         blockLow = m_orderBlocks[i].lowPrice;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check for order block retest                                     |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::CheckOrderBlockRetest(double currentPrice)
{
   for(int i = 0; i < ArraySize(m_orderBlocks); i++)
   {
      // Check if price is testing the block
      if(currentPrice >= m_orderBlocks[i].lowPrice &&
         currentPrice <= m_orderBlocks[i].highPrice)
      {
         // Update last test time
         m_orderBlocks[i].lastTest = TimeCurrent();
         m_orderBlocks[i].tested = true;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Update order blocks                                              |
//+------------------------------------------------------------------+
void CSmartMoneyLogic::UpdateOrderBlocks(ENUM_TIMEFRAMES timeframe)
{
   DetectOrderBlocks(timeframe);
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps                                           |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::DetectFairValueGaps(ENUM_TIMEFRAMES timeframe)
{
   ArrayResize(m_fvGaps, 0);

   // Scan for FVGs (3-candle pattern)
   for(int i = 2; i < m_lookbackBars; i++)
   {
      double high1 = iHigh(m_symbol, timeframe, i);
      double low1 = iLow(m_symbol, timeframe, i);
      double high2 = iHigh(m_symbol, timeframe, i - 1);
      double low2 = iLow(m_symbol, timeframe, i - 1);
      double high3 = iHigh(m_symbol, timeframe, i - 2);
      double low3 = iLow(m_symbol, timeframe, i - 2);

      // Bullish FVG: Candle 1 high < Candle 3 low (gap between them)
      if(high1 < low3)
      {
         FairValueGap fvg;
         fvg.time = iTime(m_symbol, timeframe, i - 1);
         fvg.upperLevel = low3;
         fvg.lowerLevel = high1;
         fvg.isBullish = true;
         fvg.filled = false;
         fvg.filledTime = 0;

         // Check if already filled
         double currentPrice = iClose(m_symbol, timeframe, 0);
         if(currentPrice >= fvg.lowerLevel && currentPrice <= fvg.upperLevel)
         {
            fvg.filled = true;
            fvg.filledTime = TimeCurrent();
         }

         int size = ArraySize(m_fvGaps);
         ArrayResize(m_fvGaps, size + 1);
         m_fvGaps[size] = fvg;
      }
      // Bearish FVG: Candle 1 low > Candle 3 high (gap between them)
      else if(low1 > high3)
      {
         FairValueGap fvg;
         fvg.time = iTime(m_symbol, timeframe, i - 1);
         fvg.upperLevel = low1;
         fvg.lowerLevel = high3;
         fvg.isBullish = false;
         fvg.filled = false;
         fvg.filledTime = 0;

         // Check if already filled
         double currentPrice = iClose(m_symbol, timeframe, 0);
         if(currentPrice >= fvg.lowerLevel && currentPrice <= fvg.upperLevel)
         {
            fvg.filled = true;
            fvg.filledTime = TimeCurrent();
         }

         int size = ArraySize(m_fvGaps);
         ArrayResize(m_fvGaps, size + 1);
         m_fvGaps[size] = fvg;
      }
   }

   return (ArraySize(m_fvGaps) > 0);
}

//+------------------------------------------------------------------+
//| Get FVG count                                                     |
//+------------------------------------------------------------------+
int CSmartMoneyLogic::GetFVGCount()
{
   return ArraySize(m_fvGaps);
}

//+------------------------------------------------------------------+
//| Check if price is in a Fair Value Gap                            |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::IsInFairValueGap(double price, bool &isBullish)
{
   for(int i = 0; i < ArraySize(m_fvGaps); i++)
   {
      if(!m_fvGaps[i].filled &&
         price >= m_fvGaps[i].lowerLevel &&
         price <= m_fvGaps[i].upperLevel)
      {
         isBullish = m_fvGaps[i].isBullish;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check for unfilled FVG                                           |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::HasUnfilledFVG(bool bullish)
{
   for(int i = 0; i < ArraySize(m_fvGaps); i++)
   {
      if(!m_fvGaps[i].filled && m_fvGaps[i].isBullish == bullish)
      {
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Liquidity Grabs                                           |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::DetectLiquidityGrabs(ENUM_TIMEFRAMES timeframe)
{
   ArrayResize(m_liquidityGrabs, 0);

   // Look for stop hunts - price sweeps a level then reverses
   for(int i = 2; i < m_lookbackBars - 2; i++)
   {
      double high = iHigh(m_symbol, timeframe, i);
      double low = iLow(m_symbol, timeframe, i);
      double close = iClose(m_symbol, timeframe, i);
      double open = iOpen(m_symbol, timeframe, i);

      // Find recent swing high/low
      double recentHigh = iHigh(m_symbol, timeframe, iHighest(m_symbol, timeframe, MODE_HIGH, 10, i + 1));
      double recentLow = iLow(m_symbol, timeframe, iLowest(m_symbol, timeframe, MODE_LOW, 10, i + 1));

      // Bullish liquidity grab: sweep below recent low, then strong reversal up
      if(low < recentLow)
      {
         // Check for strong bullish reversal
         bool strongReversal = false;

         // Next candle should close significantly higher
         double nextClose = iClose(m_symbol, timeframe, i - 1);
         if(nextClose > high)
         {
            strongReversal = true;
         }

         // Should have long lower wick (rejection)
         double body = MathAbs(close - open);
         double lowerWick = MathMin(open, close) - low;

         if(strongReversal && lowerWick > body * 1.5)
         {
            LiquidityGrab grab;
            grab.time = iTime(m_symbol, timeframe, i);
            grab.level = recentLow;
            grab.isBullish = true;
            grab.confirmed = true;

            int size = ArraySize(m_liquidityGrabs);
            ArrayResize(m_liquidityGrabs, size + 1);
            m_liquidityGrabs[size] = grab;
         }
      }
      // Bearish liquidity grab: sweep above recent high, then strong reversal down
      else if(high > recentHigh)
      {
         bool strongReversal = false;

         double nextClose = iClose(m_symbol, timeframe, i - 1);
         if(nextClose < low)
         {
            strongReversal = true;
         }

         double body = MathAbs(close - open);
         double upperWick = high - MathMax(open, close);

         if(strongReversal && upperWick > body * 1.5)
         {
            LiquidityGrab grab;
            grab.time = iTime(m_symbol, timeframe, i);
            grab.level = recentHigh;
            grab.isBullish = false;
            grab.confirmed = true;

            int size = ArraySize(m_liquidityGrabs);
            ArrayResize(m_liquidityGrabs, size + 1);
            m_liquidityGrabs[size] = grab;
         }
      }
   }

   return (ArraySize(m_liquidityGrabs) > 0);
}

//+------------------------------------------------------------------+
//| Check if there was a recent liquidity grab                       |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::WasRecentLiquidityGrab(int barsBack)
{
   datetime cutoffTime = iTime(m_symbol, PERIOD_CURRENT, barsBack);

   for(int i = 0; i < ArraySize(m_liquidityGrabs); i++)
   {
      if(m_liquidityGrabs[i].time >= cutoffTime && m_liquidityGrabs[i].confirmed)
      {
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check for liquidity grab setup                                   |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::IsLiquidityGrabSetup(ENUM_TIMEFRAMES timeframe, bool &bullish)
{
   if(ArraySize(m_liquidityGrabs) == 0)
      return false;

   // Check most recent liquidity grab
   int lastIndex = ArraySize(m_liquidityGrabs) - 1;

   if(m_liquidityGrabs[lastIndex].confirmed)
   {
      bullish = m_liquidityGrabs[lastIndex].isBullish;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Analyze if smart money is bullish                                |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::IsSmartMoneyBullish(ENUM_TIMEFRAMES timeframe)
{
   int bullishSignals = 0;

   // Check for bullish order blocks being respected
   for(int i = 0; i < ArraySize(m_orderBlocks); i++)
   {
      if(m_orderBlocks[i].isBullish && m_orderBlocks[i].tested)
      {
         bullishSignals++;
      }
   }

   // Check for bullish FVGs
   for(int i = 0; i < ArraySize(m_fvGaps); i++)
   {
      if(m_fvGaps[i].isBullish && !m_fvGaps[i].filled)
      {
         bullishSignals++;
      }
   }

   // Check for bullish liquidity grabs
   for(int i = 0; i < ArraySize(m_liquidityGrabs); i++)
   {
      if(m_liquidityGrabs[i].isBullish && m_liquidityGrabs[i].confirmed)
      {
         bullishSignals++;
      }
   }

   return (bullishSignals >= 2);
}

//+------------------------------------------------------------------+
//| Analyze if smart money is bearish                                |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::IsSmartMoneyBearish(ENUM_TIMEFRAMES timeframe)
{
   int bearishSignals = 0;

   // Check for bearish order blocks
   for(int i = 0; i < ArraySize(m_orderBlocks); i++)
   {
      if(!m_orderBlocks[i].isBullish && m_orderBlocks[i].tested)
      {
         bearishSignals++;
      }
   }

   // Check for bearish FVGs
   for(int i = 0; i < ArraySize(m_fvGaps); i++)
   {
      if(!m_fvGaps[i].isBullish && !m_fvGaps[i].filled)
      {
         bearishSignals++;
      }
   }

   // Check for bearish liquidity grabs
   for(int i = 0; i < ArraySize(m_liquidityGrabs); i++)
   {
      if(!m_liquidityGrabs[i].isBullish && m_liquidityGrabs[i].confirmed)
      {
         bearishSignals++;
      }
   }

   return (bearishSignals >= 2);
}

//+------------------------------------------------------------------+
//| Print smart money analysis                                       |
//+------------------------------------------------------------------+
void CSmartMoneyLogic::PrintSmartMoneyAnalysis()
{
   Print("=== Smart Money Analysis ===");
   Print("Order Blocks detected: ", ArraySize(m_orderBlocks));
   Print("Fair Value Gaps detected: ", ArraySize(m_fvGaps));
   Print("Liquidity Grabs detected: ", ArraySize(m_liquidityGrabs));

   if(IsSmartMoneyBullish(PERIOD_CURRENT))
   {
      Print("Smart Money Bias: BULLISH");
   }
   else if(IsSmartMoneyBearish(PERIOD_CURRENT))
   {
      Print("Smart Money Bias: BEARISH");
   }
   else
   {
      Print("Smart Money Bias: NEUTRAL");
   }

   Print("============================");
}

//+------------------------------------------------------------------+
//| Clear old data                                                    |
//+------------------------------------------------------------------+
void CSmartMoneyLogic::ClearOldData(int maxAge)
{
   datetime cutoffTime = TimeCurrent() - maxAge * PeriodSeconds(PERIOD_H1);

   // Clear old order blocks
   for(int i = ArraySize(m_orderBlocks) - 1; i >= 0; i--)
   {
      if(m_orderBlocks[i].time < cutoffTime)
      {
         // Remove from array
         for(int j = i; j < ArraySize(m_orderBlocks) - 1; j++)
         {
            m_orderBlocks[j] = m_orderBlocks[j + 1];
         }
         ArrayResize(m_orderBlocks, ArraySize(m_orderBlocks) - 1);
      }
   }

   // Clear old FVGs
   for(int i = ArraySize(m_fvGaps) - 1; i >= 0; i--)
   {
      if(m_fvGaps[i].time < cutoffTime)
      {
         for(int j = i; j < ArraySize(m_fvGaps) - 1; j++)
         {
            m_fvGaps[j] = m_fvGaps[j + 1];
         }
         ArrayResize(m_fvGaps, ArraySize(m_fvGaps) - 1);
      }
   }

   // Clear old liquidity grabs
   for(int i = ArraySize(m_liquidityGrabs) - 1; i >= 0; i--)
   {
      if(m_liquidityGrabs[i].time < cutoffTime)
      {
         for(int j = i; j < ArraySize(m_liquidityGrabs) - 1; j++)
         {
            m_liquidityGrabs[j] = m_liquidityGrabs[j + 1];
         }
         ArrayResize(m_liquidityGrabs, ArraySize(m_liquidityGrabs) - 1);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if move is impulsive                                       |
//+------------------------------------------------------------------+
bool CSmartMoneyLogic::IsImpulsiveMove(ENUM_TIMEFRAMES timeframe, int startBar, int endBar)
{
   // Impulsive move = strong directional move with increasing volume
   double startPrice = iClose(m_symbol, timeframe, startBar);
   double endPrice = iClose(m_symbol, timeframe, endBar);

   double priceChange = MathAbs(endPrice - startPrice);

   // Check if volume increased during the move
   long startVolume = iVolume(m_symbol, timeframe, startBar);
   long endVolume = iVolume(m_symbol, timeframe, endBar);

   return (endVolume > startVolume * 1.5 && priceChange > 0);
}
//+------------------------------------------------------------------+
