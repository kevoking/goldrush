//+------------------------------------------------------------------+
//|                                  MultiTimeframeAnalysis.mqh      |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

#include "Enums.mqh"

// Forward declaration
#ifndef TECHNICAL_INDICATORS_INCLUDED
#include "TechnicalIndicators.mqh"
#define TECHNICAL_INDICATORS_INCLUDED
#endif

//+------------------------------------------------------------------+
//| Multi-Timeframe Analysis Class                                    |
//+------------------------------------------------------------------+
class CMultiTimeframeAnalysis
{
private:
   // Reference to indicators object (will be set externally)
   CTechnicalIndicators* m_indicators;

   // Timeframes
   ENUM_TIMEFRAMES m_htf;  // Higher timeframe
   ENUM_TIMEFRAMES m_mtf;  // Medium timeframe
   ENUM_TIMEFRAMES m_ltf;  // Lower timeframe

   string m_symbol;

   // Helper functions
   bool IsHigherHighs(ENUM_TIMEFRAMES timeframe, int lookback);
   bool IsLowerLows(ENUM_TIMEFRAMES timeframe, int lookback);

public:
   // Constructor/Destructor
   CMultiTimeframeAnalysis();
   ~CMultiTimeframeAnalysis();

   // Initialization
   void Initialize(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf);
   void SetIndicatorsReference(CTechnicalIndicators* indicators);

   // Trend Analysis
   ENUM_TREND_DIRECTION GetHigherTimeframeTrend();
   ENUM_TREND_DIRECTION GetMediumTimeframeTrend();
   ENUM_TREND_DIRECTION GetLowerTimeframeTrend();

   // Alignment Checks
   bool CheckTrendAlignment(ENUM_TREND_DIRECTION expectedTrend);
   bool AreAllTimeframesAligned();
   int GetAlignmentScore(ENUM_TREND_DIRECTION trend);

   // Pullback Detection
   bool DetectPullback(ENUM_TREND_DIRECTION trend);
   bool IsPullbackValid(ENUM_TREND_DIRECTION trend);
   bool IsPullbackComplete(ENUM_TREND_DIRECTION trend);

   // Entry Confirmation
   bool ConfirmEntryOnLowerTimeframe(ENUM_TREND_DIRECTION trend);
   bool HasReversalPattern(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend);
   bool HasVolumeConfirmation(ENUM_TIMEFRAMES timeframe);

   // Market Structure
   bool IsMarketStructureIntact(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend);
   bool HasBrokenStructure(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend);

