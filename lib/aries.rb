# frozen_string_literal: true
require_relative "aries/version"
require_relative "aries/database"

require "json"
require "socket"

module Aries
  class Error < StandardError; end
  # Your code goes here...

  def self.action callable
    begin
      [callable.call, nil]
    rescue => e
      [nil, e]
    end
  end

  def self.valid? commands
    for command in commands
      command.keys.each do |k|
        if ! ["add", "find", "first"].include? k
          return [nil, "Undefined command key '#{k}'"]
        end

        command[k].keys.each do |col|
          if ! ["entity", "attribute", "value", "check"].include? col
            return [nil, "Undefined column '#{col}'"]
          end
        end
      end
    end

    return [true, nil]
  end

  host   = "localhost"
  port   = 1234
  server = TCPServer.new host, port
    
  puts "Server started, listening #{host}:#{port}"

  loop do

    client = server.accept
    client.puts "Connected to Aries"
    puts "Client connected #{client}"

    while commands = client.gets
      commands, err = action -> { JSON.parse commands }

      if ! err.nil?
        client.puts JSON.generate(err: err)
        next
      end

      _, err = valid? commands

      if ! err.nil?
        client.puts JSON.generate(err: err)
        next
      end

      db = Database.new Dir.home

      results = {}
      commands.each_with_index do |command, idx|
        
        func, vals = command.to_a.first
        begin
          results[idx] = db.send(func, vals)
        rescue => e
          results = {err: e}
          break
        end
      end

      client.puts JSON.generate(results)
    end

    client.close
    puts "Client disconnected #{client}"
  end

end
