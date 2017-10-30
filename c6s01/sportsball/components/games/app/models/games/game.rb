
module Games
  class Game < ActiveRecord::Base
    validates :date, :location, :first_team_id, :second_team_id, :winning_team,
              :first_team_score, :second_team_score, presence: true
  end
end

