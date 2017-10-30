
require_dependency "games_admin/application_controller"
module GamesAdmin
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :edit, :update, :destroy]

    def index
      @games = AppComponent::Game.all
    end

    def show
    end

    def new
      @game = AppComponent::Game.new
    end

    def edit
    end

    def create
      @game = AppComponent::Game.new(game_params)

      if @game.save
        redirect_to @game, notice: "Game was successfully created."
      else
        render :new
      end
    end

    def update
      if @game.update(game_params)
        redirect_to @game, notice: "Game was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @game.destroy
      redirect_to games_url, notice: "Game was successfully destroyed."
    end

    private
      def set_game
        @game = AppComponent::Game.find(params[:id])
      end

      def game_params
        params.require(:game).permit(:date, :location, :first_team_id, :second_team_id, :winning_team, :first_team_score, :second_team_score)
      end
  end
end

