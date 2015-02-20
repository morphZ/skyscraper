#!/usr/bin/ruby
# encoding: utf-8

# Scrape the flight search web site Kayak for specific flights, save them to a sqlite db and mail the results to a specific mail adress

require 'json'
require 'sqlite3'
require 'pry'
require 'mail'
require 'erb'

require_relative 'price.rb'

$FLIGHT_DATA_FILE = 'flights.json.tmp'
$SUMMARY_TEMPLATE_FILE ='summary.erb.html'

class Skyscraper 
  def initialize(origins)
    @origins = origins
    @summary = Hash.new
    @last_scraped = Price.maximum(:scraped_at)

    create_summary
    scrape_origins
  end

  def scrape_origins
    if @last_scraped.nil? || Time.now - @last_scraped > 18 * 60 * 60
      t = Time.now
      @origins.each {|o| scrape o, t }
      @last_scraped = t
    else
      puts "Retrieving last scraping results from database."
    end
  end

  def get_html_summary
    ERB.new(File.read($SUMMARY_TEMPLATE_FILE), nil, '>').result(binding)
  end

  def mail_summary(email)
    sum = get_html_summary
    puts sum
    return

    mail = Mail.deliver do
      delivery_method :sendmail

      to      "#{email}" 
      from    'Fluguebersicht <123morph@gmail.com>'
      subject "Suche vom #{@last_scrape}"

      text_part do
        body 'This is plain text'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body sum 
      end
    end
  end

  private

  def scrape(origin, time)
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
      f[:scraped_at] = time
      f[:scraped_url] = url
      f[:outbound_date] = url.split('/')[5]
      f[:return_date] = url.split('/')[6]
      f[:price] = f[:price].to_i.to_s

      # add flight to db
      Price.create f
    end

    @summary[origin][:this] = Price.where(origin: origin).minimum(:price)

    unless @summary[origin][:alltime].nil?
      if @summary[origin][:this] < @summary[origin][:alltime]
        @summary[origin][:tips].push "Neuer Tiefpreis fuer Flughafen #{origin}!"
      end
    end

    puts "Done."
  end

  def create_summary
    # calculates historic price minima
    @origins.each do |o|
      @summary[o] = Hash.new
      @summary[o][:last] = Price.where(origin: o, scraped_at: @last_scraped).minimum(:price)
      @summary[o][:oneweek] = Price.where(origin: o, scraped_at: 1.week.ago..Time.now).minimum(:price)
      @summary[o][:alltime] = Price.where(origin: o).minimum(:price)
      @summary[o][:tips] = Array.new
    end
  end

  def create_last_flights
    # generates an array of strings, 1 string for every round trip ticket

    flights=Hash.new

    @origins.each do |o|
      flights[o]=Array.new

      Price.where(origin: o, scraped_at: @last_scraped).find_each do |p|
        flights[o].push p.to_s
      end
    end

    flights
  end
end

s = Skyscraper.new [:DUS, :CGN, :FRA]
binding.pry
# s.scrape_origins

