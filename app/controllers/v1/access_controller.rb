module V1
	class AccessController < ApplicationController

		def index
			access_key = ApiKey.last
			response = Hash.new {}
			response['access_token'] = access_key.access_token
			response['created_at'] = access_key.created_at.strftime('%F %T')
			response['expiration'] = access_key.expiration.strftime('%F %T')
			render json: response
		end

		def create
			expiration =  Time.now + 5.minutes			
			ApiKey.create({"expiration" => expiration})
			index()
		end
	end
end