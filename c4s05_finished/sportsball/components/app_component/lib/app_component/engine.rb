module AppComponent
  class Engine < ::Rails::Engine
    isolate_namespace AppComponent

        config.generators do |g|
      g.orm             :active_record
      g.template_engine :slim
      g.test_framework  :rspec
    end

    config.generators do |g|
      g.orm             :active_record
      g.template_engine :slim
      g.test_framework  :rspec
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s+File::SEPARATOR
        app.config.paths["db/migrate"].concat config.paths["db/migrate"].expanded
      end
    end
  end
end
