module V1
	class AliasController < ApplicationController
		protect_from_forgery with: :null_session
		before_filter :restrict_access

		def index
			begin
				if params[:name].present? && params[:alias].present?
					@name = params[:name].split(',')[0]	
					@alias_names = params[:alias].split(',')	
					if params[:threshold].present?
						@threshold = params[:threshold].to_f
					else
						@threshold = 0.0
					end
					return_result = begin_processing()
					render json: return_result
				else
					error_message = {:error => "true", :response => "missing input parameters and/or malformed input"}
					render json: error_message
				end			
			rescue Exception => ex
				error_message = {:error => "true", :response => ex.message}
				render json: error_message
			end
		end

		def create
			begin				
				data = ActiveSupport::JSON.decode(request.body.read)			    		    				
				@name = data['name']	
				@alias_names = data['alias']
				@threshold = data['threshold'].to_f
				if !@threshold
					@threshold = 0.0    			
				end
				return_result = begin_processing()
				render json: return_result
			rescue
				error_message = {:error => "true", :response => "missing input parameters and/or malformed input"}
				render json: error_message
			end
		end	

		def begin_processing
			@inter_result =[]
			@final_result = Hash.new {}	
			result_set = get_score()
			if result_set.present?					
				@final_result["error"] = "true"
    			@final_result["response"] = result_set					
			else					
				@final_result["error"] = "false"
				@final_result["response"] = {}
				@final_result["response"]["name"] = @name
				@final_result["response"]["comparisons"] = {}
				for tuple in @alias_names.zip(@inter_result)
					if tuple[1] >= @threshold
						@final_result["response"]["comparisons"][tuple[0]] = tuple[1]
					end
				end
			end
			return @final_result
		end

		private

		def restrict_access
			error_message = Hash.new {}
			error_message["error"] = "true"
			case request.method_symbol
			when :get
				if params[:access_token].present?
					api_key = ApiKey.find_by_access_token(params[:access_token])
					if api_key
						error_message["response"] = "unauthorized access. access time exceeded."
						render json: error_message, status: :unauthorized unless api_key.expiration >= Time.now
					else
						error_message["response"] = "unauthorized access. missing/malformed api access key."
						render json: error_message, status: :unauthorized
					end
				else
					error_message["response"] = "unauthorized access. missing/malformed api access key."
					render json: error_message, status: :unauthorized
				end				
			when :post
				error_message["response"] = "unauthorized access. missing/malformed api access key."
				authenticate_or_request_with_http_token do |token, options|
					ApiKey.exists?(access_token: token)
				end
			end
		end

		def get_prefix_length(string_1,string_2,min_prefix_length=4)
			n = [string_1.length,string_2.length,min_prefix_length].min
			for i in 0..n
				if string_1[i] != string_2[i]
					return i
				end
			end
			return n
		end

		def get_common(string_1,string_2,distance)
			commons = Array.new(string_2.length) { |i|  }
			match_counter = 0

			for i in 0..string_1.length
				no_match = true
				for j in 0..string_2.length
					if no_match
						if string_2[j] == string_1[i] && (j-i).abs <= distance
							no_match = false
							match_counter += 1
							commons[i] = string_1[i]
						end
					end
				end
			end
			return commons.compact
		end
		
		def get_jaro(string_1,string_2)
			string_1.strip!
			string_2.strip!

			if string_1 == string_2
				return 1.0
			end

			if string_1.length > string_2.length
				tmp = string_2
				string_2 = string_1
				string_1 = tmp
			end

			distance = (string_2.length/2).floor-1.to_i			
		
			common_characters1 = get_common(string_1,string_2,distance)
			common_characters2 = get_common(string_2,string_1,distance)

			if common_characters1.length == 0  || common_characters2.length == 0
				return 0
			end

			transpositions = 0

			upper_bound = [common_characters1.length,common_characters2.length].min

			for i in 0..upper_bound
				if common_characters1[i] != common_characters2[i]
					transpositions += 1
				end
			end

			transpositions = transpositions/2

			return_value = ((upper_bound.to_f/string_1.length) + (upper_bound.to_f/string_2.length) + ((upper_bound-transpositions).to_f/common_characters1.length))/3

			return return_value		
	  	end

		def get_score(prefix_scale=0.1)
			begin
				counter = 0
				string_1 = @name.downcase					
				@alias_names.each do |alias_name|
					string_2 = alias_name.downcase
					jaro_distance = get_jaro(string_1,string_2)				
					prefix_length = get_prefix_length(string_1,string_2)				
					final_score = (jaro_distance + (prefix_length * prefix_scale * (1.0 - jaro_distance))).round(2)				
					@inter_result.push(final_score)				
				end		
				return
			rescue Exception => ex
				return ex.message
			end
		end	
	end
end