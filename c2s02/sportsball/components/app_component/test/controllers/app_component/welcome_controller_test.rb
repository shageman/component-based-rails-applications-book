require 'test_helper'

module AppComponent
  class WelcomeControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should get index" do
      get welcome_index_url
      assert_response :success
    end

  end
end
