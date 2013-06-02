class LauTwitClient < Sinatra::Application
  
configure do
  
  if ENV['RACK_ENV'] == "production"
    callback = "http://LauTwitClient.heroku.com/connect/auth"   
  else
    callback = "http://localhost:8080/connect/auth"
  end
  
  @@config = {'consumer_key'=>"AFcCvgpKoilQY506lYPGJQ", 'consumer_secret'=>"tRygHzQOlY9RofsVjEwhoDbTHJdULsx1bhBbbL82Jfs",
              'callback_url' => callback}
  set :sessions, true
  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
end

before do  
  @client = TwitterOAuth::Client.new(:consumer_key => @@config['consumer_key'], :consumer_secret => @@config['consumer_secret'], 
                                     :token => session[:access_token], :secret => session[:secret_token])
end

helpers do
  def twitter_text(text)
   text.gsub!(/@(\w+)/) {|m| "<a href=\"/#{m.gsub('@','')}\">#{m}</a>"}  
   text.gsub!(/http:\/\/.+(\/.)*/) {|m| "<a href=\"#{m}\">#{m}</a>"}
   text  
  end
end

get '/' do
  if session[:user]
    @tweets = @client.friends_timeline
  else
    @tweets = @client.public_timeline  
  end
  erb :home
end

post '/update' do
  @client.update(params[:tweet])
  redirect "/"
end

get '/mentions' do  
  @tweets = @client.mentions
  erb :home
end

get '/connect/auth' do  
  puts "/connect/auth"
  begin
    session[:oauth_verifier] = params[:oauth_verifier] if params[:oauth_verifier]
    @access_token = @client.authorize(session[:request_token], session[:request_token_secret],
                    :oauth_verifier => session[:oauth_verifier])
  rescue OAuth::Unauthorized
                  
  end
  
  if @client.authorized?    
    session[:access_token] = @access_token.token
    session[:secret_token] = @access_token.secret
    session[:user] = true
  end 
  redirect '/'
end

get '/connect' do    
  request_token = @client.request_token(:oauth_callback => @@config['callback_url'])
  session[:request_token] = request_token.token  
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url.gsub('authorize', 'authenticate') 
end

get '/logout' do
  session[:user] = nil
  session[:request_token] = nil
  session[:request_token_secret] = nil
  session[:access_token] = nil
  session[:secret_token] = nil
  redirect '/'
end


get '/:username' do
  @tweets = @client.user_timeline({ :screen_name => params[:username] })
  erb :home
end

end