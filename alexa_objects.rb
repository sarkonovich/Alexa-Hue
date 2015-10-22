
	module AlexaObjects
		class EchoRequest
			attr_reader :intent_name, :slots, :timestamp, :request_type, :session_new, :user_id, :access_token, :application_id
			attr_accessor :attributes
			alias :session_new? :session_new

			def initialize(response_hash)
				if response_hash["session"]["attributes"]
					@attributes 	= response_hash["session"]["attributes"]
				else
					@attributes 	= {}
				end

				@request_type 		= response_hash["request"]["type"]
				@timestamp 			= response_hash["request"]["timestamp"]
				@session_new 		= response_hash["session"]["new"]
				@user_id 			= response_hash["session"]["user"]["userId"]
				@access_token		= response_hash["session"]["user"]["accessToken"]
				@application_id		= response_hash["session"]["application"]["applicationId"]
				if response_hash["request"]["intent"]
					@intent_name 	=  response_hash["request"]["intent"]["name"]
					@slots 			= build_struct(response_hash["request"]["intent"]["slots"])
				end
			end

			def filled_slots
				@slots.select { |slot| slot != nil}
			end

			def intent_request?
				request_type == "IntentRequest"
			end

			def launch_request?
				request_type == "LaunchRequest"
			end

			def session_ended_request?
				request_type == "SessionEndedRequest"
			end

			private	
			def build_struct(hash)
				if hash.nil?
					nil
				else
					slot_names = hash.keys.map {|k| k.to_sym.downcase }
					slot_values = hash.values.map { |v| v["value"] }
					Struct.new(*slot_names).new(*slot_values)
				end
			end
		end

		class Response
			attr_accessor :session_attributes, :spoken_response, :card_title, :card_content, :reprompt_text, :end_session, :speech_type, :text_type
			def initialize
				@session_attributes = {}
				@speech_type = "PlainText"
				@spoken_response = nil
				@card_title = nil
				@card_content = nil
				@reprompt_text = nil
				@text_type = "text"
				@end_session = true

			end

			def add_attribute(key, value)
				@session_attributes.merge!(key => value)
			end

			def append_attribute(key, value)
				@session_attributes[key] << value if @session_attributes[key] != nil
			end

			def with_card
					{
					  "version": "2.0",
					  "sessionAttributes":
					    @session_attributes, 	
						"response": {
						  "outputSpeech": {
						    "type": speech_type,
						    "#{text_type}": spoken_response
						  },
						  "card": {
						    "type": "Simple",
						    "title": card_title,
						    "content": card_content
						  },
					  "reprompt": {
					    "outputSpeech": {
					      "type": speech_type,
					      "text": reprompt_text
					    }
					  },
					  "shouldEndSession": end_session 
					}
				}
			end

			def link_card
				self.with_card.tap { |hs| hs[:response][:card] = {"type": "LinkAccount"} }
			end

			def without_card
				self.with_card.tap { |hs| hs[:response].delete(:card) }
			end
		end
	end

