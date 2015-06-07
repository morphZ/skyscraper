#!/usr/bin/ruby
# encoding: utf-8

# Scrape the flight search web site Kayak for specific flights, save them to a sqlite db and mail the results to a specific mail adress

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'erb'

require_relative 'origin'

$SUMMARY_TEMPLATE_FILE ='summary.html.erb'

class Skyscraper 
  def initialize(origins)
    @origins = Hash.new
    origins.each do |o|
      @origins[o] = Origin.new o
    end
  end

  def html_summary
    ERB.new(File.read($SUMMARY_TEMPLATE_FILE), nil, '>').result(binding)
  end

  def text_summary
    sum = String.new 
    @origins.values.each do |o|
      sum << "Ergebnisse für #{o.origin}\n"
      sum << "URL: #{o.url}\n"
      sum << o.last_results.join("\n") << "\n\n" 
    end
    sum
  end

  def mail_summary(email)
    sum = html_summary
    sum_text = text_summary

    mail = Mail.deliver do
      delivery_method :sendmail

      to      "#{email}" 
      from    'Fluguebersicht <123morph@gmail.com>'
      subject "Flugsuche vom #{Time.now.strftime('%d.%m.%Y um %H:%M Uhr')}"

      text_part do
        content_type 'text/plain; charset=UTF-8'
        body sum_text 
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body sum
      end
    end
  end
end

s = Skyscraper.new [:DUS, :CGN, :FRA]
s.mail_summary 'franz.kirchhoff@googlemail.com'
# s.mail_summary 'u.b.lelgemann@googlemail.com'
