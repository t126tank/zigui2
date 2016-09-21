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

function getDateOfWeek(weekNumber, year){
   if (weekNumber < 1) {
      throw createError('Week num is less than 1', 'EINVAL');
   }
   // Create a date object starting january first of chosen year, plus the number of days in a week multiplied by the week number to get the right date.
   return new Date(year, 0,  1 + ((weekNumber - 1) * 7));
};

function tm2WeekNumber(tm) {
   var onejan = new Date(tm.getFullYear(), 0, 1);
   return Math.ceil((((tm - onejan) / 86400000) + onejan.getDay() + 1) / 7);
};

function validTp(tp, period) {
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
   var tpStr = tp.toString();

   tm.setFullYear(parseInt(tpStr.substr(0, 4)));
   if (period != periods.YEARLY) {
      if (period != periods.WEEKLY) {
         var mon = parseInt(tpStr.substr(4, 2)) - 1;
         tm.setMonth(mon);
         if (period != periods.MONTHLY) {
            tm.setDate(parseInt(tpStr.substr(6, 2)));
            if ((period != periods.DAILY)) {
               tm.setHours(parseInt(tpStr.substr(8, 2)));
               if ((period != periods.HOURLY)) {
                  tm.setMinutes(parseInt(tpStr.substr(10, 2)));
                  if ((period != periods.MINUTE)) {
                     tm.setSeconds(parseInt(tpStr.substr(12, 2)));
                  }
               }
            }
         }
      } else { // periods.WEEKLY
         var wk = parseInt(tpStr.substr(4, 3));
         tm = getDateOfWeek(wk, tm.getFullYear());
      }
   }

   return tm;
};

TpTmConverter.tm2Tp = function(tm, p) {
   var tpStr = tm.getFullYear().toString();

   if (p != periods.YEARLY) {
      if (p != periods.WEEKLY) {
         var mon = tm.getMonth() + 1;
         tpStr += timeStr(mon);
         if (p != periods.MONTHLY) {
            tpStr += timeStr(tm.getDate());
            if ((p != periods.DAILY)) {
               tpStr += timeStr(tm.getHours());
               if ((p != periods.HOURLY)) {
                  tpStr += timeStr(tm.getMinutes());
                  if ((p != periods.MINUTE)) {
                     tpStr += timeStr(tm.getSeconds());
                  }
               }
            }
         }
      } else { // periods.WEEKLY
         tpStr += weekStr(tm2WeekNumber(tm));
      }
   }

   return parseInt(tpStr);
};

TpTmConverter.initTpTmMap = function(s, e) {
   var tpStart = 1;
   var tmStart;
   var period = TpTmConverter.judgePeriod(s);


   tmStart = s;
};

TpTmConverter.judgePeriod = function (tp) {
   var period;

   // uint32 -> Max: 2,147,483,648
   // uint64 -> Max: 9,223,372,036,854,775,808
   if (!Number.isInteger(tp)) {
      throw createError('Start time is not integer', 'EINVAL');
   }
   if (tp < 0) {
      throw createError('Start time is minus', 'EINVAL');
   }

   switch (getLength(tp)) {
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

   if (!validTp(tp, period)) {
      throw createError('Start trade point is invalid', 'EINVAL');
   }

   return period;
};

module.exports = TpTmConverter;
