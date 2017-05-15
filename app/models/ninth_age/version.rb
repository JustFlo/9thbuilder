class NinthAge::Version < ApplicationRecord
  has_many :armies, dependent: :destroy
  has_many :magics, dependent: :destroy

  translates :name
  globalize_accessors

  validates :name, presence: true

  def cache_key
    super + '-ninth-age-' + Globalize.locale.to_s
  end
end