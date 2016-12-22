// ZiGuiHedge.mqh   Version 0.01

#property copyright "Copyright (c) 2016, abc"
#property link      "http://aabbccc.com/"

#include <Object.mqh>
#include <ZiGuiLib\RakutenSym.mqh>


#define ZIGUI_CORRELATION  "ZiGuiIndicators\\Correlation"
#define MaxBars            3

class ZiGuiHedge : public CObject
  {
protected:
   int               idx;
   int               pos;
   double            lots;
   double            times;       // Ex: ZARJPY vs USDJPY
   bool              corrlation;    // true: positive, false: negative
   ZiGuiHedgePair    zgp[2];
   ZiGuiHedgePara    para;
   string            m_string;

public:
                     ZiGuiHedge(string pair1, string pair2);
                    ~ZiGuiHedge(void);
   //--- methods set
   void              setZiGuiHedgePara(const ZiGuiHedgePara &rPara) const { para = rPara};
   //--- method indicators
   void              refreshIndicators(void);
   //--- method trade
   void              trade(void);
   //--- methods access
   string            Str(void)             const { return(m_string);                       };
   uint              Len(void)             const { return(StringLen(m_string));            };
   void              Copy(string &copy) const;
   void              Copy(CString *copy) const;
   //--- methods fill
   bool              Fill(const short character) { return(StringFill(m_string,character)); };
   void              Assign(const string str)    { m_string=str;                           };
   void              Assign(const CString *str)  { m_string=str.Str();                     };
   void              Append(const string str);
   void              Append(const CString *str);
   uint              Insert(const uint pos,const string substring);
   uint              Insert(const uint pos,const CString *substring);
   //--- methods compare
   int               Compare(const string str) const;
   int               Compare(const CString *str) const;
   int               CompareNoCase(const string str) const;
   int               CompareNoCase(const CString *str) const;
   //--- methods prepare
   string            Left(const uint count) const;
   string            Right(const uint count) const;
   string            Mid(const uint pos,const uint count) const;
   //--- methods truncation/deletion
   string            Trim(const string targets);
   string            TrimLeft(const string targets);
   string            TrimRight(const string targets);
   bool              Clear(void)   { return(StringInit(m_string));    };
   //--- methods conversion
   bool              ToUpper(void) { return(StringToUpper(m_string)); };
   bool              ToLower(void) { return(StringToLower(m_string)); };
   void              Reverse(void);
   //--- methods find
   int               Find(const uint start,const string substring) const;
   int               FindRev(const string substring) const;
   uint              Remove(const string substring);
   uint              Replace(const string substring,const string newstring);

protected:
   //--- method signal
   int               entrySignal();
   //--- method others
   int               Compare(const CObject *node,const int mode=0) const;
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
ZiGuiHedge::ZiGuiHedge(string pair1, string pair2)
  {
      zgp[0].sym = pair1;
      zgp[1].sym = pair2;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
ZiGuiHedge::~ZiGuiHedge(void)
  {
  }
//+------------------------------------------------------------------+
//| Copy the string value member to copy                             |
//+------------------------------------------------------------------+
void CString::Copy(string &copy) const
  {
   copy=m_string;
  }
//+------------------------------------------------------------------+
//| Copy the string value member to copy                             |
//+------------------------------------------------------------------+
void CString::Copy(string &copy) const
  {
   copy=m_string;
  }
//+------------------------------------------------------------------+
//| Copy the string value member to copy                             |
//+------------------------------------------------------------------+
void CString::Copy(CString *copy) const
  {
   copy.Assign(m_string);
  }
//+------------------------------------------------------------------+
//| Refresh Indicator for Hedge sigals                               |
//+------------------------------------------------------------------+
void ZiGuiHedge::refreshIndicators(void)
  {
   for (int i = 0; i < MaxBars; i++)
   {
      indicator.rShort[i] = iCustom(NULL, para.RPeriod, ZIGUI_CORRELATION,
         zgp[0].sym, zgp[1].sym, PERIOD_D1, para.RShort, 0, 0);
      indicator.rLong[i]  = iCustom(NULL, para.RPeriod, ZIGUI_CORRELATION,
         zgp[0].sym, zgp[1].sym, PERIOD_D1, para.RLong,  0, 0);

      indicator.buf0[i] = iMomentum(zgp[0].sym, para.TPeriod, para.TIndicatorN, PRICE_CLOSE, 0);
      indicator.buf1[i] = iMomentum(zgp[1].sym, para.TPeriod, para.TIndicatorN, PRICE_CLOSE, 0);
   }
  }
//+------------------------------------------------------------------+
//| Trade based on Hedge sigals                                      |
//+------------------------------------------------------------------+
void ZiGuiHedge::trade(void)
  {
   int sig_entry = entrySignal();
   bool deal = false;

   // Open Signals
   if (sig_entry > 0) {
      int s = 2-sig_entry;
      int b = sig_entry-1;

//      while (!deal) {
         deal = MyOrderSend2(b, zgp[b].sym, OP_BUY, Lots, 0, 0, 0, zgp[b].sym);
//      }

      deal = false;
//      while (!deal) {
        deal =  MyOrderSend2(s, zgp[s].sym, OP_SELL, Lots, 0, 0, 0, zgp[s].sym);
//      }
   }

   // Close Signals
   if (sig_entry < 0) {
//      while (!deal) {
         deal = MyOrderClose(0);
//      }

      deal = false;
//      while (!deal) {
         deal = MyOrderClose(1);
//      }
   }
  }
//+------------------------------------------------------------------+
//| Generate entry signal for buying                                 |
//| Open Signals > 0 or Close Signals < 0                            |
//| -1: Close Pair1 and Pair2                                        |
//|  1: buy Pair1 and sell Pair2                                     |
//|  2: buy Pair2 and sell Pair1                                     |
//+------------------------------------------------------------------+
int ZiGuiHedge::entrySignal(void)
 {
   int ret = 0;

   double delta = MathAbs(indicator.buf0[0] - indicator.buf1[0]);
   static datetime oldTime[] = 0;

   // Send monitor mail during generating new Bar
   if (oldTime[idx] == 0)
      oldTime[idx] = Time[0];
   else if (oldTime[idx] < Time[0]) {
      oldTime[idx] = Time[0];
      SendMail("MT4 Hedge: " + oldTime[idx],
         "delta = " + delta + ", " +
         "Pair1[0] = " + indicator.buf0[0] + ", " +
         "Pair2[0] = " + indicator.buf1[0] + ", " +
         "Correlation[0] = " + indicator.rShort[0]);
   }

   // Up/Dn trends (rShort vs rLong) + Positive/Negative
   if (indicator.rShort[0] > para.RThreshold &&
       delta > para.Entry) {
      if (indicator.buf0[0] > indicator.buf1[0])
         ret = 2;
      else
         ret = 1;

      // corrlation = true; // inverse or mirroring AND RThreshold * (-1)
   }

   // 
   if (delta < para.closThreshold) {
      ret = -1;
   }
   return(ret);
 }
//+------------------------------------------------------------------+
//| Generate entry signal for buying                                 |
//| Open Signals > 0 or Close Signals < 0                            |
//| -1: Close Pair1 and Pair2                                        |
//|  1: buy Pair1 and sell Pair2                                     |
//|  2: buy Pair2 and sell Pair1                                     |
//+------------------------------------------------------------------+
int ZiGuiHedge::entrySignal(void)
 {
 }

struct ZiGuiHedgePara {
   int RShort; // Correlation Short period
   int RLong;  // Correlation Long period
   double RThreshold;   // Correlation threshold (-80, +80)
   double RIndicatorN;  // reserved
   double Entry;        // Ex: Momentum abs(diff) > +80 or < -80 - OPEN
   double TIndicatorN;  // Ex: Trade indicator period - 14
   double TakeProfits;  // StopLoss?
   double Step;         // Trailing Stop step width
   double Exit;         // Ex: Momentum abs(diff) < +30 or > -30 - CLOSE

   // NOT FOR DATA MINING
   double RPeriod;      // default: PERIOD_D1
   double TPeriod;      // defalut: PERIOD_M5
};

struct ZiGuiHedgePair {
    string sym;
    int  pos;       // order ticket
    int  magic_b;   // magic number of buy
    double slOrd;   // stop loss
    double tpOrd;   // take profits
    double pipPoint;    // pips adjustment
    double slippagePips;// slippage
};

struct ZiGuiHedgeIndicator {
   // long/short correlation
   double rShort[MaxBars];
   double rLong[MaxBars];

   // open/close indicators' buffer: momentum etc
   double buf0[MaxBars];
   double buf1[MaxBars];
};

struct ZiGuiHedge {
    int idx;
    int pos;
    double lots;
    bool corrlation;    // true: positive, false: negative
    ZiGuiHedgePair zgp[2];
    double times;       // Ex: ZARJPY vs USDJPY
    ZiGuiHedgePara para;
};

struct ZiGuiPos {
    ZiGuiHedge ziGuiHedge;
};





//+------------------------------------------------------------------+
//|                                                       Object.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#include "StdLibErr.mqh"
//+------------------------------------------------------------------+
//| Class CObject.                                                   |
//| Purpose: Base class for storing elements.                        |
//+------------------------------------------------------------------+
class CObject
  {
private:
   CObject          *m_prev;               // previous item of list
   CObject          *m_next;               // next item of list

public:
                     CObject(void): m_prev(NULL),m_next(NULL)            {                 }
                    ~CObject(void)                                       {                 }
   //--- methods to access protected data
   CObject          *Prev(void)                                    const { return(m_prev); }
   void              Prev(CObject *node)                                 { m_prev=node;    }
   CObject          *Next(void)                                    const { return(m_next); }
   void              Next(CObject *node)                                 { m_next=node;    }
   //--- methods for working with files
   virtual bool      Save(const int file_handle)                         { return(true);   }
   virtual bool      Load(const int file_handle)                         { return(true);   }
   //--- method of identifying the object
   virtual int       Type(void)                                    const { return(0);      }
   //--- method of comparing the objects
   virtual int       Compare(const CObject *node,const int mode=0) const { return(0);      }
  };
//+------------------------------------------------------------------+
