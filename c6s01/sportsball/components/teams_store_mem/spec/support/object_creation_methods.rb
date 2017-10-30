
module TeamsStore::ObjectCreationMethods
  def new_team(overrides = {})
    Teams::Team.new(nil, overrides[:name] || "Some name #{counter}")
  end

  def create_team(overrides = {})
    TeamsStore::TeamRepository.new.create(new_team(overrides))
  end

  private

  def counter
    @counter ||= 0
    @counter += 1
  end
end

