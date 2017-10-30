
module TeamsStore
  module Db
    def self.reset
      $teams_db = {}
    end

    def self.get
      $teams_db
    end
  end
end

