//+------------------------------------------------------------------+
//|                                       TechnicalIndicators.mqh    |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Structure for Support/Resistance Levels                          |
//+------------------------------------------------------------------+
struct SRLevel
{
   double price;
   int touches;
   datetime lastTouch;
   bool isSupport;
   bool isResistance;
   int strength; // 1-5 rating
};

//+------------------------------------------------------------------+
//| Technical Indicators Class                                        |
//+------------------------------------------------------------------+
class CTechnicalIndicators
{
private:
   // Symbol and timeframes
   string m_symbol;
   ENUM_TIMEFRAMES m_htf;  // Higher timeframe
   ENUM_TIMEFRAMES m_mtf;  // Medium timeframe
   ENUM_TIMEFRAMES m_ltf;  // Lower timeframe

   // EMA Handles - Multiple timeframes
   int m_emaFast_HTF, m_emaSlow_HTF, m_emaTrend_HTF;
   int m_emaFast_MTF, m_emaSlow_MTF, m_emaTrend_MTF;
   int m_emaFast_LTF, m_emaSlow_LTF, m_emaTrend_LTF;

   // RSI Handles
   int m_rsi_HTF, m_rsi_MTF, m_rsi_LTF;

   // MACD Handles
   int m_macd_HTF, m_macd_MTF, m_macd_LTF;

   // ATR Handle
   int m_atr_HTF, m_atr_MTF, m_atr_LTF;

   // Indicator parameters
   int m_emaFastPeriod;
   int m_emaSlowPeriod;
   int m_emaTrendPeriod;
   int m_rsiPeriod;
   int m_macdFast;
   int m_macdSlow;
   int m_macdSignal;
   int m_atrPeriod;

   // S/R levels storage
   SRLevel m_srLevels[];

   // Helper functions
   bool CreateIndicatorHandles();
   void ReleaseIndicatorHandles();

public:
   // Constructor/Destructor
   CTechnicalIndicators();
   ~CTechnicalIndicators();

   // Initialization
   bool Initialize(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf);
   void SetIndicatorParameters(int emaFast, int emaSlow, int emaTrend, int rsi,
                               int macdFast, int macdSlow, int macdSignal, int atr);
   void Release();

   // EMA Functions
   double GetEMAValue(ENUM_TIMEFRAMES timeframe, int period, int shift);
   bool CheckEMACross(ENUM_TIMEFRAMES timeframe, int fastPeriod, int slowPeriod, bool bullish);
   bool IsPriceAboveEMA(ENUM_TIMEFRAMES timeframe, int period, int shift);
   bool IsPriceBelowEMA(ENUM_TIMEFRAMES timeframe, int period, int shift);
   bool IsPriceNearEMA(ENUM_TIMEFRAMES timeframe, int period, double tolerancePips);

   // RSI Functions
   double GetRSIValue(ENUM_TIMEFRAMES timeframe, int shift);
   bool IsRSIOversold(ENUM_TIMEFRAMES timeframe, int level);
   bool IsRSIOverbought(ENUM_TIMEFRAMES timeframe, int level);
   bool CheckRSIDivergence(ENUM_TIMEFRAMES timeframe, bool bullish, int lookback);

   // MACD Functions
   bool GetMACDValues(ENUM_TIMEFRAMES timeframe, int shift, double &main, double &signal, double &histogram);
   bool CheckMACDCross(ENUM_TIMEFRAMES timeframe, bool bullish);
   bool IsMACDAligned(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend);
   bool IsMACDHistogramIncreasing(ENUM_TIMEFRAMES timeframe);
   bool IsMACDHistogramDecreasing(ENUM_TIMEFRAMES timeframe);

   // ATR Functions
   double GetATRValue(ENUM_TIMEFRAMES timeframe, int shift);
   bool IsVolatilityAcceptable(ENUM_TIMEFRAMES timeframe, double minATR, double maxATR);

   // Volume Functions
   long GetCurrentVolume(ENUM_TIMEFRAMES timeframe, int shift);
   double GetAverageVolume(ENUM_TIMEFRAMES timeframe, int periods);
   bool IsVolumeAboveAverage(ENUM_TIMEFRAMES timeframe, double multiplier);

