
require_dependency "teams_admin/application_controller"

module TeamsAdmin
  class TeamsController < ApplicationController
    before_action :ensure_dependencies
    before_action :set_team, only: [:show, :edit, :update, :destroy]

    def index
      @teams = @team_repository.get_all
    end

    def new
      @team = Teams::Team.new
    end

    def edit
    end

    def create
      team = Teams::Team.new(team_params[:id], team_params[:name])
      @team = @team_repository.create(team)

      if @team.persisted?
        redirect_to teams_teams_url, notice: "Team was successfully created."
      else
        render :new
      end
    end

    def update
      if @team_repository.update(@team.id, team_params[:name])
        redirect_to teams_teams_url, notice: "Team was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @team_repository.delete(@team.id)
      redirect_to teams_teams_url, notice: "Team was successfully destroyed."
    end

    private
    def set_team
      @team = @team_repository.get(params[:id])
    end

    def team_params
      params.require(:teams_team).permit(:name)
    end

    def ensure_dependencies
      @team_repository = TeamsStore::TeamRepository.new
    end
  end
end

