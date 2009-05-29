require 'optparse'
require 'spork/server'

module Spork
  class Runner
    attr_reader :server
    
    def self.run(args, output, error)
      self.new(args, output, error).run
    end
    
    def initialize(args, output, error)
      raise ArgumentError, "expected array of args" unless args.is_a?(Array)
      @output = output
      @error = error
      @options = {}
      opt = OptionParser.new
      opt.banner = "Usage: spork [test framework name] [options]"
      opt.on("-b", "--bootstrap")  {|ignore| @options[:bootstrap] = true }
      non_option_args = args.select { |arg| ! args[0].match(/^-/) }
      @options[:server_matcher] = non_option_args[0]
      opt.parse!(args)
    end
    
    def find_server
      if options[:server_matcher]
        @server = Spork::Server.defined_servers(options[:server_matcher]).first
        unless @server
          @output.puts <<-ERROR
#{options[:server_matcher].inspect} didn't match a supported test framework.

I support the following test frameworks:
#{Spork::Server.defined_servers.map { |s| ' - ' + s.server_name.downcase } * "\n"}
          ERROR
          return
        end
        
        unless @server.available?
          @output.puts  <<-USEFUL_ERROR
I can't find the helper file #{@server.helper_file} for the #{@server.server_name} testing framework.
Are you running me from the project directory?
          USEFUL_ERROR
          return
        end
      else
        @server = Spork::Server.available_servers.first
        if @server.nil?
          @output.puts  <<-USEFUL_ERROR
I can't find any testing frameworks to use.
Are you running me from a project directory?
          USEFUL_ERROR
          return
        end
      end
      @server
    end
    
    def run
      return false unless find_server
      ENV["DRB"] = 'true'
      ENV["RAILS_ENV"] ||= 'test' if server.using_rails?
      return server.bootstrap if options[:bootstrap]
      return(false) unless server.preload
      server.run
      return true
    end

    private
    attr_reader :options 

  end
end






