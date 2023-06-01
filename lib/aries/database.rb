require "csv"

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

    def add entity, attribute, value
      CSV.open @path, "ab" do |fh|
        time = Time.now.to_i
        fh << [entity, attribute, value, time]
      end
    end

    def puts eav
      add eav['entity'], eav['attribute'], eav['value']
    end

    def find criteria
      hit = nil
      (CSV.read @path, headers: true).reverse_each do |row|
        if criteria(row)
          puts "found #{row}"
          hit = row
          break
        end
      end

      return hit
    end

  end
end
