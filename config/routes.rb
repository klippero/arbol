Rails.application.routes.draw do
  devise_for :users
  get 'tree/familia'
  get 'tree/persona'
  get 'tree/foto', to: 'tree#foto', as: :tree_foto
  get 'tree/fechas', to: 'tree#fechas', as: :tree_fechas
  get 'tree/personas_buscar', to: 'tree#personas_buscar', as: :tree_personas_buscar
  get 'tree/apellidos', to: 'tree#apellidos', as: :tree_apellidos
  get 'tree/cumples'
  get 'tree/new'
  get 'tree/familia_json', to: 'tree#familia_json'
  resources :families_people
  resources :people_photos
  resources :photos
  resources :families
  resources :people
  root to: redirect('/tree/familia?f=1')

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
