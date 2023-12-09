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
   Print("Initialize");
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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
   int bars = iBars(_Symbol,PERIOD_CURRENT);
   if (barsTotal<bars){
      barsTotal = bars;

              
      //+---------------------------------+
      //            Pip Value Calculations|
      //+---------------------------------+
      double USDJPYpipval = SymbolInfoDouble(dollarYen,SYMBOL_TRADE_TICK_VALUE);
      double USDZARpipval = SymbolInfoDouble(dollarZar,SYMBOL_TRADE_TICK_VALUE);
      double USDMXNpipval = SymbolInfoDouble(dollarPeso,SYMBOL_TRADE_TICK_VALUE);
      double EURUSDpipval = SymbolInfoDouble(euroDollar,SYMBOL_TRADE_TICK_VALUE);
      double USDCNHpipval = SymbolInfoDouble(dollarYuan,SYMBOL_TRADE_TICK_VALUE);
      double USDCHFpipval = SymbolInfoDouble(dollarFranc,SYMBOL_TRADE_TICK_VALUE);
      double USDHUFpipval = SymbolInfoDouble(dollarForint,SYMBOL_TRADE_TICK_VALUE);
      //Create hashmap
      CHashMap<string,double> pipdict;
      pipdict.Add("USDJPY",USDJPYpipval);
      pipdict.Add("USDZAR",USDZARpipval);
      pipdict.Add("USDMXN",USDMXNpipval);
      pipdict.Add("EURUSD",EURUSDpipval);
      pipdict.Add("USDCNH",USDCNHpipval);
      pipdict.Add("USDCHF",USDCHFpipval);
      pipdict.Add("USDHUF",USDHUFpipval);
      double eurusdval;
      pipdict.TryGetValue("EURUSD",eurusdval);
      
      //+--------------------------------+
      //Swap Calculations                |
      //+--------------------------------+
      //USDJPY
      double USDJPYSwapLong = SymbolInfoDouble(dollarYen,SYMBOL_SWAP_LONG)*USDJPYpipval;
      double USDJPYSwapShort = SymbolInfoDouble(dollarYen,SYMBOL_SWAP_SHORT)*USDJPYpipval;
      //EURUSD
      double EURUSDSwapLong = SymbolInfoDouble(euroDollar,SYMBOL_SWAP_LONG)*EURUSDpipval;
      double EURUSDSwapShort = SymbolInfoDouble(euroDollar,SYMBOL_SWAP_SHORT)*EURUSDpipval;
      //USDZAR
      double USDZARSwapLong = SymbolInfoDouble(dollarZar,SYMBOL_SWAP_LONG)*USDZARpipval;
      double USDZARSwapShort = SymbolInfoDouble(dollarZar,SYMBOL_SWAP_SHORT)*USDZARpipval;
      //USDMXN
      double USDMXNSwapLong = SymbolInfoDouble(dollarPeso,SYMBOL_SWAP_LONG)*USDMXNpipval;
      double USDMXNSwapShort = SymbolInfoDouble(dollarPeso, SYMBOL_SWAP_SHORT)*USDMXNpipval;
      //USDCNH
      double USDCNHSwapLong = SymbolInfoDouble(dollarYuan,SYMBOL_SWAP_LONG)*USDCNHpipval;
      double USDCNHSwapShort = SymbolInfoDouble(dollarYuan, SYMBOL_SWAP_SHORT)*USDCNHpipval;
      //USDCHF
      double USDCHFSwapLong = SymbolInfoDouble(dollarFranc,SYMBOL_SWAP_LONG)*USDCHFpipval;
      double USDCHFSwapShort = SymbolInfoDouble(dollarFranc, SYMBOL_SWAP_SHORT)*USDCHFpipval; 
      //USDCHF
      double USDHUFSwapLong = SymbolInfoDouble(dollarForint,SYMBOL_SWAP_LONG)*USDHUFpipval;
      double USDHUFSwapShort = SymbolInfoDouble(dollarForint, SYMBOL_SWAP_SHORT)*USDHUFpipval;    
      Comment("USDJPY Swap Long: ",USDJPYSwapLong,
               "\nUSDJPY Swap Short: ",USDJPYSwapShort,
               "\nUSDZAR Swap Long: ", USDZARSwapLong,
               "\nUSDZAR Swap Short: ",USDZARSwapShort,
               "\nUSDJPY Pip Value: ",USDJPYpipval,
               "\nUSDZAR Pip Value: ",USDZARpipval,
               "\nUSDMXN Pip Value: ",USDMXNpipval,
               "\nEURUSD Pip Value: ",eurusdval);
      
               
      //+---------------------------------+
      //Volatility Calculations           |
      //+---------------------------------+
      // Get ATR
      double USDJPYATR[],EURUSDATR[],USDZARATR[],USDMXNATR[],USDCNHATR[],USDCHFATR[],USDHUFATR[];
      int USDJPYhandleATR = iATR(dollarYen,PERIOD_D1,ATRPeriod);
      int EURUSDhandleATR = iATR(euroDollar,PERIOD_D1,ATRPeriod);
      int USDZARhandleATR = iATR(dollarZar,PERIOD_D1,ATRPeriod);
      int USDMXNhandleATR = iATR(dollarPeso, PERIOD_D1,ATRPeriod);
      int USDCNHhandleATR = iATR(dollarYuan, PERIOD_D1,ATRPeriod);
      int USDCHFhandleATR = iATR(dollarFranc, PERIOD_D1,ATRPeriod);
      int USDHUFhandleATR = iATR(dollarForint, PERIOD_D1,ATRPeriod);

      CopyBuffer(USDJPYhandleATR,0,0,20,USDJPYATR);
      CopyBuffer(USDZARhandleATR,0,0,20,USDZARATR);
      CopyBuffer(EURUSDhandleATR,0,0,20,EURUSDATR);
      CopyBuffer(USDMXNhandleATR,0,0,20,USDMXNATR);
      CopyBuffer(USDCNHhandleATR,0,0,20,USDCNHATR);
      CopyBuffer(USDCHFhandleATR,0,0,20,USDCHFATR);
      CopyBuffer(USDHUFhandleATR,0,0,20,USDHUFATR);     
      
      //Get returns
      double USDJPYretsarr[20],EURUSDretsarr[20],USDZARretsarr[20],USDMXNretsarr[20],USDCNHretsarr[20];
      double USDCHFretsarr[20],USDHUFretsarr[20];
      for(int i=0;i<ATRPeriod;i++)
      {
      double USDJPYret = USDJPYATR[i]/iClose(dollarYen,PERIOD_D1,i);
      double EURUSDret = EURUSDATR[i]/iClose(euroDollar,PERIOD_D1,i);
      double USDZARret = USDZARATR[i]/iClose(dollarZar,PERIOD_D1,i);
      double USDMXNret = USDMXNATR[i]/iClose(dollarPeso,PERIOD_D1,i);
      double USDCNHret = USDCNHATR[i]/iClose(dollarYuan,PERIOD_D1,i);
      double USDCHFret = USDCHFATR[i]/iClose(dollarFranc,PERIOD_D1,i);
      double USDHUFret = USDHUFATR[i]/iClose(dollarForint,PERIOD_D1,i);     
      
      USDJPYretsarr[i] = USDJPYret;
      EURUSDretsarr[i] = EURUSDret;
      USDZARretsarr[i] = USDZARret;
      USDMXNretsarr[i] = USDMXNret;
      USDCNHretsarr[i] = USDCNHret;
      USDCHFretsarr[i] = USDCHFret;
      USDHUFretsarr[i] = USDHUFret;
      }
      
      double USDJPYvol = MathStandardDeviation(USDJPYretsarr);
      double EURUSDvol = MathStandardDeviation(EURUSDretsarr);
      double USDZARvol = MathStandardDeviation(EURUSDretsarr);
      double USDMXNvol = MathStandardDeviation(USDMXNretsarr);
      double USDCNHvol = MathStandardDeviation(USDCNHretsarr);
      double USDCHFvol = MathStandardDeviation(USDCHFretsarr);
      double USDHUFvol = MathStandardDeviation(USDHUFretsarr);
      
      //+----------------------------------+
      // Carry-to-Vol Calculations         |
      //+----------------------------------+
      //Long Carry
      double USDJPYlongcarryvol = USDJPYSwapLong/USDJPYvol;
      double EURUSDlongcarryvol = EURUSDSwapLong/EURUSDvol;
      double USDZARlongcarryvol = USDZARSwapLong/USDZARvol;
      double USDMXNlongcarryvol = USDMXNSwapLong/USDMXNvol;
      double USDCNHlongcarryvol = USDCNHSwapLong/USDCNHvol;
      double USDCHFlongcarryvol = USDCHFSwapLong/USDCHFvol;
      double USDHUFlongcarryvol = USDHUFSwapLong/USDHUFvol;
      //Short Carry
      double USDJPYshortcarryvol = USDJPYSwapShort/USDJPYvol;
      double EURUSDshortcarryvol = EURUSDSwapShort/EURUSDvol;
      double USDZARshortcarryvol = USDZARSwapShort/USDZARvol;
      double USDMXNshortcarryvol = USDMXNSwapShort/USDMXNvol;
      double USDCNHshortcarryvol = USDCNHSwapShort/USDCNHvol;
      double USDCHFshortcarryvol = USDCHFSwapShort/USDCHFvol;
      double USDHUFshortcarryvol = USDHUFSwapShort/USDHUFvol;
      
      //Map it out with struct
      CArrayObj *CarryVolCobj = new CArrayObj();
      AddtoArray(CarryVolCobj, USDJPYlongcarryvol,dollarYen,1);
      AddtoArray(CarryVolCobj, EURUSDlongcarryvol,euroDollar,1);
      AddtoArray(CarryVolCobj, USDZARlongcarryvol,dollarZar,1);
      AddtoArray(CarryVolCobj, USDMXNlongcarryvol,dollarPeso,1);
      AddtoArray(CarryVolCobj, USDCNHlongcarryvol,dollarYuan,1);
      AddtoArray(CarryVolCobj, USDCHFlongcarryvol,dollarFranc,1);
      AddtoArray(CarryVolCobj, USDHUFlongcarryvol,dollarForint,1);
      
      AddtoArray(CarryVolCobj, USDJPYshortcarryvol,dollarYen,-1);
      AddtoArray(CarryVolCobj, EURUSDshortcarryvol,euroDollar,-1);
      AddtoArray(CarryVolCobj, USDZARshortcarryvol,dollarZar,-1);
      AddtoArray(CarryVolCobj, USDMXNshortcarryvol,dollarPeso,-1);
      AddtoArray(CarryVolCobj, USDCNHshortcarryvol,dollarYuan,-1);
      AddtoArray(CarryVolCobj, USDCHFshortcarryvol,dollarFranc,-1);
      AddtoArray(CarryVolCobj, USDHUFshortcarryvol,dollarForint,-1);
      Print("Before");
      //PrintArray<double>(CarryVolCobj);
      CloseOrders();
      CarryVolCobj.Sort(2);
      Print("After");
      PrintArray<double>(CarryVolCobj);
      
      string tickers[5];
      double carryVol[5],direction[5],lotSize[5];
      GetTradeParams(CarryVolCobj,tickers,carryVol,direction);
      
      //Portfolio Construction
      double totalCarryVol = MathSum(carryVol);
      for(int i = 0;i<5;i++){
         lotSize[i] = (carryVol[i]/totalCarryVol)*0.1;
      }
      
      
      for (int i = 0;i<4;i++){
         //double val;
         string symbol = tickers[i];
         double dir = direction[i];
         double cv = carryVol[i];
         double bid = SymbolInfoDouble(symbol,SYMBOL_BID);
        bid = NormalizeDouble(bid,_Digits);
         double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
         ask = NormalizeDouble(ask,_Digits);
         double currentlots = currentLotSize(symbol);
         
         if(dir>0){
            double posn = 0.1*(cv/totalCarryVol);//;
            
            posn = NormalizeDouble(posn,2);
            trade.Buy(posn,symbol,ask,0,0);            
         }else if (dir<0){
            double posn =0.1*(cv/totalCarryVol);
            posn = NormalizeDouble(posn,2);
            trade.Sell(posn,symbol,bid,0,0);            
         }

      }
      


   }
   
}
//+------------------------------------------------------------------+
// Define Custom Functions

