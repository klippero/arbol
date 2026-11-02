class User < ApplicationRecord
  belongs_to :person, optional: true

  def display_name
    person&.name.presence || email.split('@').first
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
