require 'rubygems'
require 'sinatra'
require 'data_mapper' # metagem, requires common plugins too.
require 'json'
require 'fileutils'
require 'securerandom'

# need install dm-sqlite-adapter
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/yt.db")


class Account
	include DataMapper::Resource
	property :accountNumber, Serial
	property :userToken, String
	property :email, String
	property :facebook, String
	property :created, DateTime
	property :lastModified, DateTime

	has n, :devices
	has n, :personalMessage
end

class Device
	include DataMapper::Resource
	property :id, Serial
	property :appId, String
	property :deviceToken, String
	property :userAgent, Text
	property :lastSeen, DateTime
	property :lastSeenIP, String
	property :created, DateTime
	property :lastModified, DateTime

	belongs_to :account, :required => false
end

class PersonalMessage
	include DataMapper::Resource
	property :id, Serial
	property :filePath, String
	property :fileName, String

	belongs_to :account
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
Device.auto_upgrade!
Account.auto_upgrade!
PersonalMessage.auto_upgrade!

# ======================
# APPLICATION
#

# ======================
# Device CRUD

get '/device/:appId' do

	device = Device.first(:appId => params[:appId])

	if device == nil
		status 404
		body "Device with appId[#{params[:appId]}] not found. Try registering a device first."
	else 
		status 200
		content_type :json
		{:deviceToken => '#{device.deviceToken}', :lastModified => "#{device.lastModified}"}.to_json
	end

end

post '/device', :provides => :json do

	request.body.rewind
	data = JSON.parse request.body.read

	#would be nice to do some validatio here
	newToken = SecureRandom.hex(16)

		device = Device.create(
		:appId => "#{data['appId']}",
		:deviceToken => "#{newToken}",
		:userAgent => "#{request.user_agent}",
		:lastSeen => Time.now,
		:lastSeenIP => "#{request.ip}",
		:created => Time.now,
		:lastModified => Time.now
	)

	device.save

	status 201
	content_type :json
	{:deviceToken => "#{newToken}", :lastModified => "#{device.lastModified}"}.to_json
end

# ======================
# Account CRUD

get '/account/:accountNumber' do

	account = Account.get(params[:accountNumber])

	if account == nil
		status 404
		body "Account with accountNumber[#{params[:accountNumber]}] not found. Try creating an account first."
	else 
		status 200
		content_type :json
		{:userToken => "#{@account.userToken}", :email => "#{@account.email}", :lastModified => "#{@account.lastModified}"}.to_json
	end

end

get '/admin/account/:accountNumber' do

	@account = Account.get(params[:accountNumber])

	erb :account
end

get '/admin/accounts' do
	@accounts = Account.all

	erb :accounts
end
	

post '/account', :provides => :json do

	request.body.rewind
	data = JSON.parse request.body.read

	#would be nice to do some validation here

	device = Device.first(:deviceToken => "#{data['deviceToken']}")

	if device == nil
		status 400
		body "Attempting to create a user without first registering a device with a valid deviceToken. Try getting a device token first."

	else
		newToken = SecureRandom.hex(8)

		account = Account.create(
			:userToken => "#{newToken}", 
			:email => "#{data['email']}" , 
			:facebook => "#{data['facebook']}",
			:created => Time.now,
			:lastModified => Time.now
			)

		account.save

		#link account to this device
		device.update(:account => account, :lastSeen => Time.now, :lastSeenIP => "#{request.ip}", :lastModified => Time.now)
		device.save

		#return the JSON response
		status 201
		content_type :json
		{:userToken => "#{newToken}", :lastModified => "#{account.lastModified}"}.to_json
	end
end

#upload PMS

post '/account/:accountNumber/images/:id' do
  File.open(params[:id], 'w+') do |file|
    file.write(request.body.read)
  end
end

