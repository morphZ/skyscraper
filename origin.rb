#!/usr/bin/ruby
# encoding: utf-8

require 'json'

require_relative 'price'

$FLIGHT_DATA_FILE = 'flights.json.tmp'

class Origin
  attr_reader :stats, :origin

  def initialize (origin)
    @origin = origin
    @last_scraped_at = Price.where(origin: @origin).maximum(:scraped_at)

    if @last_scraped_at.nil? || Time.now - @last_scraped_at > 18 * 60 * 60
      scrape
      @last_scraped_at = Price.where(origin: @origin).maximum(:scraped_at)
    else
      puts "Retrieving last results for #{@origin} from database."
    end

    calc_stats
  end

  def last_results
    s = Array.new
    Price.where(origin: @origin, scraped_at: @last_scraped_at).each do |o|
      s.push(o.to_s)
    end
  end

  private

  def scrape
    url = "http://www.kayak.de/flights/#{@origin}-FUE/2015-07-20/2015-08-01/NONSTOP"
    print "Scraping #{url}... "

    # start headless browser phantomjs with url
    # output ist written to file $FLIGHT_DATA_FILE
    `./phantomjs scrape-kayak.js "#{url}"`

    # parse flight data from json file
    flights = JSON.parse File.read($FLIGHT_DATA_FILE), :symbolize_names => true

    # delete temp file
    File.delete($FLIGHT_DATA_FILE);

    # customize some data
    time = Time.now
    flights.each do |f|
      f[:scraped_at] = time
      f[:scraped_url] = url
      f[:outbound_date] = url.split('/')[5]
      f[:return_date] = url.split('/')[6]
      f[:price] = f[:price].to_i.to_s
      f[:airline].gsub!(/\P{ASCII}/, '')

      # add flight to db
      Price.create f
    end

    puts 'Done.'
  end

  def calc_stats
    before_last, before_last_price = Price.where(origin: @origin).order(scraped_at: :desc).group(:scraped_at).limit(2).minimum(:price).to_a[1]
 
    @stats = {
      last: Price.where(origin:@origin, scraped_at: @last_scraped_at).minimum(:price),
      before: before_last_price,
      lastweek: Price.where(origin:@origin, scraped_at: (before_last - 1.week)..before_last).minimum(:price),
      alltime: Price.where(origin: @origin).minimum(:price)
    }
  end
end
