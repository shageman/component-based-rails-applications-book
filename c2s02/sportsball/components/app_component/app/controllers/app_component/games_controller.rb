require_dependency "app_component/application_controller"

module AppComponent
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :edit, :update, :destroy]

    # GET /games
    def index
      @games = Game.all
    end

    # GET /games/1
    def show
    end

    # GET /games/new
    def new
      @game = Game.new
    end

    # GET /games/1/edit
    def edit
    end

    # POST /games
    def create
      @game = Game.new(game_params)

      if @game.save
        redirect_to @game, notice: 'Game was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /games/1
    def update
      if @game.update(game_params)
        redirect_to @game, notice: 'Game was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /games/1
    def destroy
      @game.destroy
      redirect_to games_url, notice: 'Game was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_game
        @game = Game.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def game_params
        params.require(:game).permit(:date, :location, :first_team_id, :second_team_id, :winning_team, :first_team_score, :second_team_score)
      end
  end
end
