#!/usr/bin/ruby
# encoding: utf-8

require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'skyscraper.db'
)

class Price < ActiveRecord::Base
  def to_s
    format "%s € | %s->%s %s->%s (%s) | %s->%s %s->%s (%s) | %s",
      price,
      origin,
      destination,
      outbound_dep_time.strftime('%R'),
      outbound_arr_time.strftime('%R'),
      outbound_stops,
      destination,
      origin,
      return_dep_time.strftime('%R'),
      return_arr_time.strftime('%R'),
      return_stops,
      airline
  end
end
