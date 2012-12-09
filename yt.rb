require 'sinatra'
require 'mysql2'
require 'active_record'

@@mysqlclient = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "root",	 :database => "information_schema")

get '/tables/' do
	MyAPI.get_tables()
end

get '/' do
  'Hello world!'
end

post '/' do
end

put '/' do
end

patch '/' do
end

delete '/' do
end

options '/' do
end

#class definitions
class MyAPI < ActiveRecord::Base 
	class << self

		dbconfig = {
			:adapter => "mysql2",
			:host => "localhost",
			:username => "root",
			:password => "root",
			:database => "information_schema" 
		}
		ActiveRecord::Base.establish_connection(dbconfig)
		def get_tables()
			query='select * from tables'; 
			self.connection.select_all(query).to_s
		end
	end 
end