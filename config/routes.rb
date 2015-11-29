Rails.application.routes.draw do
  root to: 'pages#index'
  namespace :v1, defaults: {format: 'json'} do
    resources :alias
    get 'register', to: 'access#create'
  end  
end
