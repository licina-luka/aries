require "csv"
require "erb"
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

    def find criteria, all=true
      check = lambda do |row, criteria|
        criteria.keys.each do |k|
          if k == "check"
            entity, attribute, value = [row['entity'], row['attribute'], row['value']]
            return ERB.new(criteria[k]).result(binding) == 'true'
          end

          val = row[k].nil? ? nil : JSON.parse(row[k])

          if criteria[k].nil? && (val.nil? || val.to_s.blank?)
            return true
          end

          if val == criteria[k]
            return true
          end
            
          return false
        end
      end

      hits = []
      (CSV.read @path, headers: true).reverse_each do |row|
        if check.call row, criteria
          hits.push row.to_h
          
          if ! all
          break
          end
        end
      end
      
      return hits
    end
    
    def first criteria
      find criteria, false
    end

  end
end
