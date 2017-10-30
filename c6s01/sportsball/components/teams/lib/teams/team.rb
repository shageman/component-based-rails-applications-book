
module Teams
  class Team
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Naming

    attr_reader :id, :name

    def initialize(id=nil, name=nil)
      @id = id
      @name = name
    end

    def persisted?
      @id != nil
    end

    def ==(other)
      other.is_a?(Teams::Team) && @id == other.id
    end

    def new_record?
      !persisted?
    end
  end
end