   // Utility functions
   string GetTrendString(ENUM_TREND_DIRECTION trend);
   void PrintMTFAnalysis();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CMultiTimeframeAnalysis::CMultiTimeframeAnalysis()
{
   m_indicators = NULL;
   m_symbol = _Symbol;
   m_htf = PERIOD_H4;
   m_mtf = PERIOD_M30;
   m_ltf = PERIOD_M5;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CMultiTimeframeAnalysis::~CMultiTimeframeAnalysis()
{
   // Don't delete m_indicators as it's managed externally
}

//+------------------------------------------------------------------+
//| Initialize                                                         |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalysis::Initialize(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf)
{
   m_symbol = symbol;
   m_htf = htf;
   m_mtf = mtf;
   m_ltf = ltf;
}

//+------------------------------------------------------------------+
//| Set indicators reference                                          |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalysis::SetIndicatorsReference(CTechnicalIndicators* indicators)
{
   m_indicators = indicators;
}

//+------------------------------------------------------------------+
//| Get higher timeframe trend                                        |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CMultiTimeframeAnalysis::GetHigherTimeframeTrend()
{
   if(m_indicators == NULL)
   {
      Print("ERROR: Indicators reference not set");
      return TREND_NEUTRAL;
   }

   return m_indicators.GetTrendDirection(m_htf);
}

//+------------------------------------------------------------------+
//| Get medium timeframe trend                                        |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CMultiTimeframeAnalysis::GetMediumTimeframeTrend()
{
   if(m_indicators == NULL)
   {
      Print("ERROR: Indicators reference not set");
      return TREND_NEUTRAL;
   }

   return m_indicators.GetTrendDirection(m_mtf);
}

//+------------------------------------------------------------------+
//| Get lower timeframe trend                                         |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CMultiTimeframeAnalysis::GetLowerTimeframeTrend()
{
   if(m_indicators == NULL)
   {
      Print("ERROR: Indicators reference not set");
      return TREND_NEUTRAL;
   }

   return m_indicators.GetTrendDirection(m_ltf);
}

//+------------------------------------------------------------------+
//| Check if all timeframes align with expected trend                |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::CheckTrendAlignment(ENUM_TREND_DIRECTION expectedTrend)
{
   ENUM_TREND_DIRECTION htfTrend = GetHigherTimeframeTrend();
   ENUM_TREND_DIRECTION mtfTrend = GetMediumTimeframeTrend();
   ENUM_TREND_DIRECTION ltfTrend = GetLowerTimeframeTrend();

   // All timeframes must match the expected trend
   return (htfTrend == expectedTrend &&
           mtfTrend == expectedTrend &&
           ltfTrend == expectedTrend);
}

//+------------------------------------------------------------------+
//| Check if all timeframes are aligned (any direction)              |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::AreAllTimeframesAligned()
{
   ENUM_TREND_DIRECTION htfTrend = GetHigherTimeframeTrend();
   ENUM_TREND_DIRECTION mtfTrend = GetMediumTimeframeTrend();
   ENUM_TREND_DIRECTION ltfTrend = GetLowerTimeframeTrend();

   // All must be the same and not neutral
   return (htfTrend == mtfTrend &&
           mtfTrend == ltfTrend &&
           htfTrend != TREND_NEUTRAL);
}

//+------------------------------------------------------------------+
//| Get alignment score (0-3, higher is better)                      |
//+------------------------------------------------------------------+
int CMultiTimeframeAnalysis::GetAlignmentScore(ENUM_TREND_DIRECTION trend)
{
   int score = 0;

   if(GetHigherTimeframeTrend() == trend) score++;
   if(GetMediumTimeframeTrend() == trend) score++;
   if(GetLowerTimeframeTrend() == trend) score++;

   return score;
}

//+------------------------------------------------------------------+
//| Detect pullback on medium timeframe                              |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::DetectPullback(ENUM_TREND_DIRECTION trend)
{
   if(m_indicators == NULL) return false;

   // HTF must be in trend
   if(GetHigherTimeframeTrend() != trend)
      return false;

   // Check for pullback conditions on MTF
   if(trend == TREND_BULLISH)
   {
      // In uptrend, looking for pullback
      // Price should retrace to EMA 20 or 50
      bool priceNearEMA = m_indicators.IsPriceNearEMA(m_mtf, 20, 5.0) ||
                          m_indicators.IsPriceNearEMA(m_mtf, 50, 5.0);

      // RSI should pull back from overbought to neutral zone (40-60)
      double rsi = m_indicators.GetRSIValue(m_mtf, 0);
      bool rsiPullback = (rsi >= 40 && rsi <= 60);

      // MACD histogram should be contracting
      bool macdContracting = m_indicators.IsMACDHistogramDecreasing(m_mtf);

      return (priceNearEMA && rsiPullback);
   }
   else if(trend == TREND_BEARISH)
   {
      // In downtrend, looking for pullback
      bool priceNearEMA = m_indicators.IsPriceNearEMA(m_mtf, 20, 5.0) ||
                          m_indicators.IsPriceNearEMA(m_mtf, 50, 5.0);

      // RSI should pull back from oversold to neutral zone
      double rsi = m_indicators.GetRSIValue(m_mtf, 0);
      bool rsiPullback = (rsi >= 40 && rsi <= 60);

      return (priceNearEMA && rsiPullback);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if pullback is valid                                       |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::IsPullbackValid(ENUM_TREND_DIRECTION trend)
{
   if(m_indicators == NULL) return false;

   // Pullback should not break market structure
   if(!IsMarketStructureIntact(m_mtf, trend))
      return false;

   // Volume should be lower during pullback
   double avgVolume = m_indicators.GetAverageVolume(m_mtf, 20);
   long currentVolume = m_indicators.GetCurrentVolume(m_mtf, 0);

   bool lowVolume = (currentVolume < avgVolume * 0.8);

   return lowVolume;
}

//+------------------------------------------------------------------+
//| Check if pullback is complete (reversal starting)                |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::IsPullbackComplete(ENUM_TREND_DIRECTION trend)
{
   if(m_indicators == NULL) return false;

   if(trend == TREND_BULLISH)
   {
      // Look for bullish reversal signs
      bool bullishCandle = m_indicators.IsBullishEngulfing(m_mtf, 0) ||
                           m_indicators.IsHammer(m_mtf, 0);

      // MACD starting to turn
      bool macdTurning = m_indicators.CheckMACDCross(m_mtf, true) ||
                         m_indicators.IsMACDHistogramIncreasing(m_mtf);

      // Volume increasing
      bool volumeIncrease = m_indicators.IsVolumeAboveAverage(m_mtf, 1.2);

      return (bullishCandle && macdTurning);
   }
   else if(trend == TREND_BEARISH)
   {
      // Look for bearish reversal signs
      bool bearishCandle = m_indicators.IsBearishEngulfing(m_mtf, 0) ||
                           m_indicators.IsShootingStar(m_mtf, 0);

      // MACD starting to turn
      bool macdTurning = m_indicators.CheckMACDCross(m_mtf, false) ||
                         m_indicators.IsMACDHistogramDecreasing(m_mtf);

      return (bearishCandle && macdTurning);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Confirm entry on lower timeframe                                 |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::ConfirmEntryOnLowerTimeframe(ENUM_TREND_DIRECTION trend)
{
   if(m_indicators == NULL) return false;

   // Check for reversal pattern
   if(!HasReversalPattern(m_ltf, trend))
      return false;

   // Check for MACD cross in trend direction
   bool macdConfirm = false;

   if(trend == TREND_BULLISH)
   {
      macdConfirm = m_indicators.CheckMACDCross(m_ltf, true) ||
                    m_indicators.IsMACDAligned(m_ltf, TREND_BULLISH);
   }
   else if(trend == TREND_BEARISH)
   {
      macdConfirm = m_indicators.CheckMACDCross(m_ltf, false) ||
                    m_indicators.IsMACDAligned(m_ltf, TREND_BEARISH);
   }

   // Volume confirmation
   bool volumeConfirm = HasVolumeConfirmation(m_ltf);

   return (macdConfirm && volumeConfirm);
}

//+------------------------------------------------------------------+
//| Check for reversal pattern                                       |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::HasReversalPattern(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend)
{
   if(m_indicators == NULL) return false;

   if(trend == TREND_BULLISH)
   {
      // Bullish reversal patterns
      return (m_indicators.IsBullishEngulfing(timeframe, 0) ||
              m_indicators.IsHammer(timeframe, 0) ||
              m_indicators.IsPinBar(timeframe, 0, true));
   }
   else if(trend == TREND_BEARISH)
   {
      // Bearish reversal patterns
      return (m_indicators.IsBearishEngulfing(timeframe, 0) ||
              m_indicators.IsShootingStar(timeframe, 0) ||
              m_indicators.IsPinBar(timeframe, 0, false));
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check for volume confirmation                                    |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::HasVolumeConfirmation(ENUM_TIMEFRAMES timeframe)
{
   if(m_indicators == NULL) return false;

   // Volume should be above average
   return m_indicators.IsVolumeAboveAverage(timeframe, 1.2);
}

//+------------------------------------------------------------------+
//| Check if market structure is intact                              |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::IsMarketStructureIntact(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend)
{
   if(trend == TREND_BULLISH)
   {
      // In uptrend, should make higher highs and higher lows
      return IsHigherHighs(timeframe, 10);
   }
   else if(trend == TREND_BEARISH)
   {
      // In downtrend, should make lower lows and lower highs
      return IsLowerLows(timeframe, 10);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if structure has broken                                    |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::HasBrokenStructure(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend)
{
   return !IsMarketStructureIntact(timeframe, trend);
}

//+------------------------------------------------------------------+
//| Check for higher highs                                           |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::IsHigherHighs(ENUM_TIMEFRAMES timeframe, int lookback)
{
   // Find recent swing highs
   double high1 = 0, high2 = 0;
   int count = 0;

   for(int i = 2; i < lookback && count < 2; i++)
   {
      double currHigh = iHigh(m_symbol, timeframe, i);
      double prevHigh = iHigh(m_symbol, timeframe, i + 1);
      double nextHigh = iHigh(m_symbol, timeframe, i - 1);

      // Is it a swing high?
      if(currHigh > prevHigh && currHigh > nextHigh)
      {
         if(count == 0)
            high1 = currHigh;
         else if(count == 1)
            high2 = currHigh;

         count++;
      }
   }

   // Check if making higher highs
   return (count >= 2 && high1 > high2);
}

//+------------------------------------------------------------------+
//| Check for lower lows                                             |
//+------------------------------------------------------------------+
bool CMultiTimeframeAnalysis::IsLowerLows(ENUM_TIMEFRAMES timeframe, int lookback)
{
   // Find recent swing lows
   double low1 = 0, low2 = 0;
   int count = 0;

   for(int i = 2; i < lookback && count < 2; i++)
   {
      double currLow = iLow(m_symbol, timeframe, i);
      double prevLow = iLow(m_symbol, timeframe, i + 1);
      double nextLow = iLow(m_symbol, timeframe, i - 1);

      // Is it a swing low?
      if(currLow < prevLow && currLow < nextLow)
      {
         if(count == 0)
            low1 = currLow;
         else if(count == 1)
            low2 = currLow;

         count++;
      }
   }

   // Check if making lower lows
   return (count >= 2 && low1 < low2);
}

//+------------------------------------------------------------------+
//| Get trend direction as string                                    |
//+------------------------------------------------------------------+
string CMultiTimeframeAnalysis::GetTrendString(ENUM_TREND_DIRECTION trend)
{
   switch(trend)
   {
      case TREND_BULLISH: return "BULLISH";
      case TREND_BEARISH: return "BEARISH";
      case TREND_NEUTRAL: return "NEUTRAL";
      default: return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Print multi-timeframe analysis                                   |
//+------------------------------------------------------------------+
void CMultiTimeframeAnalysis::PrintMTFAnalysis()
{
   Print("=== Multi-Timeframe Analysis ===");
   Print("HTF (", EnumToString(m_htf), "): ", GetTrendString(GetHigherTimeframeTrend()));
   Print("MTF (", EnumToString(m_mtf), "): ", GetTrendString(GetMediumTimeframeTrend()));
   Print("LTF (", EnumToString(m_ltf), "): ", GetTrendString(GetLowerTimeframeTrend()));

   if(AreAllTimeframesAligned())
   {
      Print("Status: ALL TIMEFRAMES ALIGNED - ", GetTrendString(GetHigherTimeframeTrend()));
   }
   else
   {
      Print("Status: Timeframes not aligned");
   }

   Print("===============================");
}
//+------------------------------------------------------------------+
