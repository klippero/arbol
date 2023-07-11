Rails.application.routes.draw do
  devise_for :users
  get 'tree/familia'
  get 'tree/persona'
  get 'tree/cumples'
  get 'album/photos'
  get 'arbol/familia'
  resources :families_people
  resources :people_photos
  resources :photos
  resources :families
  resources :people
  root to: redirect('/tree/familia?f=1')

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
