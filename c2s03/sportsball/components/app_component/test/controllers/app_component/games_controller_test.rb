require 'test_helper'

module AppComponent
  class GamesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @game = app_component_games(:one)
    end

    test "should get index" do
      get games_url
      assert_response :success
    end

    test "should get new" do
      get new_game_url
      assert_response :success
    end

    test "should create game" do
      assert_difference('Game.count') do
        post games_url, params: { game: { date: @game.date, first_team_id: @game.first_team_id, first_team_score: @game.first_team_score, location: @game.location, second_team_id: @game.second_team_id, second_team_score: @game.second_team_score, winning_team: @game.winning_team } }
      end

      assert_redirected_to game_url(Game.last)
    end

    test "should show game" do
      get game_url(@game)
      assert_response :success
    end

    test "should get edit" do
      get edit_game_url(@game)
      assert_response :success
    end

    test "should update game" do
      patch game_url(@game), params: { game: { date: @game.date, first_team_id: @game.first_team_id, first_team_score: @game.first_team_score, location: @game.location, second_team_id: @game.second_team_id, second_team_score: @game.second_team_score, winning_team: @game.winning_team } }
      assert_redirected_to game_url(@game)
    end

    test "should destroy game" do
      assert_difference('Game.count', -1) do
        delete game_url(@game)
      end

      assert_redirected_to games_url
    end
  end
end
