
module TeamsStore
  class TeamRepository
    def get_all
      TeamRecord.all.map do |team_record|
        team_from_record(team_record)
      end
    end

    def get(id)
      team_record = TeamRecord.find_by_id(id)
      team_from_record(team_record)
    end

    def create(team)
      team_record = TeamRecord.create(name: team.name)
      team_from_record(team_record)
    end

    def update(id, name)
      TeamRecord.find_by_id(id).update(name: name)
    end

    def delete(id)
      TeamRecord.delete(id)
    end

    private

    class TeamRecord < ActiveRecord::Base
      self.table_name = "teams_teams"

      validates :name, presence: true
    end
    private_constant(:TeamRecord)

    def team_from_record(team_record)
      Teams::Team.new(team_record.id, team_record.name)
    end
  end
end

