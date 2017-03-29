class Army < ApplicationRecord
  has_many :army_lists, dependent: :destroy
  has_many :magic_items, dependent: :destroy
  has_many :magic_standards, dependent: :destroy
  has_many :extra_item_categories, dependent: :destroy
  has_many :units, -> { order 'name' }, dependent: :destroy
  has_many :favorite_users, class_name: 'User', foreign_key: 'favorite_army_id', dependent: :nullify

  validates :name, presence: true

  scope :disabled, -> { where('id NOT IN (SELECT DISTINCT army_id FROM units)') }
  scope :disabled_or_obsolete, -> { where('id NOT IN (SELECT DISTINCT army_id FROM units) OR name LIKE \'%obsolète%\'') }

  def obsolete?
    name =~ /obsolète/i
  end

  def duplicate
    new_units = {}

    new_army = dup
    new_army.name = "Copy of #{new_army.name}"
    new_army.units << units.collect { |unit| new_units[unit.id] = unit.duplicate }

    new_army.units.each do |unit|
      unit.unit_options.map do |unit_option|
        unit_option.mount = new_units[unit_option.mount.id] unless unit_option.mount.nil?
      end
    end

    new_army
  end
end
