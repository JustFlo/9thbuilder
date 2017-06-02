class RolifyCreateRoles < ActiveRecord::Migration[5.0]
  def change
    create_table(:roles) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:users_roles, :id => false) do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
    end

    add_index(:roles, :name)
    add_index(:roles, [ :name, :resource_type, :resource_id ])
    add_index(:users_roles, [ :user_id, :role_id ])

    Role.create :name => 'Administrator'
    Role.create :name => 'Moderator'

    execute 'INSERT INTO users (`email`, `encrypted_password`,`reset_password_token`, `reset_password_sent_at`, `remember_created_at`,`sign_in_count`, `current_sign_in_at`, `last_sign_in_at`, `current_sign_in_ip`, `last_sign_in_ip`,`created_at`,`updated_at`)
              SELECT `email`, `encrypted_password`,`reset_password_token`, `reset_password_sent_at`, `remember_created_at`,`sign_in_count`, `current_sign_in_at`, `last_sign_in_at`, `current_sign_in_ip`, `last_sign_in_ip`,`created_at`,`updated_at`
              FROM `admin_users`
              WHERE `email` NOT IN (SELECT `email` FROM users)'

    execute 'INSERT INTO users_roles (user_Id, role_id)
              SELECT id, 1
              FROM users
              WHERE `email` IN (SELECT `email` FROM admin_users)'

    drop_table :admin_users

    rename_table :armies, :ninth_age_armies

    NinthAge::Army.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_army_translations, :ninth_age_armies, column: :ninth_age_army_id, on_delete: :cascade


    create_table :ninth_age_versions do |t|
      t.integer :major, null: false, default: 0
      t.integer :minor, null: false, default: 0
      t.integer :fix, null: false, default: 0
      t.boolean :public, null: false, default: false

      t.timestamps
    end

    NinthAge::Version.create_translation_table!({:name => :string})

    NinthAge::Version.create :name => 'V-1.0.0', :major => 1, :minor => 0, :fix => 0, :public => true

    add_column :ninth_age_armies, :version_id, :integer, :default => 0, :null => true
    add_index :ninth_age_armies, :version_id

    NinthAge::Army.update_all(version_id: 1)

    add_foreign_key :ninth_age_armies, :ninth_age_versions, column: :version_id, on_delete: :cascade

    create_table :ninth_age_magics do |t|
      t.belongs_to :version, null: false

      t.timestamps
    end
    add_foreign_key :ninth_age_magics, :ninth_age_versions, column: :version_id

    NinthAge::Magic.create_translation_table! :name => :string, :description => :text
    add_foreign_key :ninth_age_magic_translations, :ninth_age_magics, column: :ninth_age_magic_id, on_delete: :cascade

    create_table :ninth_age_magic_spells do |t|
      t.belongs_to :magic, null: false
      t.column :type_lvl, :integer, default: 0
      t.column :type_target, :integer, default: 0
      t.column :duration, :integer, default: 0

      t.timestamps
    end
    add_foreign_key :ninth_age_magic_spells, :ninth_age_magics, column: :magic_id

    NinthAge::MagicSpell.create_translation_table! :name => :string, :range => :string, :casting_value => :string, :effect => :text
    add_foreign_key :ninth_age_magic_spell_translations, :ninth_age_magic_spells, column: :ninth_age_magic_spell_id, on_delete: :cascade

    add_attachment :ninth_age_armies, :logo
    add_attachment :ninth_age_magics, :logo

    create_table :ninth_age_army_organisations do |t|
      t.belongs_to :army, index: false, null: false, default: 0
      t.timestamps
    end
    add_foreign_key :ninth_age_army_organisations, :ninth_age_armies, column: :army_id

    NinthAge::ArmyOrganisation.create_translation_table! :name => :string, :description => :string
    add_foreign_key :ninth_age_army_organisation_translations, :ninth_age_army_organisations, column: :ninth_age_army_organisation_id, on_delete: :cascade

    create_table :ninth_age_organisations do |t|
      t.belongs_to :army, index: false, null: false, default: 0
      t.boolean :isSpecialRule, null: false, default: false
      t.timestamps
    end
    add_attachment :ninth_age_organisations, :logo
    add_foreign_key :ninth_age_organisations, :ninth_age_armies, column: :army_id

    NinthAge::Organisation.create_translation_table! :name => :string
    add_foreign_key :ninth_age_organisation_translations, :ninth_age_organisations, column: :ninth_age_organisation_id, on_delete: :cascade

    create_table :ninth_age_organisation_groups do |t|
      t.belongs_to :army_organisation, null: false, default: 0
      t.belongs_to :organisation, null: false, default: 0
      t.column :type_target, :integer, default: 0
      t.integer :target, null: false, default: 0
      t.timestamps
    end
    add_foreign_key :ninth_age_organisation_groups, :ninth_age_army_organisations, column: :army_organisation_id
    add_foreign_key :ninth_age_organisation_groups, :ninth_age_organisations, column: :organisation_id

    create_table :ninth_age_organisation_changes do |t|
      t.belongs_to :default_organisation, index: true, null: false, default: 0, :references => [:organisations, :id]
      t.belongs_to :new_organisation, index: true, null: false, default: 0, :references => [:organisations, :id]
      t.belongs_to :unit, index: true, null: false, default: 0
      t.integer :number, null: false, default: 0
      t.column :type_target, :integer, default: 0

      t.timestamps
    end
    add_foreign_key :ninth_age_organisation_changes, :ninth_age_organisations, column: :default_organisation_id
    add_foreign_key :ninth_age_organisation_changes, :ninth_age_organisations, column: :new_organisation_id
    add_foreign_key :ninth_age_organisation_changes, :units, column: :unit_id

    create_table :ninth_age_organisations_units, id: false do |t|
      t.belongs_to :unit, index: false, null: false, default: 0
      t.belongs_to :organisation, index: false, null: false, default: 0
    end
    add_foreign_key :ninth_age_organisations_units, :units, column: :unit_id
    add_foreign_key :ninth_age_organisations_units, :ninth_age_organisations, column: :organisation_id

    add_index :ninth_age_organisations_units, [:unit_id, :organisation_id], name: 'ninth_age_units_organisations_unit_organisation', :unique => true
    add_index :ninth_age_organisations_units, [:organisation_id, :unit_id], name: 'ninth_age_units_organisations_organisation_unit', :unique => true

    create_table :builder_army_list_organisations do |t|
      t.belongs_to :army_list, index: false, null: false, default: 0
      t.belongs_to :organisation, index: false, null: false, default: 0
      t.integer :pts, null: false, default: 0
      t.integer :rate, null: false, default: 0
      t.boolean :good, null: false, default: false
    end
    add_foreign_key :builder_army_list_organisations, :army_lists, column: :army_list_id
    add_foreign_key :builder_army_list_organisations, :ninth_age_organisations, column: :organisation_id

    add_index :builder_army_list_organisations, [:army_list_id, :organisation_id], name: 'builder_army_list_organisations_army_list_organisation', :unique => true
    add_index :builder_army_list_organisations, [:organisation_id, :army_list_id], name: 'builder_army_list_organisations_organisation_army_list', :unique => true

    #Translations of equipments
    create_table :ninth_age_special_rules do |t|

      t.timestamps
    end
    NinthAge::SpecialRule.create_translation_table!({:name => :string, :description => :text})
    add_foreign_key :ninth_age_special_rule_translations, :ninth_age_special_rules, column: :ninth_age_special_rule_id, on_delete: :cascade


    create_table :ninth_age_special_rule_unit_troops do |t|
      t.belongs_to :special_rule, index: false, null: false, default: 0
      t.belongs_to :unit, index: false, null: false, default: 0
      t.belongs_to :troop, index: false, null: true, default: 0
      t.integer :position, :null => false, default: 0
      t.timestamps
    end
    add_foreign_key :ninth_age_special_rule_unit_troops, :ninth_age_special_rules, column: :special_rule_id
    add_foreign_key :ninth_age_special_rule_unit_troops, :units, column: :unit_id
    add_foreign_key :ninth_age_special_rule_unit_troops, :troops, column: :troop_id

    add_index :ninth_age_special_rule_unit_troops, [:special_rule_id, :unit_id, :troop_id], name: 'ninth_age_special_rules_troops_rule_troop', :unique => true


    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_special_rules (id, created_at, updated_at)
                                      SELECT id, NOW(), NOW() FROM special_rules;')

    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_special_rule_unit_troops (position, special_rule_id, unit_id, troop_id, created_at, updated_at)
                                      SELECT position, id, unit_id, troop_id, NOW(), NOW() FROM special_rules;')

    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_special_rule_translations (ninth_age_special_rule_id, locale, name, created_at, updated_at)
                                      SELECT id, \'en\', name, NOW(), NOW() FROM special_rules;')

    drop_table :special_rules


    ActiveRecord::Base.connection.execute('  INSERT INTO ninth_age_special_rule_unit_troops (special_rule_id, unit_id, troop_id, position, created_at, updated_at)
    select distinct t2.new_id, troops.unit_id, troops.troop_id, MIN(troops.position), troops.created_at, troops.updated_at
    from ninth_age_special_rule_unit_troops troops
    INNER JOIN
    (select T.ninth_age_special_rule_id, t1.ninth_age_special_rule_id as new_id
    from ninth_age_special_rule_translations T
    INNER JOIN (
                        SELECT MIN(ninth_age_special_rule_id) as ninth_age_special_rule_id, name as name
    FROM ninth_age_special_rule_translations
    group by name
    having count(*) > 1) as t1
    ON T.ninth_age_special_rule_id != t1.ninth_age_special_rule_id AND T.name = t1.name
    WHERE t1.ninth_age_special_rule_id IS NOT NULL) as t2 ON troops.special_rule_id = t2.ninth_age_special_rule_id
    group by t2.new_id, troops.unit_id, troops.troop_id, troops.created_at, troops.updated_at')

    ActiveRecord::Base.connection.execute('DELETE FROM ninth_age_special_rule_unit_troops
    where special_rule_id in (
    select T.ninth_age_special_rule_id
    from ninth_age_special_rule_translations T
    LEFT OUTER JOIN (
                        SELECT MIN(ninth_age_special_rule_id) as ninth_age_special_rule_id, name as name
    FROM ninth_age_special_rule_translations
    group by name
    having count(*) > 1) as t1
    ON T.ninth_age_special_rule_id != t1.ninth_age_special_rule_id AND T.name = t1.name
    WHERE t1.ninth_age_special_rule_id IS NOT NULL)')

    ActiveRecord::Base.connection.execute('delete FROM ninth_age_special_rule_translations
    where ninth_age_special_rule_id not in (select special_rule_id from ninth_age_special_rule_unit_troops)')

    ActiveRecord::Base.connection.execute('delete FROM ninth_age_special_rules
    where id not in (select special_rule_id from ninth_age_special_rule_unit_troops)')

    #Translations of equipments
    create_table :ninth_age_equipments do |t|

      t.timestamps
    end
    NinthAge::Equipment.create_translation_table!({:name => :string, :description => :text})
    add_foreign_key :ninth_age_equipment_translations, :ninth_age_equipments, column: :ninth_age_equipment_id, on_delete: :cascade


    create_table :ninth_age_equipment_unit_troops do |t|
      t.belongs_to :equipment, index: false, null: false, default: 0
      t.belongs_to :unit, index: false, null: false, default: 0
      t.belongs_to :troop, index: false, null: true, default: 0
      t.integer :position, :null => false, default: 0
      t.timestamps
    end
    add_foreign_key :ninth_age_equipment_unit_troops, :ninth_age_equipments, column: :equipment_id
    add_foreign_key :ninth_age_equipment_unit_troops, :units, column: :unit_id
    add_foreign_key :ninth_age_equipment_unit_troops, :troops, column: :troop_id

    add_index :ninth_age_equipment_unit_troops, [:equipment_id, :unit_id, :troop_id], name: 'ninth_age_equipments_troops_rule_troop', :unique => true


    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_equipments (id, created_at, updated_at)
                                      SELECT id, NOW(), NOW() FROM equipments;')

    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_equipment_unit_troops (position, equipment_id, unit_id, troop_id, created_at, updated_at)
                                      SELECT position, id, unit_id, troop_id, NOW(), NOW() FROM equipments;')

    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_equipment_translations (ninth_age_equipment_id, locale, name, created_at, updated_at)
                                      SELECT id, \'en\', name, NOW(), NOW() FROM equipments;')

    drop_table :equipments

    ActiveRecord::Base.connection.execute('INSERT INTO ninth_age_equipment_unit_troops (equipment_id, unit_id, troop_id, position, created_at, updated_at)
    select distinct t2.new_id, troops.unit_id, troops.troop_id, MIN(troops.position), troops.created_at, troops.updated_at
    from ninth_age_equipment_unit_troops troops
    INNER JOIN
    (select T.ninth_age_equipment_id, t1.ninth_age_equipment_id as new_id
    from ninth_age_equipment_translations T
    INNER JOIN (
                        SELECT MIN(ninth_age_equipment_id) as ninth_age_equipment_id, name as name
    FROM ninth_age_equipment_translations
    group by name
    having count(*) > 1) as t1
    ON T.ninth_age_equipment_id != t1.ninth_age_equipment_id AND T.name = t1.name
    WHERE t1.ninth_age_equipment_id IS NOT NULL) as t2 ON troops.equipment_id = t2.ninth_age_equipment_id
    group by t2.new_id, troops.unit_id, troops.troop_id, troops.created_at, troops.updated_at')

    ActiveRecord::Base.connection.execute('delete FROM ninth_age_equipment_unit_troops
    where equipment_id in (
    select T.ninth_age_equipment_id
    from ninth_age_equipment_translations T
    LEFT OUTER JOIN (
                        SELECT MIN(ninth_age_equipment_id) as ninth_age_equipment_id, name as name
    FROM ninth_age_equipment_translations
    group by name
    having count(*) > 1) as t1
    ON T.ninth_age_equipment_id != t1.ninth_age_equipment_id AND T.name = t1.name
    WHERE t1.ninth_age_equipment_id IS NOT NULL)')

    ActiveRecord::Base.connection.execute('delete FROM ninth_age_equipment_translations
    where ninth_age_equipment_id not in (select equipment_id from ninth_age_equipment_unit_troops)')

    ActiveRecord::Base.connection.execute('delete FROM ninth_age_equipments
    where id not in (select equipment_id from ninth_age_equipment_unit_troops)')

    rename_table :troops, :ninth_age_troops
    rename_table :troop_types, :ninth_age_troop_types

    NinthAge::TroopType.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_troop_type_translations, :ninth_age_troop_types, column: :ninth_age_troop_type_id, on_delete: :cascade
    NinthAge::Troop.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_troop_translations, :ninth_age_troops, column: :ninth_age_troop_id, on_delete: :cascade

    rename_table :extra_items, :ninth_age_extra_items
    rename_table :extra_item_categories, :ninth_age_extra_item_categories

    NinthAge::ExtraItemCategory.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_extra_item_category_translations, :ninth_age_extra_item_categories, column: :ninth_age_extra_item_category_id, on_delete: :cascade
    NinthAge::ExtraItem.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_extra_item_translations, :ninth_age_extra_items, column: :ninth_age_extra_item_id, on_delete: :cascade

    rename_table :magic_items, :ninth_age_magic_items
    rename_table :magic_item_categories, :ninth_age_magic_item_categories

    NinthAge::MagicItemCategory.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_magic_item_category_translations, :ninth_age_magic_item_categories, column: :ninth_age_magic_item_category_id, on_delete: :cascade
    NinthAge::MagicItem.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_magic_item_translations, :ninth_age_magic_items, column: :ninth_age_magic_item_id, on_delete: :cascade

    rename_table :magic_standards, :ninth_age_magic_standards

    NinthAge::MagicStandard.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_magic_standard_translations, :ninth_age_magic_standards, column: :ninth_age_magic_standard_id, on_delete: :cascade

    rename_table :units, :ninth_age_units
    rename_table :unit_options, :ninth_age_unit_options

    NinthAge::UnitOption.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_unit_option_translations, :ninth_age_unit_options, column: :ninth_age_unit_option_id, on_delete: :cascade
    NinthAge::Unit.create_translation_table!({:name => :string}, {:migrate_data => true, :remove_source_columns => true})
    add_foreign_key :ninth_age_unit_translations, :ninth_age_units, column: :ninth_age_unit_id, on_delete: :cascade

    add_column :ninth_age_units, :is_mount, :boolean, :default => 0, :null => false
    ActiveRecord::Base.connection.execute('UPDATE ninth_age_units
                                      SET is_mount = 1
                                      WHERE id in (SELECT ninth_age_unit_id FROM ninth_age_unit_translations where name like \'%Mount%\')')

    add_column :ninth_age_units, :type_figurine, :integer, :default => 0, :null => false
    add_column :ninth_age_units, :base, :integer, :default => 0, :null => false
    add_column :ninth_age_units, :max, :integer, :default => 0
    add_column :ninth_age_units, :max_model, :integer
    add_column :ninth_age_units, :pts_setup, :integer, :default => 0, :null => false
    add_column :ninth_age_units, :pts_add_figurine, :integer, :default => 0
    add_column :ninth_age_units, :order, :integer, :default => 0, :null => false

    ActiveRecord::Base.connection.execute('UPDATE ninth_age_units SET pts_setup = value_points WHERE value_points is not null;')
    ActiveRecord::Base.connection.execute('UPDATE ninth_age_units SET max = 1 WHERE is_unique = 1;')

    remove_column :ninth_age_units, :is_unique
    remove_column :ninth_age_units, :value_points


    unit_categories = Builder::ArmyList.connection.select_all 'SELECT uc.id as id, uc.name as name, uc.min_quota as min_quota, uc.max_quota as max_quota FROM unit_categories uc;'

    NinthAge::Army.all.each do |army|

      army_organisation = NinthAge::ArmyOrganisation.create!({:name => 'Army organisation', :army_id => army.id})

      unit_categories.each do |unit_category|

        organisation = NinthAge::Organisation.create!({:name => unit_category['name'], :army_id => army.id})

        organisation_group = NinthAge::OrganisationGroup.create!({army_organisation_id: army_organisation.id, organisation_id: organisation.id})
        if unit_category['min_quota'] != nil
          organisation_group.type_target = :Least
          organisation_group.target = unit_category['min_quota']
        elsif unit_category['max_quota'] != nil
          organisation_group.type_target = :Max
          organisation_group.target = unit_category['max_quota']
        end
        organisation_group.save

        NinthAge::Unit.where({army_id: army.id, unit_category_id: unit_category['id']}).each do |unit|

          unit.organisations << organisation
          unit.save

        end
      end
    end

    add_column :army_lists, :army_organisation_id, :integer, :default => 0, :null => true
    add_index :army_lists, :army_organisation_id

    ActiveRecord::Base.connection.execute('UPDATE army_lists
                                      SET army_organisation_id = (SELECT id FROM ninth_age_army_organisations WHERE army_lists.army_id = ninth_age_army_organisations.army_id)
                                      where army_organisation_id = 0;')

    add_foreign_key :army_lists, :ninth_age_army_organisations, column: :army_organisation_id, on_delete: :cascade

    remove_foreign_key :ninth_age_units, :unit_categories
    remove_index :ninth_age_units, :unit_category_id
    remove_column :ninth_age_units, :unit_category_id

    remove_index :army_list_units, :unit_category_id
    remove_column :army_list_units, :unit_category_id

    drop_table :unit_categories


    rename_table :army_lists,                       :builder_army_lists
    rename_table :army_list_units,                  :builder_army_list_units
    rename_table :army_list_units_extra_items,      :builder_army_list_unit_extra_items
    rename_table :army_list_units_magic_items,      :builder_army_list_unit_magic_items

    remove_foreign_key :army_list_units_magic_standards, :builder_army_list_units
    remove_index :army_list_units_magic_standards,  :army_list_unit_id
    remove_foreign_key :army_list_units_magic_standards, :ninth_age_magic_standards
    remove_index :army_list_units_magic_standards,  :magic_standard_id

    rename_table :army_list_units_magic_standards,  :builder_army_list_unit_magic_standards

    add_index :builder_army_list_unit_magic_standards, :army_list_unit_id, name: 'index_builder_armylistunit_magicstandards_on_armylistunit_id'
    add_foreign_key :builder_army_list_unit_magic_standards, :builder_army_list_units, column: :army_list_unit_id, on_delete: :cascade
    add_index :builder_army_list_unit_magic_standards, :magic_standard_id, name: 'index_builder_armylistunit_magicstandards_on_magicstandard_id'
    add_foreign_key :builder_army_list_unit_magic_standards, :ninth_age_magic_standards, column: :magic_standard_id, on_delete: :cascade

    rename_table :army_list_unit_troops,           :builder_army_list_unit_troops
    rename_table :army_list_units_unit_options,     :builder_army_list_unit_unit_options
  end
end
