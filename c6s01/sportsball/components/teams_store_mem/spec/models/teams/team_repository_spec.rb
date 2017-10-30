
require "spec_helper"

RSpec.describe TeamsStore::TeamRepository do
  describe "create" do
    it "creates a persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to_not eq(nil)
      expect(team.name).to eq("testTeam")

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("testTeam")
    end

    it "cant create a persisted record if the model is invalid" do
      team = subject.create(Teams::Team.new(nil, ""))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to eq(nil)
      expect(team.name).to eq("")

      team = subject.create(Teams::Team.new(nil, nil))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to eq(nil)
      expect(team.name).to eq(nil)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team).to eq(nil)
    end
  end

  describe "update" do
    it "creates a persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.update(team.id, "newName")
      expect(updated_team).to eq(true)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")

      updated_team = subject.update(team.id, "")
      expect(updated_team).to eq(false)

      updated_team = subject.update(team.id, nil)
      expect(updated_team).to eq(false)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")
    end

    it "handles string ids" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.update(team.id.to_s, "newName")
      expect(updated_team).to eq(true)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")
    end
  end

  describe "delete" do
    it "deletes the persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.delete(team.id)
      expect(updated_team).to eq(team.id)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team).to eq(nil)
    end

    it "handles string ids" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.delete(team.id.to_s)
      expect(updated_team).to eq(team.id)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team).to eq(nil)
    end
  end

  describe "get" do
    it "retrieves previously persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      retrieved_team = subject.get(team.id)
      expect(retrieved_team).to be_a(Teams::Team)
      expect(retrieved_team.id).to_not eq(nil)
      expect(retrieved_team.name).to eq("testTeam")
    end

    it "handles string ids" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      retrieved_team = subject.get(team.id.to_s)
      expect(retrieved_team).to be_a(Teams::Team)
      expect(retrieved_team.id).to_not eq(nil)
      expect(retrieved_team.name).to eq("testTeam")
    end
  end

  describe "get_all" do
    it "retrieves all previously persisted record" do
      subject.create(Teams::Team.new(nil, "testTeam1"))
      subject.create(Teams::Team.new(nil, "testTeam2"))

      retrieved_teams = subject.get_all
      expect(retrieved_teams.size).to eq(2)

      expect(retrieved_teams[0]).to be_a(Teams::Team)
      expect(retrieved_teams[0].id).to_not eq(nil)
      expect(retrieved_teams[0].name).to eq("testTeam1")

      expect(retrieved_teams[1]).to be_a(Teams::Team)
      expect(retrieved_teams[1].id).to_not eq(nil)
      expect(retrieved_teams[1].name).to eq("testTeam2")
    end
  end
end

