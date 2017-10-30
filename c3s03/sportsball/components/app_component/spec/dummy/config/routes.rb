Rails.application.routes.draw do
  mount AppComponent::Engine => "/app_component"
end
