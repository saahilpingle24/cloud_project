class PagesController < ApplicationController	
	def index
		error_message = {:error => "true",:response => "root directory access is not permitted"}
		render json: error_message
	end
end