require 'numbers_in_words'
require 'numbers_in_words/duck_punch'
require './hue_switch'
require 'chronic_duration'
require './fix_schedule_syntax'

LEVELS = {} ; [*1..10].each { |t| LEVELS[t.to_s ] = t.in_words }

module Sinatra
  module Lights
    def self.registered(app)

      app.post '/lights' do
        content_type :json

        # halt 400, "Invalid Application ID" unless @application_id == "your application id here"
        
        # Behavior for Launch Request
        if @echo_request.launch_request?
          response = AlexaObjects::Response.new
          response.spoken_response = "I'm ready to control the lights"
          response.end_session = false
          response.without_card.to_json
        
        # Behavior for ControlLights intent. Keys and values need to be adjusted a bit to work with HueSwitch #voice syntax.
        elsif @echo_request.intent_name == "ControlLights"
         @echo_request.slots.to_h.each do |k,v| 
          @string ||= ""
          next unless v
          if k == :scene || k == :alert
            @string << "#{v.to_s} #{k.to_s}  "
          elsif k == :lights || k == :modifier || k == :state
            @string << "#{v.to_s}  "
          elsif k == :savescene
            @string << "save scene as #{v.to_s} "
          elsif k == :flash
            @string << "start long alert "
          else
            @string << "#{k.to_s} #{v.to_s}  "
          end
        end
        
				fix_schedule_syntax(@string)        

				@string.sub!("color loop", "colorloop")
				LEVELS.keys.reverse_each { |level| @string.sub!(level, LEVELS[level]) } if @string.scan("schedule").empty?
        @string.strip!
 
        begin
          switch = Hue::Switch.new
        rescue RuntimeError
          response = AlexaObjects::Response.new
          response.end_session = true
          response.spoken_response = "Hello. Before using Hue lighting, you'll need to give me access to your Hue bridge." +
                              " Please press the link button on your bridge and launch the skill again within ten seconds."
          halt response.without_card.to_json
        end
        switch.voice @string.gsub('%20', ' ')

        response = AlexaObjects::Response.new
        response.end_session = true
        response.spoken_response = "okay"
        response.card_content =  "#{@string}...#{@data}"
        response.without_card.to_json # change to .with_card.to_json for debugging info
          
        # Behavior for End Session requests.
        elsif @echo_request.intent_name == "EndSession"
          response = AlexaObjects::Response.new
          response.end_session = true
          response.spoken_response = "exiting lighting"
          response.without_card.to_json
        
        elsif @echo_request.session_ended_request?
          response = AlexaObjects::Response.new
          response.end_session = true
          response.without_card.to_json
        end
      end
    end
  end
  register Lights
end
