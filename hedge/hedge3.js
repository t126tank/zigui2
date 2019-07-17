
requirejs.config({
  paths: {
    ramda: 'https://cdnjs.cloudflare.com/ajax/libs/ramda/0.26.1/ramda.min',
    jquery: 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min',
    moment: 'https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.23.0/moment.min',
    Chart: 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.3/Chart.min'
  }
});

require([
    'ramda',
    'jquery',
    'moment',
    'Chart'
  ],
  function (_, $) {
    var trace = _.curry(function(tag, x) {
      console.log(tag, x);
      return x;
    });

    var Impure = {
      getJSON: _.curry(function(callback, url) {
        $.getJSON(url, callback);
      }),

      setHtml: _.curry(function(sel, html) {
        $(sel).html(html);
      })
    };

    var url = function (ts) {
      return 'http://xxx.yyy.zzz/startupId.php?startupId=aaa:' + ts;
      // security.mixed_content.block_active_content = false in firefox about:config
    };

    var jf = function(ts) {
      return ts + '.json';
    }

    var img = function (val) {
      return $('<label />', { text: val });
    };

    var cnvt = function (ts) {
      var d = new Date(ts * 1000);
      var year  = d.getFullYear();

      var month = d.getMonth() + 1;
      var day   = d.getDate();
      var hour  = ( '0' + d.getHours() ).slice(-2);
      var min   = ( '0' + d.getMinutes() ).slice(-2);
      var sec   = ( '0' + d.getSeconds() ).slice(-2);

      return ( year + '-' + month + '-' + day + ' ' + hour + ':' + min + ':' + sec );
    };

    var hedges = _.compose(_.map(_.compose(img, _.prop('total'))), _.prop('result'));

    var calSell = function (v) {
        // console.log(v['bearPrice'] * v['bearVol']);
        return v['bearPrice'] * v['bearVol'];
    };

    var calBuy = function (v) {
        // console.log(v['bullPrice'] * v['bullVol']);
        return v['bullPrice'] * v['bullVol'];
    };

    var dates = _.compose(cnvt, _.prop('ts'));

    var smiles = _.compose(_.map(_.prop('data')));

    var smile = _.curry(function(i, v, e, t) {
      var isEnd = s => _.prop('end', s) == e;
      return _.prop('smile', _.find(_.propEq('type', t))(_.filter(isEnd, _.prop('data', v))))[i];
    });

    var lbl = smile(0);
    var biv = smile(3);
    var siv = smile(4);

    var renderResults = function (val) {
      setTimeout(function() {
        var kps = dates(val);
        var end = "20190725";
        var type = "call";

        var l1 = lbl(val, end, type);
        var b1 = biv(val, end, type);
        var s1 = siv(val, end, type);

        console.log(kps);

        var lnChartData = {
          labels: l1,
          datasets: [{
            label: '# Selling IV',
            type: 'line',
            data: s1,
            fill: false,
            borderColor: '#EC932F',
            backgroundColor: '#EC932F',
            pointBorderColor: '#EC932F',
            pointBackgroundColor: '#EC932F',
            pointHoverBackgroundColor: '#EC932F',
            pointHoverBorderColor: '#EC932F',
            yAxisID: 'y-axis-1'
          }, {
            label: '# Buying IV',
            type: 'line',
            data: b1,
            fill: false,
            borderColor: '#AC932F',
            backgroundColor: '#AC932F',
            pointBorderColor: '#AC932F',
            pointBackgroundColor: '#AC932F',
            pointHoverBackgroundColor: '#AC932F',
            pointHoverBorderColor: '#AC932F',
            yAxisID: 'y-axis-1'
          }]
        };

        var myChart = new Chart(ctx, {
          type: 'line',
          data: lnChartData,
          options: {
            title : {
              display: true,
              text: end + '-' + type + '(' + kps + ')',
              fontStyle: 'bold',
              fontSize: 18,
              fontFamily: "sans-serif",
              position: 'bottom'
            },
            responsive: true,
            maintainAspectRatio: false,
            tooltips: {
              mode: 'index',
              intersect: false
            },
            elements: {
              line: {
                fill: false
              }
            },
            scales: {
              xAxes: [{
                display: true,
                gridLines: {
                  display: false
                },
                //stacked: true
                //labels: {
                //  show: true
                //}
              }],
              yAxes: [{
                type: 'linear',
                display: true,
                position: 'left',
                id: 'y-axis-1',
                gridLines: {
                  display: false
                },
                labels: {
                  show: true
                },
                ticks: {
                  //min: 9000000,
                  //max: 11000000,
                  //stepSize: 50000,
                  beginAtZero: false
                }
              }]
            }
          }
        });
      }, Math.random() * 200);
    };

    var renderHedges = _.compose(Impure.setHtml("body"), hedges);

    var app = _.compose(Impure.getJSON(renderHedges), url);
    var app2 = _.compose(Impure.getJSON(renderResults), url);
    var app3 = _.compose(Impure.getJSON(renderResults), jf);

    // app goes here
    /*
    $('<canvas>').attr({
        id: 'myChart'
    }).css({
        width: '300px',
        height: '300px'
    });
    */

    // app("1546820763");
    Impure.setHtml('body', '<canvas id="myChart" width="200" height="200"></canvas>');
    var ctx = document.getElementById("myChart").getContext('2d');
    ctx.canvas.height = 500;
    // ctx.canvas.width  = 230;


    // test data
    var ts = String($('#hedge3').data('ts'));
    app3(ts);
  }
);

