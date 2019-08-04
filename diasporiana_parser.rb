#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'byebug'
require 'date'
require 'cli/ui'
require 'mongo'

require './lib/book'
require './lib/page'

REQUIRED_CATEGORIES = %w{ ukrainica mistetstvo folklor miscellaneous }

main_page_uri = 'http://diasporiana.org.ua/page/'

CLI::UI::StdoutRouter.enable

Mongo::Logger.logger.level = ::Logger::FATAL
db_client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'diasporiana')

books = []
have_next_page = true
page_numb = 1
while have_next_page do
  CLI::UI::Spinner.spin("Wait for page #{page_numb} downloading") do
    sleep 0.5
    page_books, have_next_page = Page.new("#{main_page_uri}#{page_numb}", REQUIRED_CATEGORIES, Date.today.prev_month.prev_month, db_client).books
    
    books += page_books
    page_numb += 1
  end
end

p 'Books:'
books.each do |book|
  CLI::UI::Frame.open("#{book.category_class}", color: :magenta ) do
    puts CLI::UI.fmt "{{green:#{book.title}}}"
    p "Date: #{book.original_date}, Author : #{book.author}"
    p "Publisher: #{book.publisher}, Pages : #{book.pages}"
    p "Desc: #{book.description}"
    puts CLI::UI.fmt "{{blue:#{book.uri}}}"
  end
end

def save_books(books, db_client)
  books.each { |book| book.mark_as_read(db_client)}
end

if books.count > 0
  answer = CLI::UI.ask('r - mark as read, x - exit?', default: 'x')
  save_books(books, db_client) if answer == 'r'
end

db_client.close
