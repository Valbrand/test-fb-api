class FbfeedController < ApplicationController
  def index
  end

  def addsubscription
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

  	render 'index'

  	#subscribe to app
  	#submit to redis
  end
end
