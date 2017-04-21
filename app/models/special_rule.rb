class SpecialRule < ApplicationRecord
  belongs_to :unit
  belongs_to :troop

  translates :name
  globalize_accessors

  validates :unit_id, :name, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 1, only_integer: true, allow_nil: true }

  acts_as_list scope: :unit

  attr_accessor :army_filter

  def army_filter
    @army_filter ||= unit.try(:army).try(:id)
  end
end
