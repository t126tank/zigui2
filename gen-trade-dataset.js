'use strict';

var periods = require('../core/period-types');
var ttc = require('./tp-tm-converter');

var Q    = require('q');
var fs   = require('fs');
var _    = require('lodash');

var brandInfo = [
   {code: "aaa", name: "AAA"}, {code: "bbb", name: "BBB"},
   {code: "ccc", name: "CCC"}, {code: "ddd", name: "DDD"},
   {code: "eee", name: "EEE"}, {code: "fff", name: "FFF"},
   {code: "ggg", name: "GGG"}, {code: "hhh", name: "HHH"},
   {code: "iii", name: "III"}, {code: "jjj", name: "JJJ"},
   {code: "kkk", name: "KKK"}, {code: "lll", name: "LLL"},
   {code: "mmm", name: "MMM"}, {code: "nnn", name: "NNN"},
   {code: "ooo", name: "OOO"}, {code: "ppp", name: "PPP"},
   {code: "qqq", name: "QQQ"}, {code: "rrr", name: "RRR"},
   {code: "sss", name: "SSS"}, {code: "ttt", name: "TTT"},
   {code: "uuu", name: "UUU"}, {code: "vvv", name: "VVV"},
   {code: "www", name: "WWW"}, {code: "xxx", name: "XXX"},
   {code: "yyy", name: "YYY"}, {code: "zzz", name: "ZZZ"}
];

// start, range could be accepted from cmd line arguments
var periodTypes = [
   {start: 20160101, range: 300},   // DAILY
   {start: 2016,  range: 50}        // WEEKLY
];

function random(low, high) {
   var raw = Math.random() * (high - low) + low;

   return raw.toFixed(6);
}

function genTradeDetail(tp) {
   var low = 100, high = 150;

   var v = Math.floor(random(low, high) * 10); // stub for overturn
   var c = random(low, high), o = random(low, high),
       tmp = random(low, high), h = random(low, high);
   var l = tmp > h? h: tmp;
   h = tmp > h? tmp: h;

   return {
      tradePoint: tp,
      O: o,
      C: c,
      L: l,
      H: h,
      V: v
   };
}

function calNewTp(s, p, add) {
   var rnt = new Date(s);

   switch (p) {
   case periods.SECOND:
      rnt.setSeconds(s.getSeconds() + add);
      break;
   case periods.MINUTE:
      rnt.setMinutes(s.getMinutes() + add);
      break;
   case periods.HOURLY:
      rnt.setHours(s.getHours() + add);
      break;
   case periods.DAILY:
      rnt.setDate(s.getDate() + add);
      break;
   case periods.WEEKLY:

      break;
   case periods.MONTHLY:
      rnt.setMonth(s.getMonth() + add);
      break;
   case periods.YEARLY:
   default:
      rnt.setFullYear(s.getFullYear() + add);
      break;
   }

   return ttc.tm2Tp(rnt, p);
};

// fileName could be accepted from cmd line arguments
var GenTradeData = function(fileName) {
   var ts = new Date();

   this._fileName = fileName + ts.getMinutes() + ts.getSeconds() + ".json";
};

GenTradeData.prototype.gen = function() {
   var self = this;

   var brandInfoArray = _.map(brandInfo, function(element) {
      var tradeDetailArray = [];

      // Generate each detail
      periodTypes.forEach(function(item) {
         var period = ttc.judgePeriod(item.start);
         var start = ttc.tp2Tm(item.start);

         for (var i = 0; i < item.range; i++) {
            var tradePoint = calNewTp(start, period, i);
            var tradeDetail = genTradeDetail(tradePoint);
            tradeDetailArray.push(tradeDetail);
         }
      });

      // Mapping each brand and set trade detail
      return {
         code: element.code,
         name: element.name,
         tradeUnit: 100,
         tradeDetail: tradeDetailArray
      };
   });

   var data = JSON.stringify(brandInfoArray);

   return Q.nfcall(fs.writeFile, self._fileName, data, 'utf8', null)
      .then(function(data) {
         console.log(self._fileName);
      });
};

var instance = new GenTradeData("../dataset/metaInfoDummy-");

instance.gen();
