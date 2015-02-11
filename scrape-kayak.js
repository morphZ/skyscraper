var system = require('system');
var args = system.args;
var url = args.length > 1 ? args[1]:"http://www.kayak.de/flights/DUS-FUE/2015-07-20/2015-08-01/NONSTOP";


var page = require('webpage').create();
page.settings.userAgent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36';

page.open(url, function(status) {
  if (status != "success") {
    console.log("Error loading page");
    phantom.exit();
  }
  else {
    page.includeJs("http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js", function() {
      var strResultsPJS = page.evaluate(function() {
        var objRes = [];
        $( ".resultrow.flightresult" ).slice(0, 4).each( function(index,element){
          var item = {};
          item["origin"] = $.trim($( element ).find(".singleleg0").find(".airport").eq(0).text());
          item["destination"] = $.trim($( element ).find(".singleleg0").find(".airport").eq(1).text());
          item["price"] = $( element ).find(".results_price").text().replace(" ", "");
          item["airline"] = $.trim($( element ).find(".airlineName").text()).replace(/\r?\n|\r/g, "");
          item["outbound_dep_time"] = $.trim($( element ).find(".singleleg0").find(".flightTimeDeparture").text());
          item["outbound_arr_time"] = $.trim($( element ).find(".singleleg0").find(".flightTimeArrival").text());
          item["outbound_stops"] = $.trim($( element ).find(".singleleg0").find(".stopsLayovers").text());
          item["return_dep_time"] = $.trim($( element ).find(".singleleg1").find(".flightTimeDeparture").text());
          item["return_arr_time"] = $.trim($( element ).find(".singleleg1").find(".flightTimeArrival").text());
          item["return_stops"] = $.trim($( element ).find(".singleleg1").find(".stopsLayovers").text());
          objRes.push(item);
        });

        return objRes;
      });

      console.log(JSON.stringify(strResultsPJS));
      phantom.exit();
    });
  }
});
