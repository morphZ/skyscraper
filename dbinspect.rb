#!/usr/bin/ruby

require 'active_record'
require 'pry'

ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
      database: 'skyscraper.db'
)

class Price < ActiveRecord::Base
end

binding.pry
