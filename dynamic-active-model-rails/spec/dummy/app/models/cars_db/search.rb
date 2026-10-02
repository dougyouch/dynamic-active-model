# frozen_string_literal: true

# An ordinary autoloaded class living alongside the generated models
module CarsDB
  class Search
    def self.for_make(name)
      CarsDB::Car.by_make(name)
    end
  end
end
