# -*- encoding: utf-8 -*-
# stub: trueskill 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "trueskill".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lars Kuhnt".freeze]
  s.date = "2011-01-19"
  s.description = "".freeze
  s.email = "lars@sauspiel.de".freeze
  s.files = ["HISTORY.md".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "lib/saulabs/gauss.rb".freeze, "lib/saulabs/gauss/distribution.rb".freeze, "lib/saulabs/gauss/truncated_correction.rb".freeze, "lib/saulabs/trueskill.rb".freeze, "lib/saulabs/trueskill/factor_graph.rb".freeze, "lib/saulabs/trueskill/factors/base.rb".freeze, "lib/saulabs/trueskill/factors/greater_than.rb".freeze, "lib/saulabs/trueskill/factors/likelihood.rb".freeze, "lib/saulabs/trueskill/factors/prior.rb".freeze, "lib/saulabs/trueskill/factors/weighted_sum.rb".freeze, "lib/saulabs/trueskill/factors/within.rb".freeze, "lib/saulabs/trueskill/layers/base.rb".freeze, "lib/saulabs/trueskill/layers/iterated_team_performances.rb".freeze, "lib/saulabs/trueskill/layers/performances_to_team_performances.rb".freeze, "lib/saulabs/trueskill/layers/prior_to_skills.rb".freeze, "lib/saulabs/trueskill/layers/skills_to_performances.rb".freeze, "lib/saulabs/trueskill/layers/team_difference_comparision.rb".freeze, "lib/saulabs/trueskill/layers/team_performance_differences.rb".freeze, "lib/saulabs/trueskill/rating.rb".freeze, "lib/saulabs/trueskill/schedules/base.rb".freeze, "lib/saulabs/trueskill/schedules/loop.rb".freeze, "lib/saulabs/trueskill/schedules/sequence.rb".freeze, "lib/saulabs/trueskill/schedules/step.rb".freeze, "spec/saulabs/gauss/distribution_spec.rb".freeze, "spec/saulabs/gauss/truncated_correction_spec.rb".freeze, "spec/saulabs/trueskill/factor_graph_spec.rb".freeze, "spec/saulabs/trueskill/factors/greater_than_spec.rb".freeze, "spec/saulabs/trueskill/factors/likelihood_spec.rb".freeze, "spec/saulabs/trueskill/factors/prior_spec.rb".freeze, "spec/saulabs/trueskill/factors/weighted_sum_spec.rb".freeze, "spec/saulabs/trueskill/factors/within_spec.rb".freeze, "spec/saulabs/trueskill/layers/prior_to_skills_spec.rb".freeze, "spec/saulabs/trueskill/schedules_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/true_skill_matchers.rb".freeze]
  s.homepage = "http://github.com/saulabs/trueskill".freeze
  s.rubygems_version = "2.6.14".freeze
  s.summary = "A ruby library for the trueskill rating system".freeze
  s.test_files = ["spec/saulabs/gauss/distribution_spec.rb".freeze, "spec/saulabs/gauss/truncated_correction_spec.rb".freeze, "spec/saulabs/trueskill/factor_graph_spec.rb".freeze, "spec/saulabs/trueskill/factors/greater_than_spec.rb".freeze, "spec/saulabs/trueskill/factors/likelihood_spec.rb".freeze, "spec/saulabs/trueskill/factors/prior_spec.rb".freeze, "spec/saulabs/trueskill/factors/weighted_sum_spec.rb".freeze, "spec/saulabs/trueskill/factors/within_spec.rb".freeze, "spec/saulabs/trueskill/layers/prior_to_skills_spec.rb".freeze, "spec/saulabs/trueskill/schedules_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/true_skill_matchers.rb".freeze]

  s.installed_by_version = "2.6.14" if s.respond_to? :installed_by_version
end
