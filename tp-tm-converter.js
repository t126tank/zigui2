'use strict';

var createError = require('./create-error');
var periods = require('../core/period-types');

var TpTmConverter = function () {
};


var immutableLen = Object.freeze({
   second : 14,
   minute : 12,
   hour   : 10,
   day    : 8,
   week   : 7,
   month  : 6,
   year   : 4
});

function getLength(number) {
   return number.toString().length;
};

function timeStr(tm) {
   // 2 -> 02
   return getLength(tm) == 2 ? tm.toString(): "0" + tm.toString();
};

function weekStr(wk) {
   // 12 -> 012, 3 -> 003
   return getLength(wk) == 2 ? "0" + wk.toString(): "00" + wk.toString();
};

function validTm(t, p) {
   /**
    * true  - 20160112, 2015033, 201411
    * false - 11112233, 2013069, 201213
    */
   return true;
}

var TpTmConverter = function () {
};

// Specify
TpTmConverter.mapTpTm = function() {
   console.log("mapTpTm");
};

// TradePoint to Date
TpTmConverter.tp2Tm = function(tp) {
   var tm = new Date();
   var period = TpTmConverter.judgePeriod(tp);
   var str = tp.toString();

   tm.setFullYear(parseInt(str.substr(0, 4)));
   if (period != periods.YEARLY) {
      if (period != periods.WEEKLY) {
         var mon = parseInt(str.substr(4, 2)) - 1;
         tm.setMonth(mon);
         if (period != periods.MONTHLY) {
            tm.setDate(parseInt(str.substr(6, 2)));
            if ((period != periods.DAILY)) {
               tm.setHours(parseInt(str.substr(8, 2)));
               if ((period != periods.HOURLY)) {
                  tm.setMinutes(parseInt(str.substr(10, 2)));
                  if ((period != periods.MINUTE)) {
                     tm.setSeconds(parseInt(str.substr(12, 2)));
                  }
               }
            }
         }
      } else { // WEEKLY
      }
   }

   return tm;
};

TpTmConverter.tm2Tp = function(tm, p) {
   var tp = tm.getFullYear().toString();

   if (p != periods.YEARLY) {
      if (p != periods.WEEKLY) {
         var mon = tm.getMonth() + 1;
         tp += timeStr(mon);
         if (p != periods.MONTHLY) {
            tp += timeStr(tm.getDate());
            if ((p != periods.DAILY)) {
               tp += timeStr(tm.getHours());
               if ((p != periods.HOURLY)) {
                  tp += timeStr(tm.getMinutes());
                  if ((p != periods.MINUTE)) {
                     tp += timeStr(tm.getSeconds());
                  }
               }
            }
         }
      } else { // WEEKLY
         tp += weekStr();
      }
   }

   return tp;
};

TpTmConverter.initTpTmMap = function(s, e) {
   var tpStart = 1;
   var tmStart;
   var period = TpTmConverter.judgePeriod(s);


   tmStart = s;
};

TpTmConverter.judgePeriod = function (tm) {
   var period;

   if (!Number.isInteger(tm)) {
      throw createError('Start time is not integer', 'EINVAL');
   }
   if (tm < 0) {
      throw createError('Start time is minus', 'EINVAL');
   }

   switch (getLength(tm)) {
   case immutableLen.second:
      period = periods.SECOND;
      break;
   case immutableLen.minute:
      period = periods.MINUTE;
      break;
   case immutableLen.hour:
      period = periods.HOURLY;
      break;
   case immutableLen.day:
      period = periods.DAILY;
      break;
   case immutableLen.week:
      period = periods.WEEKLY;
      break;
   case immutableLen.month:
      period = periods.MONTHLY;
      break;
   case immutableLen.year:
      period = periods.YEARLY;
      break;
   default:
      throw createError('Period not supported', 'EINVAL');
   }

   if (!validTm(tm, period)) {
      throw createError('Start time is invalid', 'EINVAL');
   }

   return period;
};

module.exports = TpTmConverter;
