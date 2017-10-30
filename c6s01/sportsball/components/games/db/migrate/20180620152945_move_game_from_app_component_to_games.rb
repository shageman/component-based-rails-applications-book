
class MoveGameFromAppComponentToGames < ActiveRecord::Migration[5.0]
  def change
    rename_table :app_component_games, :games_games
  end
end

