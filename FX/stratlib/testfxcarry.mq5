//+------------------------------------------------------------------+
//|                                G10/Asia FX Carry-to-Vol Strategy |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Math\Stat\Stat.mqh>
#include <Generic\HashMap.mqh>
#define SORT_ASCENDING  1
#define SORT_DESCENDING 2
//I made this its own include file and include in my projects. You could do the same.
#include <Arrays\ArrayObj.mqh>
#include <Sortable.mqh>

template<typename T>
class objvector : public CArrayObj
{
public:
   T  *operator[](const int index) const { return (T*)At(index);}
};
//...........

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//+--------------------------+
//| Model Inputs
input int ATRPeriod = 20;
input int topxcurrencies = 8;
static input int magicNumber = 20230610; // set magic number


// Define Global Variables
string dollarYen = "USDJPY";
string aussieDollar = "AUDUSD";
string dollarZar = "USDZAR";
string dollarPeso = "USDMXN";
string dollarYuan = "USDCNH";
string dollarLoonie = "USDCAD";
string kiwiDollar = "NZDUSD";
string dollarFranc = "USDCHF";
string euroPound = "EURGBP";
string poundDollar = "GBPUSD";
string dollarLira = "USDTRY";
string dollarZloty = "USDPLN";
string dollarForint = "USDHUF";
string dollarDKroner = "USDDKK";
string dollarNKroner = "USDNOK";
string dollarHongky = "USDHKD";
string dollarSing = "USDSGD";
string dollarBaht = "USDTHB";
string dollarKrona = "USDSEK";
string dollarCKoruna = "USDCZK";
string euroDollar = "EURUSD";

CTrade trade;

int barsTotal;


int OnInit()
  {
   trade.SetExpertMagicNumber(magicNumber);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
  
void OnTick()
{  
   int bars = iBars(_Symbol,PERIOD_D1);
   if (barsTotal<bars){
      barsTotal = bars;
      //+--------------------------------+
      //Swap Calculations                |
      //+--------------------------------+
      //USDJPY
      double USDJPYSwapLong = SymbolInfoDouble(dollarYen,SYMBOL_SWAP_LONG);
      double USDJPYSwapShort = SymbolInfoDouble(dollarYen,SYMBOL_SWAP_SHORT);
      //EURUSD
      double EURUSDSwapLong = SymbolInfoDouble(euroDollar,SYMBOL_SWAP_LONG);
      double EURUSDSwapShort = SymbolInfoDouble(euroDollar,SYMBOL_SWAP_SHORT);
      //USDZAR
      double USDZARSwapLong = SymbolInfoDouble(dollarZar,SYMBOL_SWAP_LONG);
      double USDZARSwapShort = SymbolInfoDouble(dollarZar,SYMBOL_SWAP_SHORT);
      //USDMXN
      double USDMXNSwapLong = SymbolInfoDouble(dollarPeso,SYMBOL_SWAP_LONG);
      double USDMXNSwapShort = SymbolInfoDouble(dollarPeso, SYMBOL_SWAP_SHORT);  
      Comment("USDJPY Swap Long: ",USDJPYSwapLong,
               "\nUSDJPY Swap Short: ",USDJPYSwapShort,
               "\nUSDZAR Swap Long: ", USDZARSwapLong,
               "\nUSDZAR Swap Short: ",USDZARSwapShort);
               
      //+---------------------------------+
      //Volatility Calculations           |
      //+---------------------------------+
      // Get ATR
      double USDJPYATR[],EURUSDATR[],USDZARATR[],USDMXNATR[];
      int USDJPYhandleATR = iATR(dollarYen,PERIOD_D1,ATRPeriod);
      int EURUSDhandleATR = iATR(euroDollar,PERIOD_D1,ATRPeriod);
      int USDZARhandleATR = iATR(dollarZar,PERIOD_D1,ATRPeriod);
      int USDMXNhandleATR = iATR(dollarPeso, PERIOD_D1,ATRPeriod);

   }
}