   // Support/Resistance Functions
   bool DetectKeyLevels(ENUM_TIMEFRAMES timeframe, int lookback);
   bool IsPriceAtSRLevel(double price, double tolerancePips, bool &isSupport, bool &isResistance);
   int GetNearestSRLevel(double price, double &levelPrice);
   void UpdateSRLevels(ENUM_TIMEFRAMES timeframe);

   // Candlestick Pattern Functions
   bool IsBullishEngulfing(ENUM_TIMEFRAMES timeframe, int shift);
   bool IsBearishEngulfing(ENUM_TIMEFRAMES timeframe, int shift);
   bool IsPinBar(ENUM_TIMEFRAMES timeframe, int shift, bool bullish);
   bool IsHammer(ENUM_TIMEFRAMES timeframe, int shift);
   bool IsShootingStar(ENUM_TIMEFRAMES timeframe, int shift);
   bool IsDoji(ENUM_TIMEFRAMES timeframe, int shift);

   // Trend Detection
   ENUM_TREND_DIRECTION GetTrendDirection(ENUM_TIMEFRAMES timeframe);
   bool IsStrongTrend(ENUM_TIMEFRAMES timeframe);
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTechnicalIndicators::CTechnicalIndicators()
{
   m_symbol = _Symbol;
   m_htf = PERIOD_H4;
   m_mtf = PERIOD_M30;
   m_ltf = PERIOD_M5;

   // Initialize handles to invalid
   m_emaFast_HTF = INVALID_HANDLE;
   m_emaSlow_HTF = INVALID_HANDLE;
   m_emaTrend_HTF = INVALID_HANDLE;
   m_emaFast_MTF = INVALID_HANDLE;
   m_emaSlow_MTF = INVALID_HANDLE;
   m_emaTrend_MTF = INVALID_HANDLE;
   m_emaFast_LTF = INVALID_HANDLE;
   m_emaSlow_LTF = INVALID_HANDLE;
   m_emaTrend_LTF = INVALID_HANDLE;

   m_rsi_HTF = INVALID_HANDLE;
   m_rsi_MTF = INVALID_HANDLE;
   m_rsi_LTF = INVALID_HANDLE;

   m_macd_HTF = INVALID_HANDLE;
   m_macd_MTF = INVALID_HANDLE;
   m_macd_LTF = INVALID_HANDLE;

   m_atr_HTF = INVALID_HANDLE;
   m_atr_MTF = INVALID_HANDLE;
   m_atr_LTF = INVALID_HANDLE;

   // Default parameters
   m_emaFastPeriod = 20;
   m_emaSlowPeriod = 50;
   m_emaTrendPeriod = 200;
   m_rsiPeriod = 14;
   m_macdFast = 12;
   m_macdSlow = 26;
   m_macdSignal = 9;
   m_atrPeriod = 14;

   ArrayResize(m_srLevels, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CTechnicalIndicators::~CTechnicalIndicators()
{
   Release();
}

//+------------------------------------------------------------------+
//| Initialize indicators                                             |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::Initialize(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf)
{
   m_symbol = symbol;
   m_htf = htf;
   m_mtf = mtf;
   m_ltf = ltf;

   return CreateIndicatorHandles();
}

//+------------------------------------------------------------------+
//| Set indicator parameters                                          |
//+------------------------------------------------------------------+
void CTechnicalIndicators::SetIndicatorParameters(int emaFast, int emaSlow, int emaTrend, int rsi,
                                                   int macdFast, int macdSlow, int macdSignal, int atr)
{
   m_emaFastPeriod = emaFast;
   m_emaSlowPeriod = emaSlow;
   m_emaTrendPeriod = emaTrend;
   m_rsiPeriod = rsi;
   m_macdFast = macdFast;
   m_macdSlow = macdSlow;
   m_macdSignal = macdSignal;
   m_atrPeriod = atr;
}

//+------------------------------------------------------------------+
//| Create indicator handles for all timeframes                      |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::CreateIndicatorHandles()
{
   Print("Creating indicator handles...");

   // HTF Indicators
   m_emaFast_HTF = iMA(m_symbol, m_htf, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaSlow_HTF = iMA(m_symbol, m_htf, m_emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaTrend_HTF = iMA(m_symbol, m_htf, m_emaTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_rsi_HTF = iRSI(m_symbol, m_htf, m_rsiPeriod, PRICE_CLOSE);
   m_macd_HTF = iMACD(m_symbol, m_htf, m_macdFast, m_macdSlow, m_macdSignal, PRICE_CLOSE);
   m_atr_HTF = iATR(m_symbol, m_htf, m_atrPeriod);

   // MTF Indicators
   m_emaFast_MTF = iMA(m_symbol, m_mtf, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaSlow_MTF = iMA(m_symbol, m_mtf, m_emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaTrend_MTF = iMA(m_symbol, m_mtf, m_emaTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_rsi_MTF = iRSI(m_symbol, m_mtf, m_rsiPeriod, PRICE_CLOSE);
   m_macd_MTF = iMACD(m_symbol, m_mtf, m_macdFast, m_macdSlow, m_macdSignal, PRICE_CLOSE);
   m_atr_MTF = iATR(m_symbol, m_mtf, m_atrPeriod);

   // LTF Indicators
   m_emaFast_LTF = iMA(m_symbol, m_ltf, m_emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaSlow_LTF = iMA(m_symbol, m_ltf, m_emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaTrend_LTF = iMA(m_symbol, m_ltf, m_emaTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_rsi_LTF = iRSI(m_symbol, m_ltf, m_rsiPeriod, PRICE_CLOSE);
   m_macd_LTF = iMACD(m_symbol, m_ltf, m_macdFast, m_macdSlow, m_macdSignal, PRICE_CLOSE);
   m_atr_LTF = iATR(m_symbol, m_ltf, m_atrPeriod);

   // Validate all handles
   if(m_emaFast_HTF == INVALID_HANDLE || m_emaSlow_HTF == INVALID_HANDLE || m_emaTrend_HTF == INVALID_HANDLE ||
      m_emaFast_MTF == INVALID_HANDLE || m_emaSlow_MTF == INVALID_HANDLE || m_emaTrend_MTF == INVALID_HANDLE ||
      m_emaFast_LTF == INVALID_HANDLE || m_emaSlow_LTF == INVALID_HANDLE || m_emaTrend_LTF == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create EMA handles");
      return false;
   }

   if(m_rsi_HTF == INVALID_HANDLE || m_rsi_MTF == INVALID_HANDLE || m_rsi_LTF == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create RSI handles");
      return false;
   }

   if(m_macd_HTF == INVALID_HANDLE || m_macd_MTF == INVALID_HANDLE || m_macd_LTF == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create MACD handles");
      return false;
   }

   if(m_atr_HTF == INVALID_HANDLE || m_atr_MTF == INVALID_HANDLE || m_atr_LTF == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ATR handles");
      return false;
   }

   Print("All indicator handles created successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                     |
//+------------------------------------------------------------------+
void CTechnicalIndicators::Release()
{
   if(m_emaFast_HTF != INVALID_HANDLE) IndicatorRelease(m_emaFast_HTF);
   if(m_emaSlow_HTF != INVALID_HANDLE) IndicatorRelease(m_emaSlow_HTF);
   if(m_emaTrend_HTF != INVALID_HANDLE) IndicatorRelease(m_emaTrend_HTF);

   if(m_emaFast_MTF != INVALID_HANDLE) IndicatorRelease(m_emaFast_MTF);
   if(m_emaSlow_MTF != INVALID_HANDLE) IndicatorRelease(m_emaSlow_MTF);
   if(m_emaTrend_MTF != INVALID_HANDLE) IndicatorRelease(m_emaTrend_MTF);

   if(m_emaFast_LTF != INVALID_HANDLE) IndicatorRelease(m_emaFast_LTF);
   if(m_emaSlow_LTF != INVALID_HANDLE) IndicatorRelease(m_emaSlow_LTF);
   if(m_emaTrend_LTF != INVALID_HANDLE) IndicatorRelease(m_emaTrend_LTF);

   if(m_rsi_HTF != INVALID_HANDLE) IndicatorRelease(m_rsi_HTF);
   if(m_rsi_MTF != INVALID_HANDLE) IndicatorRelease(m_rsi_MTF);
   if(m_rsi_LTF != INVALID_HANDLE) IndicatorRelease(m_rsi_LTF);

   if(m_macd_HTF != INVALID_HANDLE) IndicatorRelease(m_macd_HTF);
   if(m_macd_MTF != INVALID_HANDLE) IndicatorRelease(m_macd_MTF);
   if(m_macd_LTF != INVALID_HANDLE) IndicatorRelease(m_macd_LTF);

   if(m_atr_HTF != INVALID_HANDLE) IndicatorRelease(m_atr_HTF);
   if(m_atr_MTF != INVALID_HANDLE) IndicatorRelease(m_atr_MTF);
   if(m_atr_LTF != INVALID_HANDLE) IndicatorRelease(m_atr_LTF);
}

//+------------------------------------------------------------------+
//| Get EMA value for specific timeframe and period                  |
//+------------------------------------------------------------------+
double CTechnicalIndicators::GetEMAValue(ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   int handle = INVALID_HANDLE;

   // Select the appropriate handle based on timeframe and period
   if(timeframe == m_htf)
   {
      if(period == m_emaFastPeriod) handle = m_emaFast_HTF;
      else if(period == m_emaSlowPeriod) handle = m_emaSlow_HTF;
      else if(period == m_emaTrendPeriod) handle = m_emaTrend_HTF;
   }
   else if(timeframe == m_mtf)
   {
      if(period == m_emaFastPeriod) handle = m_emaFast_MTF;
      else if(period == m_emaSlowPeriod) handle = m_emaSlow_MTF;
      else if(period == m_emaTrendPeriod) handle = m_emaTrend_MTF;
   }
   else if(timeframe == m_ltf)
   {
      if(period == m_emaFastPeriod) handle = m_emaFast_LTF;
      else if(period == m_emaSlowPeriod) handle = m_emaSlow_LTF;
      else if(period == m_emaTrendPeriod) handle = m_emaTrend_LTF;
   }

   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Invalid EMA handle for timeframe and period");
      return 0;
   }

   double buffer[];
   ArraySetAsSeries(buffer, true);

   if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
   {
      Print("ERROR: Failed to copy EMA buffer");
      return 0;
   }

   return buffer[0];
}

//+------------------------------------------------------------------+
//| Check for EMA crossover                                          |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::CheckEMACross(ENUM_TIMEFRAMES timeframe, int fastPeriod, int slowPeriod, bool bullish)
{
   double fastCurrent = GetEMAValue(timeframe, fastPeriod, 0);
   double fastPrevious = GetEMAValue(timeframe, fastPeriod, 1);
   double slowCurrent = GetEMAValue(timeframe, slowPeriod, 0);
   double slowPrevious = GetEMAValue(timeframe, slowPeriod, 1);

   if(bullish)
   {
      // Bullish cross: fast crosses above slow
      return (fastPrevious <= slowPrevious && fastCurrent > slowCurrent);
   }
   else
   {
      // Bearish cross: fast crosses below slow
      return (fastPrevious >= slowPrevious && fastCurrent < slowCurrent);
   }
}

//+------------------------------------------------------------------+
//| Check if price is above EMA                                      |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsPriceAboveEMA(ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   double emaValue = GetEMAValue(timeframe, period, shift);
   double closePrice = iClose(m_symbol, timeframe, shift);

   return (closePrice > emaValue);
}

//+------------------------------------------------------------------+
//| Check if price is below EMA                                      |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsPriceBelowEMA(ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   double emaValue = GetEMAValue(timeframe, period, shift);
   double closePrice = iClose(m_symbol, timeframe, shift);

   return (closePrice < emaValue);
}

//+------------------------------------------------------------------+
//| Check if price is near EMA (within tolerance)                    |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsPriceNearEMA(ENUM_TIMEFRAMES timeframe, int period, double tolerancePips)
{
   double emaValue = GetEMAValue(timeframe, period, 0);
   double currentPrice = iClose(m_symbol, timeframe, 0);

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   // Adjust for 3/5 digit brokers
   if(digits == 3 || digits == 5)
      point *= 10;

   double tolerance = tolerancePips * point;
   double distance = MathAbs(currentPrice - emaValue);

   return (distance <= tolerance);
}

//+------------------------------------------------------------------+
//| Get RSI value                                                     |
//+------------------------------------------------------------------+
double CTechnicalIndicators::GetRSIValue(ENUM_TIMEFRAMES timeframe, int shift)
{
   int handle = INVALID_HANDLE;

   if(timeframe == m_htf) handle = m_rsi_HTF;
   else if(timeframe == m_mtf) handle = m_rsi_MTF;
   else if(timeframe == m_ltf) handle = m_rsi_LTF;

   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Invalid RSI handle");
      return 0;
   }

   double buffer[];
   ArraySetAsSeries(buffer, true);

   if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
   {
      Print("ERROR: Failed to copy RSI buffer");
      return 0;
   }

   return buffer[0];
}

//+------------------------------------------------------------------+
//| Check if RSI is oversold                                         |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsRSIOversold(ENUM_TIMEFRAMES timeframe, int level)
{
   double rsi = GetRSIValue(timeframe, 0);
   return (rsi < level);
}

//+------------------------------------------------------------------+
//| Check if RSI is overbought                                       |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsRSIOverbought(ENUM_TIMEFRAMES timeframe, int level)
{
   double rsi = GetRSIValue(timeframe, 0);
   return (rsi > level);
}

//+------------------------------------------------------------------+
//| Check for RSI divergence                                         |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::CheckRSIDivergence(ENUM_TIMEFRAMES timeframe, bool bullish, int lookback)
{
   // Find price swing points
   double priceHigh = iHigh(m_symbol, timeframe, iHighest(m_symbol, timeframe, MODE_HIGH, lookback, 1));
   double priceLow = iLow(m_symbol, timeframe, iLowest(m_symbol, timeframe, MODE_LOW, lookback, 1));

   // Get corresponding RSI values
   int highBar = iHighest(m_symbol, timeframe, MODE_HIGH, lookback, 1);
   int lowBar = iLowest(m_symbol, timeframe, MODE_LOW, lookback, 1);

   double rsiAtHigh = GetRSIValue(timeframe, highBar);
   double rsiAtLow = GetRSIValue(timeframe, lowBar);
   double rsiCurrent = GetRSIValue(timeframe, 0);

   if(bullish)
   {
      // Bullish divergence: price makes lower low, RSI makes higher low
      double currentLow = iLow(m_symbol, timeframe, 0);
      return (currentLow < priceLow && rsiCurrent > rsiAtLow);
   }
   else
   {
      // Bearish divergence: price makes higher high, RSI makes lower high
      double currentHigh = iHigh(m_symbol, timeframe, 0);
      return (currentHigh > priceHigh && rsiCurrent < rsiAtHigh);
   }
}

//+------------------------------------------------------------------+
//| Get MACD values                                                   |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::GetMACDValues(ENUM_TIMEFRAMES timeframe, int shift, double &main, double &signal, double &histogram)
{
   int handle = INVALID_HANDLE;

   if(timeframe == m_htf) handle = m_macd_HTF;
   else if(timeframe == m_mtf) handle = m_macd_MTF;
   else if(timeframe == m_ltf) handle = m_macd_LTF;

   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Invalid MACD handle");
      return false;
   }

   double mainBuffer[], signalBuffer[];
   ArraySetAsSeries(mainBuffer, true);
   ArraySetAsSeries(signalBuffer, true);

   if(CopyBuffer(handle, 0, shift, 1, mainBuffer) <= 0 ||
      CopyBuffer(handle, 1, shift, 1, signalBuffer) <= 0)
   {
      Print("ERROR: Failed to copy MACD buffers");
      return false;
   }

   main = mainBuffer[0];
   signal = signalBuffer[0];
   histogram = main - signal;

   return true;
}

//+------------------------------------------------------------------+
//| Check for MACD crossover                                         |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::CheckMACDCross(ENUM_TIMEFRAMES timeframe, bool bullish)
{
   double mainCurrent, signalCurrent, histCurrent;
   double mainPrevious, signalPrevious, histPrevious;

   if(!GetMACDValues(timeframe, 0, mainCurrent, signalCurrent, histCurrent))
      return false;

   if(!GetMACDValues(timeframe, 1, mainPrevious, signalPrevious, histPrevious))
      return false;

   if(bullish)
   {
      // Bullish cross: MACD crosses above signal
      return (mainPrevious <= signalPrevious && mainCurrent > signalCurrent);
   }
   else
   {
      // Bearish cross: MACD crosses below signal
      return (mainPrevious >= signalPrevious && mainCurrent < signalCurrent);
   }
}

//+------------------------------------------------------------------+
//| Check if MACD is aligned with trend                              |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsMACDAligned(ENUM_TIMEFRAMES timeframe, ENUM_TREND_DIRECTION trend)
{
   double main, signal, histogram;

   if(!GetMACDValues(timeframe, 0, main, signal, histogram))
      return false;

   if(trend == TREND_BULLISH)
   {
      return (main > signal && histogram > 0);
   }
   else if(trend == TREND_BEARISH)
   {
      return (main < signal && histogram < 0);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if MACD histogram is increasing                            |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsMACDHistogramIncreasing(ENUM_TIMEFRAMES timeframe)
{
   double main0, signal0, hist0;
   double main1, signal1, hist1;

   if(!GetMACDValues(timeframe, 0, main0, signal0, hist0))
      return false;

   if(!GetMACDValues(timeframe, 1, main1, signal1, hist1))
      return false;

   return (hist0 > hist1);
}

//+------------------------------------------------------------------+
//| Check if MACD histogram is decreasing                            |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsMACDHistogramDecreasing(ENUM_TIMEFRAMES timeframe)
{
   double main0, signal0, hist0;
   double main1, signal1, hist1;

   if(!GetMACDValues(timeframe, 0, main0, signal0, hist0))
      return false;

   if(!GetMACDValues(timeframe, 1, main1, signal1, hist1))
      return false;

   return (hist0 < hist1);
}

//+------------------------------------------------------------------+
//| Get ATR value                                                     |
//+------------------------------------------------------------------+
double CTechnicalIndicators::GetATRValue(ENUM_TIMEFRAMES timeframe, int shift)
{
   int handle = INVALID_HANDLE;

   if(timeframe == m_htf) handle = m_atr_HTF;
   else if(timeframe == m_mtf) handle = m_atr_MTF;
   else if(timeframe == m_ltf) handle = m_atr_LTF;

   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Invalid ATR handle");
      return 0;
   }

   double buffer[];
   ArraySetAsSeries(buffer, true);

   if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
   {
      Print("ERROR: Failed to copy ATR buffer");
      return 0;
   }

   return buffer[0];
}

//+------------------------------------------------------------------+
//| Check if volatility is within acceptable range                   |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsVolatilityAcceptable(ENUM_TIMEFRAMES timeframe, double minATR, double maxATR)
{
   double atr = GetATRValue(timeframe, 0);
   return (atr >= minATR && atr <= maxATR);
}

//+------------------------------------------------------------------+
//| Get current volume                                                |
//+------------------------------------------------------------------+
long CTechnicalIndicators::GetCurrentVolume(ENUM_TIMEFRAMES timeframe, int shift)
{
   return iVolume(m_symbol, timeframe, shift);
}

//+------------------------------------------------------------------+
//| Get average volume                                                |
//+------------------------------------------------------------------+
double CTechnicalIndicators::GetAverageVolume(ENUM_TIMEFRAMES timeframe, int periods)
{
   long totalVolume = 0;

   for(int i = 1; i <= periods; i++)
   {
      totalVolume += iVolume(m_symbol, timeframe, i);
   }

   return (double)totalVolume / periods;
}

//+------------------------------------------------------------------+
//| Check if volume is above average                                 |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsVolumeAboveAverage(ENUM_TIMEFRAMES timeframe, double multiplier)
{
   long currentVolume = GetCurrentVolume(timeframe, 0);
   double averageVolume = GetAverageVolume(timeframe, 20);

   return (currentVolume >= averageVolume * multiplier);
}

//+------------------------------------------------------------------+
//| Detect key support/resistance levels                             |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::DetectKeyLevels(ENUM_TIMEFRAMES timeframe, int lookback)
{
   ArrayResize(m_srLevels, 0);

   // Find swing highs and lows
   for(int i = 2; i < lookback - 2; i++)
   {
      double high = iHigh(m_symbol, timeframe, i);
      double low = iLow(m_symbol, timeframe, i);

      // Check if swing high
      if(high > iHigh(m_symbol, timeframe, i-1) && high > iHigh(m_symbol, timeframe, i-2) &&
         high > iHigh(m_symbol, timeframe, i+1) && high > iHigh(m_symbol, timeframe, i+2))
      {
         SRLevel level;
         level.price = high;
         level.touches = 1;
         level.lastTouch = iTime(m_symbol, timeframe, i);
         level.isSupport = false;
         level.isResistance = true;
         level.strength = 3;

         int size = ArraySize(m_srLevels);
         ArrayResize(m_srLevels, size + 1);
         m_srLevels[size] = level;
      }

      // Check if swing low
      if(low < iLow(m_symbol, timeframe, i-1) && low < iLow(m_symbol, timeframe, i-2) &&
         low < iLow(m_symbol, timeframe, i+1) && low < iLow(m_symbol, timeframe, i+2))
      {
         SRLevel level;
         level.price = low;
         level.touches = 1;
         level.lastTouch = iTime(m_symbol, timeframe, i);
         level.isSupport = true;
         level.isResistance = false;
         level.strength = 3;

         int size = ArraySize(m_srLevels);
         ArrayResize(m_srLevels, size + 1);
         m_srLevels[size] = level;
      }
   }

   return (ArraySize(m_srLevels) > 0);
}

//+------------------------------------------------------------------+
//| Check if price is at S/R level                                   |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsPriceAtSRLevel(double price, double tolerancePips, bool &isSupport, bool &isResistance)
{
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   if(digits == 3 || digits == 5)
      point *= 10;

   double tolerance = tolerancePips * point;

   for(int i = 0; i < ArraySize(m_srLevels); i++)
   {
      if(MathAbs(price - m_srLevels[i].price) <= tolerance)
      {
         isSupport = m_srLevels[i].isSupport;
         isResistance = m_srLevels[i].isResistance;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get nearest S/R level                                            |
//+------------------------------------------------------------------+
int CTechnicalIndicators::GetNearestSRLevel(double price, double &levelPrice)
{
   if(ArraySize(m_srLevels) == 0)
      return -1;

   double minDistance = DBL_MAX;
   int nearestIndex = -1;

   for(int i = 0; i < ArraySize(m_srLevels); i++)
   {
      double distance = MathAbs(price - m_srLevels[i].price);

      if(distance < minDistance)
      {
         minDistance = distance;
         nearestIndex = i;
         levelPrice = m_srLevels[i].price;
      }
   }

   return nearestIndex;
}

//+------------------------------------------------------------------+
//| Update S/R levels                                                 |
//+------------------------------------------------------------------+
void CTechnicalIndicators::UpdateSRLevels(ENUM_TIMEFRAMES timeframe)
{
   DetectKeyLevels(timeframe, 100);
}

//+------------------------------------------------------------------+
//| Check for bullish engulfing pattern                              |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsBullishEngulfing(ENUM_TIMEFRAMES timeframe, int shift)
{
   double open1 = iOpen(m_symbol, timeframe, shift + 1);
   double close1 = iClose(m_symbol, timeframe, shift + 1);
   double open0 = iOpen(m_symbol, timeframe, shift);
   double close0 = iClose(m_symbol, timeframe, shift);

   // Previous candle is bearish
   bool prevBearish = (close1 < open1);

   // Current candle is bullish
   bool currBullish = (close0 > open0);

   // Current candle engulfs previous
   bool engulfs = (open0 < close1 && close0 > open1);

   return (prevBearish && currBullish && engulfs);
}

//+------------------------------------------------------------------+
//| Check for bearish engulfing pattern                              |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsBearishEngulfing(ENUM_TIMEFRAMES timeframe, int shift)
{
   double open1 = iOpen(m_symbol, timeframe, shift + 1);
   double close1 = iClose(m_symbol, timeframe, shift + 1);
   double open0 = iOpen(m_symbol, timeframe, shift);
   double close0 = iClose(m_symbol, timeframe, shift);

   // Previous candle is bullish
   bool prevBullish = (close1 > open1);

   // Current candle is bearish
   bool currBearish = (close0 < open0);

   // Current candle engulfs previous
   bool engulfs = (open0 > close1 && close0 < open1);

   return (prevBullish && currBearish && engulfs);
}

//+------------------------------------------------------------------+
//| Check for pin bar                                                |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsPinBar(ENUM_TIMEFRAMES timeframe, int shift, bool bullish)
{
   double open = iOpen(m_symbol, timeframe, shift);
   double close = iClose(m_symbol, timeframe, shift);
   double high = iHigh(m_symbol, timeframe, shift);
   double low = iLow(m_symbol, timeframe, shift);

   double body = MathAbs(close - open);
   double totalRange = high - low;

   if(totalRange == 0) return false;

   if(bullish)
   {
      // Bullish pin bar: long lower wick
      double lowerWick = MathMin(open, close) - low;
      double upperWick = high - MathMax(open, close);

      return (lowerWick >= body * 2 && upperWick <= body * 0.5);
   }
   else
   {
      // Bearish pin bar: long upper wick
      double upperWick = high - MathMax(open, close);
      double lowerWick = MathMin(open, close) - low;

      return (upperWick >= body * 2 && lowerWick <= body * 0.5);
   }
}

//+------------------------------------------------------------------+
//| Check for hammer                                                  |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsHammer(ENUM_TIMEFRAMES timeframe, int shift)
{
   return IsPinBar(timeframe, shift, true);
}

//+------------------------------------------------------------------+
//| Check for shooting star                                          |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsShootingStar(ENUM_TIMEFRAMES timeframe, int shift)
{
   return IsPinBar(timeframe, shift, false);
}

//+------------------------------------------------------------------+
//| Check for doji                                                    |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsDoji(ENUM_TIMEFRAMES timeframe, int shift)
{
   double open = iOpen(m_symbol, timeframe, shift);
   double close = iClose(m_symbol, timeframe, shift);
   double high = iHigh(m_symbol, timeframe, shift);
   double low = iLow(m_symbol, timeframe, shift);

   double body = MathAbs(close - open);
   double totalRange = high - low;

   if(totalRange == 0) return false;

   // Body is less than 10% of total range
   return (body <= totalRange * 0.1);
}

//+------------------------------------------------------------------+
//| Get trend direction                                               |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CTechnicalIndicators::GetTrendDirection(ENUM_TIMEFRAMES timeframe)
{
   double ema200 = GetEMAValue(timeframe, m_emaTrendPeriod, 0);
   double currentPrice = iClose(m_symbol, timeframe, 0);
   double ema50 = GetEMAValue(timeframe, m_emaSlowPeriod, 0);

   // Check MACD alignment
   double main, signal, hist;
   GetMACDValues(timeframe, 0, main, signal, hist);

   // Price above 200 EMA and 50 EMA above 200 EMA = bullish
   if(currentPrice > ema200 && ema50 > ema200 && main > signal)
   {
      return TREND_BULLISH;
   }
   // Price below 200 EMA and 50 EMA below 200 EMA = bearish
   else if(currentPrice < ema200 && ema50 < ema200 && main < signal)
   {
      return TREND_BEARISH;
   }

   return TREND_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Check if trend is strong                                         |
//+------------------------------------------------------------------+
bool CTechnicalIndicators::IsStrongTrend(ENUM_TIMEFRAMES timeframe)
{
   ENUM_TREND_DIRECTION trend = GetTrendDirection(timeframe);

   if(trend == TREND_NEUTRAL)
      return false;

   // Check if 20, 50, and 200 EMAs are aligned
   double ema20 = GetEMAValue(timeframe, m_emaFastPeriod, 0);
   double ema50 = GetEMAValue(timeframe, m_emaSlowPeriod, 0);
   double ema200 = GetEMAValue(timeframe, m_emaTrendPeriod, 0);

   if(trend == TREND_BULLISH)
   {
      return (ema20 > ema50 && ema50 > ema200);
   }
   else
   {
      return (ema20 < ema50 && ema50 < ema200);
   }
}
//+------------------------------------------------------------------+
