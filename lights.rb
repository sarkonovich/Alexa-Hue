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

        elsif @echo_request.intent_name == "AMAZON.StopIntent"
          response = AlexaObjects::Response.new
          response.spoken_response = "Goodbye"
          response.end_session = false
          response.without_card.to_json
        elsif @echo_request.intent_name == "AMAZON.CancelIntent"
          response = AlexaObjects::Response.new
          response.spoken_response = "Cancelling. I'm ready to control the lights."
          response.end_session = false
          response.without_card.to_json  
        
        # Behavior for ControlLights intent. Keys and values need to be adjusted a bit to work with HueSwitch #voice syntax.
        elsif @echo_request.intent_name == "ControlLights"
          
          if @echo_request.slots.brightness
  				  LEVELS.keys.reverse_each { |level| @echo_request.slots.brightness.sub!(level, LEVELS[level]) } if @echo_request.slots.schedule.nil? 
  				end

  				if @echo_request.slots.saturation
            LEVELS.keys.reverse_each { |level| @echo_request.slots.saturation.sub!(level, LEVELS[level]) } if @echo_request.slots.schedule.nil?
          end

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
  				@string.strip!
          p @string
 
          begin
            switch = Hue::Switch.new
          rescue RuntimeError
            response = AlexaObjects::Response.new
            response.end_session = true
            response.spoken_response = "Hello. Before using Hue lighting, you'll need to give me access to your Hue bridge." +
                                " Please press the link button on your bridge and launch the skill again within ten seconds."
            halt response.without_card.to_json
          end
          
  				if @echo_request.slots.lights.nil? && @echo_request.slots.scene.nil? && @echo_request.slots.savescene.nil?
  					r = AlexaObjects::Response.new
  					r.end_session = false
  					r.spoken_response = "Please specify which light or lights you'd like to adjust. I'm ready to control the lights."
  					halt r.without_card.to_json
  				end

  				 if @echo_request.slots.lights
  					if @echo_request.slots.lights.scan(/light|lights/).empty?
              r = AlexaObjects::Response.new
              r.end_session = false
              r.spoken_response = "Please specify which light or lights you'd like to adjust. I'm ready to control the lights."
              halt r.without_card.to_json
  				  end
          end

  				if @echo_request.slots.lights
    				if @echo_request.slots.lights.include?('lights')
    					 puts switch.list_groups.keys.join(', ').downcase
    					if !(switch.list_groups.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.sub(' lights','')}"))
                r = AlexaObjects::Response.new
                r.end_session = true
                r.spoken_response = "I couldn't find a group with the name #{@echo_request.slots.lights}"
                halt r.without_card.to_json
              end
            end

  				elsif  @echo_request.slots.lights.include?('light')
  					if  !(switch.list_lights.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.sub(' light','')}"))
              r = AlexaObjects::Response.new
              r.end_session = true
              r.spoken_response = "I couldn't find a light with the name #{@echo_request.slots.lights}"
              halt r.without_card.to_json
            end
          end
  			end
				
        switch.voice @string 

        response = AlexaObjects::Response.new
        response.end_session = true
        response.spoken_response = "okay"
        response.card_content =  "#{@string}...#{@data}"
        response.without_card.to_json # change to .with_card.to_json for debugging info
          
        # Behavior for End Session requests.
        
        elsif @echo_request.session_ended_request?
          response = AlexaObjects::Response.new
          response.end_session = true
          response.spoken_response = "exiting lighting"
          response.without_card.to_json
        end
      end
    end
  end
  register Lights
end
