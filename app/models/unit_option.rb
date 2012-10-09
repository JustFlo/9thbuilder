class UnitOption < ActiveRecord::Base
  belongs_to :unit
  belongs_to :parent, :class_name => "UnitOption"
  belongs_to :depend, :class_name => "UnitOption"
  has_many :children, :class_name => "UnitOption", :order => "position", :foreign_key => "parent_id", :dependent => :nullify

  validates_presence_of :unit_id, :name
  validates_numericality_of :value_points, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :position, :greater_than_or_equal_to => 1, :only_integer => true, :allow_nil => true
  validates_inclusion_of :is_per_model, :in => [true, false]
  validates_inclusion_of :is_magic_items, :in => [true, false]
  validates_inclusion_of :is_magic_standards, :in => [true, false]
  validates_inclusion_of :is_unique_choice, :in => [true, false]

  acts_as_list :scope => 'unit_id = #{unit_id} AND COALESCE(parent_id, \'\') = \'#{parent_id}\''

  scope :without_parent, where(:parent_id => nil)
  scope :exclude_magics, where(:is_magic_items => false, :is_magic_standards => false)
  scope :only_magic_items, where(:is_magic_items => true, :is_magic_standards => false)
  scope :only_magic_standards, where(:is_magic_items => false, :is_magic_standards => true)
end
