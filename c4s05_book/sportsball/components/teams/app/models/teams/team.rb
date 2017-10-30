
module Teams
  class Team < ApplicationRecord
    validates :name, presence: true
  end
end

