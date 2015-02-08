var system = require('system');
var args = system.args;
var url = args.length > 1 ? args[1]:"http://www.kayak.de/flights/DUS-FUE/2015-07-20/2015-08-01";


var page = require('webpage').create();
page.settings.userAgent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36';
var strResults = [];
var fs = require('fs');

page.onConsoleMessage = function (msg, line, source) {
    //console.log('console> ' + msg);
};

page.open(url, function(status) {
    if (status != "success") {
        console.log("Error loading page");
        phantom.exit();
    }
    else
    {
//        console.log("Page loaded");

        page.includeJs("http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js", function() {
            page.evaluate(function() {
                $( "#fs_stops_1_input" ).click();
                $( "#fs_stops_2_input" ).click();
            });

//            console.log("Waiting 10 secs");
            setTimeout(function() {
//                console.log("Grabbing Flight data");
                var strResultsPJS = page.evaluate(function() {
                    var strResults = [];
                    var objRes = [];
                    $( ".resultrow.flightresult" ).slice(0, 4).each( function(index,element) {
                        strResults.push(
                            $( element ).find(".results_price").text().replace(" ", "") +
                            " | " +
                            $.trim($( element ).find(".singleleg0").find(".airport").eq(0).text()) +
                            "->" +
                            $.trim($( element ).find(".singleleg0").find(".airport").eq(1).text()) +
                            " " +
                            $.trim($( element ).find(".singleleg0").find(".flightTimeDeparture").text()) +
                            "->" +
                            $.trim($( element ).find(".singleleg0").find(".flightTimeArrival").text()) +
                            " (" +
                            $.trim($( element ).find(".singleleg0").find(".stopsLayovers").text()) +
                            ") | " +

                            $.trim($( element ).find(".singleleg1").find(".airport").eq(0).text()) +
                            "->" +
                            $.trim($( element ).find(".singleleg1").find(".airport").eq(1).text()) +
                            " " +
                            $.trim($( element ).find(".singleleg1").find(".flightTimeDeparture").text()) +
                            "->" +
                            $.trim($( element ).find(".singleleg1").find(".flightTimeArrival").text()) +
                            " (" +
                            $.trim($( element ).find(".singleleg1").find(".stopsLayovers").text()) +
                            ") | " +
                            $.trim($( element ).find(".airlineName").text()).replace(/\r?\n|\r/g, "")
                        );

                        var item = {};
                        item["orig"] = $.trim($( element ).find(".singleleg0").find(".airport").eq(0).text());
                        item["dest"] = $.trim($( element ).find(".singleleg0").find(".airport").eq(1).text());
                        item["dep_time"] = $.trim($( element ).find(".singleleg0").find(".flightTimeDeparture").text());
                        item["arr_time"] = $.trim($( element ).find(".singleleg0").find(".flightTimeArrival").text());
                        item["stops"] = $.trim($( element ).find(".singleleg0").find(".stopsLayovers").text());

                        var fluege = {};
                        fluege["price"] = $( element ).find(".results_price").text().replace(" ", "");
                        fluege["airline"] = $.trim($( element ).find(".airlineName").text()).replace(/\r?\n|\r/g, "");
                        fluege["to"] = item;

                        item = {};
                        item["orig"] = $.trim($( element ).find(".singleleg1").find(".airport").eq(0).text());
                        item["dest"] = $.trim($( element ).find(".singleleg1").find(".airport").eq(1).text());
                        item["dep_time"] = $.trim($( element ).find(".singleleg1").find(".flightTimeDeparture").text());
                        item["arr_time"] = $.trim($( element ).find(".singleleg1").find(".flightTimeArrival").text());
                        item["stops"] = $.trim($( element ).find(".singleleg1").find(".stopsLayovers").text());
                        fluege["from"] = item;

                        objRes.push(fluege);
                    });

                    //return strResults;
                    return objRes;
                });

                //console.log("Ergebnisse vom " + new Date + ":");
                //console.log("URL: " + url);
                //strResultsPJS.forEach( function(elem) { console.log(elem); } );
                console.log(JSON.stringify(strResultsPJS));

                phantom.exit();

            }, 10000);
        });
    }
});
