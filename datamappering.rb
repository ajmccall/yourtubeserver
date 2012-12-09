require 'rubygems'
require 'sinatra'
require 'data_mapper' # metagem, requires common plugins too.
require 'json'
require 'fileutils'
require 'securerandom'

# need install dm-sqlite-adapter
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/yt.db")

class User
	include DataMapper::Resource
	property :id, Serial
	property :appId, String
	property :deviceToken, String
	property :userToken, String
	property :email, String
	property :created, DateTime
	property :lastModified, DateTime
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!

#APPLICATION

#-------------------
# Device

get '/device/:deviceToken' do

	user = User.first(:deviceToken => params[:deviceToken])

	if user == nil
		status 404
		body "User record with deviceToken[#{params[:deviceToken]}] not found. Try registering a device first."
	else 
		status 200
		content_type :json
		{:lastModified => "#{user.lastModified}"}.to_json
	end

end

put '/device', :provides => :json do

	request.body.rewind
	data = JSON.parse request.body.read

	#would be nice to do some validatio here
	newToken = SecureRandom.hex(16)

	user = User.create(
		:deviceToken => "#{newToken}",
		:appId => "#{data['appId']}",
		:created => Time.now,
		:lastModified => Time.now
	)

	user.save

	status 201
	content_type :json
	{:deviceToken => "#{newToken}", :lastModified => "#{user.lastModified}"}.to_json
end

#-------------------
# User

get '/user/:userId' do

	@user = User.get(params[:userId])

	if @user == nil
		status 404
		body "User with id[#{params[:userId]}] not found. Try registering a user first."
	else 
		status 200
		content_type :json
		{:userToken => "#{@user.userToken}", :email => "#{@user.email}", :lastModified => "#{@user.lastModified}"}.to_json
	end

end

get '/admin/user/:userId' do

	@user = User.get(params[:userId])

	erb :user
end

get '/admin/users' do
	@users = User.all

	erb :users
end
	

put '/user', :provides => :json do

	request.body.rewind
	data = JSON.parse request.body.read

	#would be nice to do some validation here

	user = User.first(:deviceToken => "#{data['deviceToken']}")

	if user == nil
		status 400
		body "Attempting to register a user without first registering a device for deviceToken[#{data['deviceToken']}]. Try registering a device first."

	else
		newToken = SecureRandom.hex(16)

		user.update(:userToken => "#{newToken}", :email => "#{data['email']}" , :lastModified => Time.now)	

		user.save

		#return the JSON response
		status 201
		content_type :json
		{:userToken => "#{newToken}", :lastModified => "#{user.lastModified}"}.to_json
	end
end

#upload PMS

put '/upload/:id' do
  File.open(params[:id], 'w+') do |file|
    file.write(request.body.read)
  end
end