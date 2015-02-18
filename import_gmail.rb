#!/usr/bin/ruby -w

require 'mail'
require 'pry'

Mail.defaults do
  retriever_method :imap, {
    :address             => "imap.gmail.com",
    :port                => 993,
    :user_name           => '123morph@gmail.com',
    :password            => 'Siedler#27',
    :enable_ssl          => true,
    :mailbox             => '[Gmail]/Export'
  }
end

Mail.find(mailbox: 'Export', what: :first, count: 1) do |m|
  b = m.body.to_s.split("\n")

  data = nil


  b.each do |l|
    puts "> " << l
    if l =~ /URL\:/
      puts data unless data.nil?

      data=Hash.new
      data[:url] = l[5..-1]
    end
  end
  puts data
end
