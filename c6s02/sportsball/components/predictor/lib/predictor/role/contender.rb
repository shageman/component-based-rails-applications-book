
module Predictor
  module Role
    module Contender
      def self.extended(base)
        base.rating = [Saulabs::TrueSkill::Rating.new(1500.0, 1000.0, 1.0)]
      end

      def rating
        @rating
      end

      def rating=(value)
        @rating = value
      end

      def mean_of_rating
        @rating.first.mean
      end
    end
  end
end

