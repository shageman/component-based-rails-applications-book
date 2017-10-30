
RSpec.describe TeamsAdmin::TeamsController, :type => :controller do
  routes { TeamsAdmin::Engine.routes }

  let(:valid_attributes) { new_team(name: "Our team").as_json }
  let(:invalid_attributes) { new_team(name: "").as_json }
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all teams as @teams" do
      team = create_team
      get :index, params: {}, session: valid_session
      expect(assigns(:teams)).to eq [team]
    end

    describe "view" do
      render_views

      it "renders a list of teams" do
        create_team name: "myteam x"
        create_team name: "myteam x"

        get :index, params: {}, session: valid_session

        assert_select "tr>td", :text => "myteam x", :count => 2
      end
    end
  end

  describe "GET new" do
    it "assigns a new team as @team" do
      get :new, params: {}, session: valid_session
      expect(assigns(:team)).to be_a_new Teams::Team
    end

    describe "view" do
      render_views

      it "renders new team form" do
        get :new, params: {}, session: valid_session

        assert_select "form[action=?][method=?]", teams_teams_path, "post" do
          assert_select "input#teams_team_name"
        end
      end
    end
  end

  describe "GET edit" do
    it "assigns the requested team as @team" do
      team = create_team
      get :edit, params: {:id => team.to_param}, session: valid_session
      expect(assigns(:team)).to eq team
    end

    describe "view" do
      render_views

      it "renders the edit team form" do
        team = create_team
        get :edit, params: {:id => team.to_param}, session: valid_session

        assert_select "form[action=?][method=?]", teams_team_path(team), "post" do
          assert_select "input#teams_team_name"
        end
      end
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Teams::Team" do
        previous_count = TeamsStore::TeamRepository.new.get_all.count
        post :create, params: {:teams_team => valid_attributes}, session: valid_session
        expect(TeamsStore::TeamRepository.new.get_all.count - 1).
            to eq (previous_count)
      end

      it "assigns a newly created team as @team" do
        post :create, params: {:teams_team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a Teams::Team
        expect(assigns(:team)).to be_persisted
      end

      it "redirects to the index" do
        post :create, params: {:teams_team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_teams_path
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved team as @team" do
        post :create, params: {:teams_team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a_new Teams::Team
      end

      it "re-renders the new template" do
        post :create, params: {:teams_team => invalid_attributes}, session: valid_session
        expect(response).to render_template "new"
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      let(:new_attributes) {
        {name: "new team name"}
      }

      it "updates the requested team" do
        existing_team = create_team
        put :update, params: {:id => existing_team.to_param, :teams_team => new_attributes}, session: valid_session
        team = TeamsStore::TeamRepository.new.get(existing_team.id)
        expect(team.name).to eq("new team name")
      end

      it "assigns the requested team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "redirects to the index" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_teams_path
      end
    end

    describe "with invalid params" do
      it "assigns the team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "re-renders the edit template" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => invalid_attributes}, session: valid_session
        expect(response).to render_template "edit"
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested team" do
      team = create_team
      previous_count = TeamsStore::TeamRepository.new.get_all.count
      delete :destroy, params: {:id => team.to_param}, session: valid_session
      expect(TeamsStore::TeamRepository.new.get_all.count + 1).
          to eq (previous_count)
    end

    it "redirects to the teams list" do
      team = create_team
      delete :destroy, params: {:id => team.to_param}, session: valid_session
      expect(response).to redirect_to teams_teams_url
    end
  end
end

