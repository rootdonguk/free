//+------------------------------------------------------------------+
//|                                           CandleBalanceRevolution|
//|                "White sum == Black sum" balance target indicator |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_plots 0

input int    LookbackBars            = 20;      // Number of closed candles to evaluate
input int    IgnoreDojiPoints        = 5;       // Ignore tiny bodies (points)
input bool   UseVolumeWeight         = false;   // Weight candle bodies by tick volume
input bool   DrawInfoLabel           = true;    // Draw status label
input color  BullTargetColor         = clrLime; // Target line color if bullish body needed
input color  BearTargetColor         = clrTomato; // Target line color if bearish body needed
input int    TargetLineWidth         = 2;

string LINE_NAME  = "CBR_Target_Line";
string LABEL_NAME = "CBR_Info_Label";

//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "CandleBalanceRevolution");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void ClearObjects()
{
   ObjectDelete(0, LINE_NAME);
   ObjectDelete(0, LABEL_NAME);
}

//+------------------------------------------------------------------+
void DrawTargetLine(const double price, const color c)
{
   if(ObjectFind(0, LINE_NAME) == -1)
      ObjectCreate(0, LINE_NAME, OBJ_HLINE, 0, 0, price);

   ObjectSetDouble(0, LINE_NAME, OBJPROP_PRICE, price);
   ObjectSetInteger(0, LINE_NAME, OBJPROP_COLOR, c);
   ObjectSetInteger(0, LINE_NAME, OBJPROP_WIDTH, TargetLineWidth);
   ObjectSetInteger(0, LINE_NAME, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, LINE_NAME, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, LINE_NAME, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
void DrawLabel(const string text, const color c)
{
   if(!DrawInfoLabel)
   {
      ObjectDelete(0, LABEL_NAME);
      return;
   }

   if(ObjectFind(0, LABEL_NAME) == -1)
      ObjectCreate(0, LABEL_NAME, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, LABEL_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_YDISTANCE, 20);
   ObjectSetString(0, LABEL_NAME, OBJPROP_TEXT, text);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_COLOR, c);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, LABEL_NAME, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total <= LookbackBars + 1)
   {
      ClearObjects();
      return(rates_total);
   }

   // MQL5 time series arrays: index 0 is current (forming) bar, 1 is last closed bar.
   double bullSum = 0.0;
   double bearSum = 0.0;

   for(int shift = 1; shift <= LookbackBars; shift++)
   {
      double body = close[shift] - open[shift];
      double absBodyPoints = MathAbs(body) / _Point;

      if(absBodyPoints < IgnoreDojiPoints)
         continue;

      double weight = 1.0;
      if(UseVolumeWeight)
         weight = (double)tick_volume[shift];

      if(body > 0.0)
         bullSum += body * weight;
      else
         bearSum += (-body) * weight;
   }

   // Required net body to force balance (bull == bear)
   // Positive requiredBody -> bullish body needed. Negative -> bearish body needed.
   double requiredBody = bearSum - bullSum;

   // Predict close of current forming candle if it closes with required body
   double predictedClose = open[0] + requiredBody;

   color lineColor = (requiredBody >= 0.0) ? BullTargetColor : BearTargetColor;
   DrawTargetLine(predictedClose, lineColor);

   string dir = "NEUTRAL";
   if(requiredBody > 0.0)
      dir = "BULL body needed";
   else if(requiredBody < 0.0)
      dir = "BEAR body needed";

   string txt = StringFormat("CBR Lookback=%d | BullSum=%.1f pts | BearSum=%.1f pts | Need=%s %.1f pts | TargetClose=%.5f",
                             LookbackBars,
                             bullSum / _Point,
                             bearSum / _Point,
                             dir,
                             MathAbs(requiredBody) / _Point,
                             predictedClose);
   DrawLabel(txt, lineColor);

   return(rates_total);
}
//+------------------------------------------------------------------+
