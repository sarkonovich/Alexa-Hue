require 'net/http'
require 'uri'
require 'socket'
require 'ipaddr'
require 'timeout'
require 'chronic'
require 'chronic_duration'
require 'httparty'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'
require 'timeout'

module Hue
  module_function

  def devices(options = {})
    SSDP.new(options).devices
  end

  def first(options = {})
    options = options.merge(:first => true)
    SSDP.new(options).devices
  end

  class Switch
    attr_accessor :command, :lights_array, :_group, :body, :schedule_params, :schedule_ids, :groups, :scenes, :lights
    def initialize( _group = 0)

      @user = "1234567890"
        begin

          HTTParty::Basement.default_options.update(verify: false)
          @ip = HTTParty.get("https://www.meethue.com/api/nupnp").first["internalipaddress"] rescue nil
          if @ip.nil?
            bridge = get_bridge_by_SSDP
            @ip = bridge.ip
          end

        rescue Timeout::Error
          puts "Time Out"
        rescue NoMethodError
          puts "Cannot Find Bridge via Hue broker service, trying SSDP..."
        rescue Errno::ECONNREFUSED
          puts "Connection refused"
        rescue SocketError
          puts "Cannot connect to local network"
        end
      
      authorize_user
      populate_switch
      
      @lights_array = []
      @schedule_ids = []
      @schedule_params = nil
      @_group = "0"
      @body = {}
      @groups = groups
      @scenes = scenes
      @lights = lights
    end

    def hue (numeric_value)
      clear_attributes
      self.body[:hue] = numeric_value
    end

    def mired (numeric_value)
      clear_attributes
      self.body[:ct] = numeric_value
    end

    def color(color_name)
      clear_attributes
      if @colors.keys.include?(color_name.split(' ').last.to_sym)
        self.body[:hue] = @colors[color_name.split(' ').last.to_sym]
        self.body[:sat] = 220
        self.body[:sat] = 255 if color_name.split(' ').first == "dark"
        self.body[:sat] = 195 if color_name.split(' ').first == "light"
      else
        self.body[:ct] = @mired_colors[color_name.to_sym]
      end
    end

    def saturation(depth)
      self.body.delete(:scene)
      self.body[:sat] = depth
    end

    def brightness(depth)
      self.body.delete(:scene)
      self.body[:bri] = depth
    end

    def clear_attributes
      self.body.delete(:scene)
      self.body.delete(:ct)
      self.body.delete(:hue)
    end

    def fade(in_seconds)
      self.body[:transitiontime] = in_seconds * 10
    end 

    def light (*args)
      self.lights_array = []
      self._group = ""
      self.body.delete(:scene)
      args.each { |l| self.lights_array.push @lights[l.to_s] if @lights.keys.include?(l.to_s) }
    end

    def group(group_name)
      self.lights_array = []
      self.body.delete(:scene)
      group = @groups[group_name.to_s]
      self._group = group if !group.nil?
    end

    def scene(scene_name)
      clear_attributes
      self.lights_array = []
      self._group = "0"
      self.body[:scene] = @scenes[scene_name.to_s]
    end

    def confirm
      params = {:alert => 'select'}
      HTTParty.put("http://#{@ip}/api/#{@user}/groups/0/action" , :body => params.to_json)
    end

    def save_scene(scene_name)
      self.fade 2 if self.body[:transitiontime] == nil
      if self._group.empty?
        light_group = HTTParty.get("http://#{@ip}/api/#{@user}/groups/0")["lights"]
      else
        light_group = HTTParty.get("http://#{@ip}/api/#{@user}/groups/#{self._group}")["lights"]
      end
      
      params = {name: scene_name, lights: light_group, transitiontime: self.body[:transitiontime]}
      response = HTTParty.put("http://#{@ip}/api/#{@user}/scenes/#{scene_name.gsub(' ','-')}", :body => params.to_json)
      confirm if response.first.keys[0] == "success"
    end

    def lights_on_off
      self.lights_array.each { |l| HTTParty.put("http://#{@ip}/api/#{@user}/lights/#{l}/state", :body => (self.body).to_json) }
    end

    def group_on_off
      HTTParty.put("http://#{@ip}/api/#{@user}/groups/#{self._group}/action", :body => (self.body.reject { |s| s == :scene }).to_json)
    end

    def scene_on_off
      if self.body[:on] == true
        HTTParty.put("http://#{@ip}/api/#{@user}/groups/#{self._group}/action", :body => (self.body.select { |s| s == :scene }).to_json)
      elsif self.body[:on] == false
        # turn off individual lights in the scene
        (HTTParty.get("http://#{@ip}/api/#{@user}/scenes"))[self.body[:scene]]["lights"].each do |l|
          HTTParty.put("http://#{@ip}/api/#{@user}/lights/#{l}/state", :body => (self.body).to_json)
        end
      end
    end

    def on
      self.body[:on]=true
      lights_on_off if self.lights_array.any?
      group_on_off if (!self._group.empty? && self.body[:scene].nil?)
      scene_on_off if !self.body[:scene].nil?
    end

    def off
      self.body[:on]=false
      lights_on_off if self.lights_array.any?
      group_on_off if (!self._group.empty? && self.body[:scene].nil?)
      scene_on_off if !self.body[:scene].nil? 
    end

    def schedule (string)
      set_time = Time.parse(string).to_s.sub(' ', 'T').rpartition(' ').first
      p set_time
      if Time.parse(string) < Time.now
        "You've set the schedule to a time in the past. Please indicate a.m. or p.m. when specifying a time."
      else
        self.schedule_params = {:name=>"Hue_Switch Alarm",
               :description=>"",
               :localtime=>"#{set_time}",
               :status=>"enabled",
               :autodelete=>true
              }
              p self.schedule_params
        if self.lights_array.any?
          lights_array.each do |l|
            self.schedule_params[:command] = {:address=>"/api/#{@user}/lights/#{l}/state", :method=>"PUT", :body=>self.body}
          end
        else
          self.schedule_params[:command] = {:address=>"/api/#{@user}/groups/#{self._group}/action", :method=>"PUT", :body=>self.body}
        end
        p self.schedule_params
        self.schedule_ids.push(HTTParty.post("http://#{@ip}/api/#{@user}/schedules", :body => (self.schedule_params).to_json))
        
        if self.schedule_ids.flatten.last.include?("success")
          "Schedule set at #{Time.parse(set_time).strftime("%H:%M")}"
        else
          "Scheduling error. Schedule not set"
        end
      end
    end

    def delete_schedules!
      self.schedule_ids.flatten!
      self.schedule_ids.each { |k| 
        id = k["success"]["id"] if k.include?("success")
        HTTParty.delete("http://#{@ip}/api/#{@user}/schedules/#{id}")
      }
      self.schedule_ids = []
    end

    def colorloop(start_or_stop)
      if start_or_stop == :start
        self.body[:effect] = "colorloop"
      elsif start_or_stop == :stop
        self.body[:effect] = "none"
      end
    end

    def alert(value)
      if value == :short
        self.body[:alert] = "select"
      elsif value == :long
        self.body[:alert] = "lselect"
      elsif value == :stop
        self.body[:alert] = "none"
      end
    end

    def reset
      self.command = ""
      self._group = "0"
      self.body = {}
      self.schedule_params = nil
    end

    def authorize_user
      begin
        if HTTParty.get("http://#{@ip}/api/#{@user}/config").include?("whitelist") == false
          body = {:devicetype => "Hue_Switch", :username=>"1234567890"}
          create_user = HTTParty.post("http://#{@ip}/api", :body => body.to_json)
          puts "You need to press the link button on the bridge and run again" if create_user.first.include?("error")
        end
      rescue Errno::ECONNREFUSED
        puts "Cannot Reach Bridge"
      end
    end

    def populate_switch
      @colors = {red: 65280, pink: 56100, purple: 52180, violet: 47188, blue: 46920, turquoise: 31146, green: 25500, yellow: 12750, orange: 8618}
      @mired_colors = {candle: 500, relax: 467, reading: 346, neutral: 300, concentrate: 231, energize: 136}
      @scenes = {} ; HTTParty.get("http://#{@ip}/api/#{@user}/scenes").each { |k,v| @scenes["#{v['name']}".downcase.gsub('-',' ')] = k }
      @groups = {} ; HTTParty.get("http://#{@ip}/api/#{@user}/groups").each { |k,v| @groups["#{v['name']}".downcase] = k } ; @groups["all"] = "0"
      @lights = {} ; HTTParty.get("http://#{@ip}/api/#{@user}/lights").each { |k,v| @lights["#{v['name']}".downcase] = k }
    end

    def pretty_scenes
      string = ""
      self.scenes.keys.each {|k| 
        string << "#{k}\n" }
      string
    end

    def pretty_lights
      string = ""
      self.lights.keys.each {|k| 
        string << "#{k}\n" }
      string
    end

    def pretty_groups
      string = ""
      self.groups.keys.each {|k| 
        string << "#{k}\n" }
      string
    end

    def get_bridge_by_SSDP
      discovered_devices = Hue.devices
      bridge = discovered_devices.each do |device|
          next unless device.get_response.include?("hue Personal") 
      end.first
    end
  end

  
  # The Device and SSDP classes are basically lifted from Sam Soffes' great GitHub repo:
  # https://github.com/soffes/discover. 

  class Device
    attr_reader :ip
    attr_reader :port
    attr_reader :description_url
    attr_reader :server
    attr_reader :service_type
    attr_reader :usn
    attr_reader :url_base
    attr_reader :name
    attr_reader :manufacturer
    attr_reader :manufacturer_url
    attr_reader :model_name
    attr_reader :model_number
    attr_reader :model_description
    attr_reader :model_url
    attr_reader :serial_number
    attr_reader :software_version
    attr_reader :hardware_version

    def initialize(info)
      headers = {}
      info[0].split("\r\n").each do |line|
        matches = line.match(/^([\w\-]+):(?:\s)*(.*)$/)
        next unless matches
        headers[matches[1].upcase] = matches[2]
      end

      @description_url = headers['LOCATION']
      @server = headers['SERVER']
      @service_type = headers['ST']
      @usn = headers['USN']

      info = info[1]
      @port = info[1]
      @ip = info[2]
    end

    def get_response
      Net::HTTP.get_response(URI.parse(description_url)).body
    end
  end
  
  class SSDP
    # SSDP multicast IPv4 address
    MULTICAST_ADDR = '239.255.255.250'.freeze

    # SSDP UDP port
    MULTICAST_PORT = 1900.freeze

    # Listen for all devices
    DEFAULT_SERVICE_TYPE = 'ssdp:all'.freeze

    # Timeout in 2 seconds
    DEFAULT_TIMEOUT = 2.freeze

    attr_reader :service_type
    attr_reader :timeout
    attr_reader :first

    # @param service_type [String] the identifier of the device you're trying to find
    # @param timeout [Fixnum] timeout in seconds
    def initialize(options = {})
      @service_type = options[:service_type]
      @timeout = (options[:timeout] || DEFAULT_TIMEOUT)
      @first = options[:first]
      initialize_socket
    end

    # Look for devices on the network
    def devices
      @socket.send(search_message, 0, MULTICAST_ADDR, MULTICAST_PORT)
      listen_for_responses(first)
    end

  private

    def listen_for_responses(first = false)
      @socket.send(search_message, 0, MULTICAST_ADDR, MULTICAST_PORT)

      devices = []
      Timeout::timeout(timeout) do
        loop do
          device = Device.new(@socket.recvfrom(2048))
          next if service_type && service_type != device.service_type

          if first
            return device
          else
            devices << device
          end
        end
      end
      devices

    rescue Timeout::Error => ex
      devices
    end

    def initialize_socket
      # Create a socket
      @socket = UDPSocket.open

      # We're going to use IP with the multicast TTL. Mystery third parameter is a mystery.
      @socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, 2)
    end

    def search_message
     [
        'M-SEARCH * HTTP/1.1',
        "HOST: #{MULTICAST_ADDR}:reservedSSDPport",
        'MAN: ssdp:discover',
        "MX: #{timeout}",
        "ST: #{service_type || DEFAULT_SERVICE_TYPE}"
      ].join("\n")
    end
  end
end
