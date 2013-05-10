
require 'dropbox-api'
require 'sinatra'
enable :sessions

configure do
  # setting one option
	if development?
		set :server, 'webrick'
	end
end

Dropbox::API::Config.app_key    = "4rvehrxctb1l17w"
Dropbox::API::Config.app_secret = "73i31ar64jj8h06"
Dropbox::API::Config.mode       = "dropbox"


		# Here the user goes to Dropbox, authorizes the app and is redirected

		
get '/' do
	@@consumer = Dropbox::API::OAuth.consumer(:authorize)
	request_token = @@consumer.get_request_token
	# Store the token and secret so after redirecting we have the same request token
	session[:token] = request_token.token
	logger.info session[:token]
	session[:token_secret] = request_token.secret
	logger.info session[:token_secret]
	request_token.authorize_url(:oauth_callback => 'http://localhost:4567/1')
	logger.info request_token.authorize_url
	redirect to request_token.authorize_url
end

get '/1' do
	consumer=@@consumer
		hash = { oauth_token: session[:token], oauth_token_secret: session[:token_secret]}
		logger.info hash
		logger.info session[:token]
		logger.info session[:token_secret]
		request_token  = OAuth::RequestToken.from_hash(consumer, hash)
		logger.info request_token
		result = request_token.get_access_token(:oauth_verifier => session[:token])
		logger.info result.token
		logger.info result.secret
		@client = Dropbox::API::Client.new :token => result.token, :secret => result.secret
end
