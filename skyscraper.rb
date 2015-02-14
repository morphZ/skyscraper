#!/usr/bin/ruby
# Scrape the flight search web site Kayak for specific flights, save them to a sqlite db and mail the results to a specific mail adress

require 'json'
require 'sqlite3'
require 'pry'
require 'active_record'
require 'mail'

$FLIGHT_DATA_FILE = 'flights.json.tmp'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'skyscraper.db'
)

class Price < ActiveRecord::Base
end

class Skyscraper 
  def initialize(origins)
    @origins = origins
    @flights = Hash.new
  end

  def scrape_origins
    @origins.each do |o|
      scrape o
    end
  end

  private

  def scrape(origin)
    url = "http://www.kayak.de/flights/#{origin}-FUE/2015-07-20/2015-08-01/NONSTOP"
    print "Scraping #{url}... "

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

      # add flight to db
      Price.create f
    end

    puts "Done."

    @flights[origin] = flights
    binding.pry
  end

end

class FlightSummary
  def self.mail_summary(email)
    mail = Mail.deliver do
      delivery_method :sendmail

      to      "#{email}" 
      from    'Fluguebersicht <123morph@gmail.com>'
      subject 'First multipart email sent with Mail'

      text_part do
        body 'This is plain text'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is HTML</h1>'
      end
    end
  end

  def self.make_table
    puts "Results of last scraping"
  end
end

s = Skyscraper.new [:DUS, :CGN, :FRA]
s.scrape_origins

# FlightSummary.mail_summary 'franz.kirchhoff@googlemail.com'
