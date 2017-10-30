
class MoveTeamFromAppComponentToTeams < ActiveRecord::Migration[5.0]
  def change
    rename_table :app_component_teams, :teams_teams
  end
end

