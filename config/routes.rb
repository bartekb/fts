Fts::Application.routes.draw do
  resources :documents

  resources :categories
  resources :articles do
    collection do
      get :populate
    end
  end
end
