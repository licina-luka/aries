require "csv"
require "json"

module Aries
  class Database

    attr_reader :headers

    def initialize path
      @headers = ['entity', 'attribute', 'value', 'timestamp']
      @path = File.join path, "db.csv"

      if ! File.exists? @path
        CSV.open @path, "w" do |fh|
          fh << @headers
        end
      end
    end

    def append entity, attribute, value
      CSV.open @path, "ab" do |fh|
        time = Time.now.to_i
        fh << [entity, attribute, value, time]
      end
    end

    def add eav
      add eav['entity'], eav['attribute'], eav['value']
    end

    def find criteria
      check = lambda do |row, criteria|
        criteria.keys.each do |k|
          if row[k].nil?
            return false
          end

          if JSON.parse(row[k]) != criteria[k]
            return false
          end

          return true
        end
      end

      hit = nil
      (CSV.read @path, headers: true).reverse_each do |row|
        if check.call row, criteria
          hit = row
          break
        end
      end

      return hit
    end

  end
end
