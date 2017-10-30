
module AppComponent
  class Team < ApplicationRecord
    validates :name, presence: true
  end
end

