
module TeamsStore
  class TeamRepository
    def get_all
      TeamsStore::Db.get.values
    end

    def get(key)
      id = key.to_i
      TeamsStore::Db.get[id]
    end

    def create(team)
      return team if [nil, ""].include? team.name

      id = TeamsStore::Db.get.keys.max && TeamsStore::Db.get.keys.max + 1 || 1
      TeamsStore::Db.get[id] = Teams::Team.new(id, team.name)
    end

    def update(key, name)
      id = key.to_i
      return false if [nil, ""].include? name

      TeamsStore::Db.get[id] = Teams::Team.new(id, name)
      true
    end

    def delete(key)
      id = key.to_i

      TeamsStore::Db.get.delete(id)
      id
    end
  end
end

