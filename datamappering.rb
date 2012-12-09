require 'rubygems'
require 'sinatra'
require 'data_mapper' # metagem, requires common plugins too.
require 'json'
require 'fileutils'
require 'securerandom'

# need install dm-sqlite-adapter
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/yt.db")

class Post
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :body, Text
    property :created_at, DateTime
end

class User
	include DataMapper::Resource
	property :id, Serial
	property :deviceToken, String
	property :userToken, String
	property :email, String
	property :created_at, DateTime
	property :last_modified, DateTime
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
Post.auto_upgrade!
User.auto_upgrade!

get '/user/:userId' do

	@user = User.get([:userId])

	erb :user
end

post '/user', :provides => :json do

	request.body.rewind
	data = JSON.parse request.body.read

	#would be nice to do some validatio here

	newUserToken = SecureRandom.hex(16)
	
	@user = User.create(
		:deviceToken => "#{data['deviceToken']}",
		:userToken => "#{newUserToken}",
		:email => "#{data['email']}", #email isn't needed
		:created_at => Time.now,
		:last_modified => Time.now
	)

	"#{newUserToken}"

	@user.save
end


post '/createPost' do

	request.body.rewind  # in case someone already read it
  	data = JSON.parse request.body.read

	# create makes the resource immediately
	@post = Post.create(
	  :title      => "#{data['title']}",
	  :body       => "#{data['body']}",
	  :created_at => Time.now
	)

	@post.save                           # persist the resource
end


# application

put '/upload/:id' do
  File.open(params[:id], 'w+') do |file|
    file.write(request.body.read)
  end
end


get '/' do
    # get the latest 20 posts
    @posts = Post.all(:order => [ :id.desc ], :limit => 20)
    erb :index
end