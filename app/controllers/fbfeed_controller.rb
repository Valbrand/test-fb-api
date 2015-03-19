class FbfeedController < ApplicationController
  def index
  	@subs = $redis.smembers('subscriptions').sort
  end

  def add_subscription
  	require "rest-client"
  	require "rack/utils"

  	if $redis.get('apptoken').nil?
  		response = RestClient.get('https://graph.facebook.com/oauth/access_token', {
  			:params => {
  				:client_id => Rails.application.secrets.fb_app_id,
  				:client_secret => Rails.application.secrets.fb_app_secret,
  				:grant_type => :client_credentials
  			}
  		})

  		if response.is_a? String
  			parsed_response = Rack::Utils.parse_nested_query(response)

  			if parsed_response.key? "access_token"
  				$redis.set("apptoken", parsed_response["access_token"])
  			else
  				raise "Unable to obtain app access token."
  			end
  		end
  	end

  	if Rails.env.production?
  		callback_url = 'http://test-fb-api.herokuapp.com/subscription'
  	else
  		callback_url = 'http://valbrand.ngrok.com/subscription'
  	end

  	begin
  		response = RestClient.post("https://graph.facebook.com/v2.2/#{params[:appid]}/subscriptions", {
  			:object => :page,
  			:callback_url => callback_url,
  			:fields => 'feed,conversations',
  			:verify_token => 'abcdef',
  			:access_token => $redis.get('apptoken')
  		})
  	rescue Exception => e
  		puts e.response
  		raise e.response.to_s
  	end

  	if $redis.sadd 'subscriptions', params[:appid]
  		redirect_to root_url, notice: "Subscription added successfully!"
  	else
  		redirect_to root_url, alert: "Subscription already exists!"
  	end
  end

  def verify_subscription
  	if params['hub.mode'].eql? "subscribe" and params['hub.verify_token'].eql? "abcdef"
  		render plain: params['hub.challenge']
  	else
  		raise 'Invalid request received'
  	end
  end

  def process_update
  	puts "Update received"
  	puts params
  	render nothing: true
  end
end
