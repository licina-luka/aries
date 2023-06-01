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
    commands.keys.each do |k|
      if ! ["add", "find"].include? k
        return [nil, "Undefined command key #{k}"]
      end

      commands[k].keys.each do |col|
        if ! ["entity", "attribute", "value"].include? col
          return [nil, "Undefined column #{col}"]
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
        client.puts err
        next
      end

      _, err = valid? commands

      if ! err.nil?
        client.puts err
        next
      end

      db = Database.new Dir.home

      results = {}
      commands.each_with_index do |command, idx|
        
        func, vals = command
        results[command] = db.send(func, vals)
      end

      client.puts results
    end

    client.close
    puts "Client disconnected #{client}"
  end

end
