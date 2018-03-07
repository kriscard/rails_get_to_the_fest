class Artist < ApplicationRecord
  has_many :line_ups
  has_many :festivals, through: :line_ups
  has_many :user_artists
end
