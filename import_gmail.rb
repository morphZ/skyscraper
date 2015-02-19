#!/usr/bin/ruby
# encoding: utf-8

require 'mail'
require 'pry'

require_relative 'price'

Mail.defaults do
  retriever_method :imap, {
    :address             => "imap.gmail.com",
    :port                => 993,
    :user_name           => '123morph@gmail.com',
    :password            => 'Siedler_27',
    :enable_ssl          => true,
    :mailbox             => '[Gmail]/Export'
  }
end

Mail.find(mailbox: 'Export', count: 100) do |m|
  body_utf8 = m.body.to_s.encode 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''}
  b = body_utf8.gsub(/\P{ASCII}/, '').split("\n")
  url = nil
  created = nil

  b.each do |l|
    puts "> " << l

    if l =~ /URL\:/
      url = l[5..-1]
      puts "url: " + url
    elsif l =~ /Ergebnisse/
      created = Time.strptime l[("Ergebnisse vom Sun ".length)..-17], "%b %d %Y %T" if created.nil?
      puts "created at: #{created}"
    elsif l[0..2] =~ /\d{3}/
      p = Price.new
      p.scraped_url = url
      p.scraped_at = created
      p.outbound_date = url.split('/')[5]
      p.return_date = url.split('/')[6]

      p.price, l1, l2, p.airline = l.split(' | ')

      p.origin = l1[0..2]
      p.destination = l1[5..7]

      l1s = l1.split(' ')
      p.outbound_dep_time, p.outbound_arr_time = l1s[1].split('->')
      p.outbound_stops = /\(.*\)/.match(l1).to_s[1..-2]

      l1s = l2.split(' ')
      p.return_dep_time, p.return_arr_time = l1s[1].split('->')
      p.return_stops = /\(.*\)/.match(l1).to_s[1..-2]

      p.save
      puts p
    end
  end
end