void AddtoArray(CArrayObj &arr, double key,string sValue, int iValue ){
   
   CSortableStructure *node = new CSortableStructure();
   //CSortable<T> * node = new CSortable<T>();
   
   //Assign the key
   node.key = key;
   node.stringValue = sValue;
   node.intValue = iValue;
   
   arr.Add(node);   
}

template <typename T>
void PrintArray(CArrayObj &arr){
   for (int i = 0; i <arr.Total();i++){
      CSortableStructure *node = (CSortableStructure*)arr.At(i);
      double key = node.key;
      string sValue = node.stringValue;
      int iValue  = node.intValue;
      Print("carryvol, pair, long/short: ",key," | ",sValue," | ",iValue);
   }

}

void GetTradeParams(CArrayObj &arr, string & tickers[],double & carryVol[],double& direction[]){
   for (int i = 0; i<5;i++){
      CSortableStructure *node = (CSortableStructure*)arr.At(i);
      double key = node.key;
      string sValue = node.stringValue;
      int iValue  = node.intValue;
      carryVol[i] = key;
      tickers[i] = sValue;
      direction[i] = iValue;
   }

}


      //struct carry_vol_struct {
      //   string pair;
      //   int direction;
      //   double carrytoVol;
      //   void init(string p, int d, double cv){
      //      pair = p; direction = d; carrytoVol = cv;}
      //};
      //carry_vol_struct cv_struct[];
      //cv_struct[0].init(dollarYen,1,USDJPYlongcarryvol);
      //cv_struct[1].init(dollarYen,-1,USDJPYshortcarryvol);
      //cv_struct[2].init(dollarYen,1,EURUSDlongcarryvol);
      //cv_struct[3].init(dollarYen,-1,EURUSDshortcarryvol);
      //cv_struct[4].init(dollarYen,1,USDZARlongcarryvol);
      //cv_struct[5].init(dollarYen,-1,USDZARshortcarryvol);
      //cv_struct[6].init(dollarYen,1,USDMXNlongcarryvol);
      //cv_struct[7].init(dollarYen,-1,USDMXNshortcarryvol);
      
class CSortableStructure: public CSortable<double>{
public:
   string stringValue;
   int intValue;

};


double currentLotSize(string & ticker) 
  {
   double lot=0;
   int total=PositionsTotal();
   for (int cnt= total-1;cnt>=0;cnt--){
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      string tkr = PositionGetSymbol(cnt);
      if(magic == magicNumber && tkr == ticker){
         double lots = PositionGetDouble(POSITION_VOLUME);
         long dir = PositionGetInteger(POSITION_TYPE);
         if(dir==0){dir=-1;}
         return lots*dir;
      }
   }
   return 0;
  }
  
int CloseOrders(){
   int total = PositionsTotal();
   //Print("Close Position...");
   
   for (int cnt=total-1;cnt>=0;cnt--){
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      ulong ticket = PositionGetTicket(cnt);
      
      if(magic == magicNumber){
         trade.PositionClose(ticket);
         Print("Close position...");
      }
   }
   return(0);
 }