class Artist < ApplicationRecord
  has_one_attached :photo
  has_many :posts
  has_many :user_artists
  has_many :users, through: :user_artists
end
