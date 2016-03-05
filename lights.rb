require 'numbers_in_words'
require 'numbers_in_words/duck_punch'
require './hue_switch'
require 'chronic_duration'


LEVELS = {} ; [*1..10].each { |t| LEVELS[t.to_s ] = t.in_words }

module Sinatra
  module Lights
    def self.registered(app)

      app.post '/lights' do
        content_type :json

        # halt 400, "Invalid Application ID" unless @application_id == "your application id here"

        response = AlexaObjects::Response.new
        begin
          switch ||= Hue::Switch.new
        rescue RuntimeError
          response.end_session = true
          response.spoken_response = "Hello. Before using Hue lighting, you'll need to give me access to your Hue bridge." +
                              " Please press the link button on your bridge and launch the skill again within ten seconds."
          halt response.without_card.to_json
        end

        if @echo_request.launch_request?
          response.spoken_response = "I'm ready to control the lights"
          response.end_session = false
          response.without_card.to_json
          halt response.without_card.to_json
        elsif @echo_request.intent_name == "AMAZON.StopIntent"
          response.spoken_response = "Goodbye"
          response.end_session = false
          response.without_card.to_json
          halt response.without_card.to_json
        elsif @echo_request.intent_name == "AMAZON.CancelIntent"
          response.spoken_response = "Cancelling. I'm ready to control the lights."
          response.end_session = false
          response.without_card.to_json  
          halt response.without_card.to_json
        elsif @echo_request.intent_name == "ListScenes"
          response.end_session = true
          response.spoken_response = "I've sent a card to the Alexa app with the list of scenes I found on the bridge"
          response.card_title = "Scenes"
          response.card_content = "#{switch.pretty_scenes}"
          halt response.with_card.to_json
        elsif @echo_request.intent_name == "ListLights"
          response.end_session = true
          response.spoken_response = "I've sent a card to the Alexa app with the list of lights I found on the bridge"
          response.card_title = "Lights"
          response.card_content = "#{switch.pretty_lights}"
          halt response.with_card.to_json
        elsif @echo_request.intent_name == "ListGroups"
          response.end_session = true
          response.spoken_response = "I've sent a card to the Alexa app with the list of groups I found on the bridge"
          response.card_title = "Lights"
          response.card_content = "#{switch.pretty_groups}"
          halt response.with_card.to_json
        
        # Behaviors for controlling the lights
        elsif @echo_request.intent_name == "ControlLights"

          if @echo_request.slots.brightness
            if @echo_request.slots.relativetime.nil? && @echo_request.slots.absolutetime.nil?
    				  LEVELS.keys.reverse_each { |level| @echo_request.slots.brightness.sub!(level, LEVELS[level]) } 
    				end
          end

  				if @echo_request.slots.saturation
            if @echo_request.slots.relativetime.nil? && @echo_request.slots.absolutetime.nil?
              LEVELS.keys.reverse_each { |level| @echo_request.slots.saturation.sub!(level, LEVELS[level]) }
            end
          end
 
  				# Check that a light, group, or scene was specified
          if @echo_request.slots.lights.nil? && @echo_request.slots.scene.nil? && @echo_request.slots.savescene.nil?
  					response.end_session = false
  					response.spoken_response = "Please specify which light or lights you'd like to adjust. I'm ready to control the lights."
  					halt response.without_card.to_json
  				end


          if @echo_request.slots.lights
  				  if @echo_request.slots.lights.scan(/light|lights/).empty?
              response.end_session = false
              response.spoken_response = "Please specify which light or lights you'd like to adjust. I'm ready to control the lights."
              halt response.without_card.to_json
  				  end
          end

  				# Check that a name for and existing light or group was specified
          if @echo_request.slots.lights
            if @echo_request.slots.lights.include?('lights')
              if !(switch.groups.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.downcase.sub(' lights','')}"))
                response.spoken_response = "I couldn't find a group with the name #{@echo_request.slots.lights.delete('lights')}"
                response.end_session = false
                halt response.without_card.to_json
              end
            elsif  @echo_request.slots.lights.include?('light')
              if  !(switch.lights.keys.join(', ').downcase.include?("#{@echo_request.slots.lights.downcase.sub(' light','')}"))
                response.spoken_response = "I couldn't find a light with the name #{@echo_request.slots.lights.delete('lights')}"
                response.end_session = false
                halt response.without_card.to_json
              end
            end
          end

      
        # Logic for light adjustments

          if @echo_request.slots.lights
            
            light_name = @echo_request.slots.lights
            
            if light_name.partition("light").last.empty?
              switch.light light_name.sub(" light", "").strip
            else
              switch.group light_name.sub(" lights", "").strip
            end
            
            p switch._group

            if @echo_request.slots.color
              switch.color @echo_request.slots.color
            end
            
            if @echo_request.slots.brightness
              brightness = @echo_request.slots.brightness.in_numbers
              converted = ((brightness.to_f/10.to_f)*255).to_i
              switch.brightness converted
            end

            if @echo_request.slots.saturation
              saturation = @echo_request.slots.saturation.in_numbers
              converted = ((saturation.to_f/10.to_f)*255).to_i
              switch.saturation converted
            end

            if @echo_request.slots.state
              if @echo_request.slots.absolutetime.nil? && @echo_request.slots.relativetime.nil?
                switch.on if @echo_request.slots.state == "on"
                switch.off if @echo_request.slots.state == "off"
                response.end_session = true
                response.spoken_response = "okay"
                halt response.without_card.to_json
              end
            end

            if @echo_request.slots.alert
              type = @echo_request.slots.alert
              if type == "color loop"
                @echo_request.slots.event == "stop" ? switch.colorloop(:stop) : switch.colorloop(:start) 
              else
                switch.alert :long if type == "long alert"
                switch.alert :short if type == "short alert"
              end

              if @echo_request.slots.absolutetime.nil? && @echo_request.slots.relativetime.nil?
                switch.on
                response.end_session = true
                response.spoken_response = "okay"
                halt response.without_card.to_json
              end
            end
          end

          p switch.body
          p switch._group

          if @echo_request.slots.savescene
            scene_name = @echo_request.slots.savescene
            switch.save_scene scene_name
            response.spoken_response = "Scene saved as #{scene_name}"
            halt response. without_card.to_json
          
          elsif @echo_request.slots.scene
            scene_name = @echo_request.slots.scene
            if @echo_request.slots.absolutetime.nil? && @echo_request.slots.relativetime.nil?
              if switch.scenes.keys.include?(scene_name)
                switch.scene scene_name
                switch.on
                response.end_session = true
                response.spoken_response = "Setting #{scene_name} scene"
                halt response. without_card.to_json
              else
                response.end_session = false
                response.spoken_response = "I couldn't find a scene named #{scene_name}. I've sent a card to the Alexa app with the available scenes." +
                                            " I'm ready to control the lights."
                response.card_title = "Scenes"
                response.card_content = "#{switch.pretty_scenes}"
                halt response. with_card.to_json
              end
            end
          end
            
          if @echo_request.slots.absolutetime || @echo_request.slots.relativetime
            if @echo_request.slots.absolutetime
              time = Time.parse(@echo_request.slots.absolutetime).to_s.sub(' ', 'T').rpartition(' ').first
            elsif @echo_request.slots.relativetime
              adder = ChronicDuration.parse(@echo_request.slots.relativetime)
              time = Time.now + adder
            end

            if @echo_request.slots.state
              switch.body[:on] = true if @echo_request.slots.state == "on"
              switch.body[:on] = false if @echo_request.slots.state == "off"
            end
            
            p switch.body
            
            spoken = switch.schedule(time.to_s)

            response.end_session = true
            response.spoken_response = spoken
            halt response.without_card.to_json
          end

          switch.on
          response.end_session = true
          response.spoken_response = "okay"
          halt response.without_card.to_json

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
