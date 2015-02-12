#!/usr/bin/ruby
# Scrape the flight search web site Kayak for specific flights, save them to a sqlite db and mail the results to a specific mail adress

require 'json'
require 'sqlite3'
require 'pry'
require 'active_record'

$FLIGHT_DATA_FILE = 'flights.json.tmp'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'skyscraper.db'
)

class Price < ActiveRecord::Base
end

class Skyscraper 
  def self.scrape(url)
    # start headless browser phantomjs with url
    # output ist written to file $FLIGHT_DATA_FILE
    `./phantomjs scrape-kayak.js "#{url}"`

    # parse flight data from json file
    flights = JSON.parse File.read($FLIGHT_DATA_FILE), :symbolize_names => true

    # delete temp file
    File.delete($FLIGHT_DATA_FILE);

    # customize some data
    flights.each do |f|
      f[:scraped_url] = url
      f[:outbound_date] = url.split('/')[5]
      f[:return_date] = url.split('/')[6]
      f[:price] = f[:price].to_i.to_s
    end

    flights
  end

  def self.save_to_db (flights)
    flights.each do |f|
      p = Price.create f      
    end
  end

  def self.scrape_n_save (url)
    f = self.scrape url
    self.save_to_db f
  end
end

origins = [
  "DUS",
  "CGN",
  "FRA"
]

puts "Start scraping ..."
origins.each do |o|
  url = "http://www.kayak.de/flights/#{o}-FUE/2015-07-20/2015-08-01/NONSTOP"
  print "Scraping #{url}... "
  Skyscraper.scrape_n_save url
  puts "Done."
end
