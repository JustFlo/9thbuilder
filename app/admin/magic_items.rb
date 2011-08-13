ActiveAdmin.register MagicItem do
  controller do
    def create
      create! { new_admin_magic_item_url }
    end
  end

  action_item :only => :show do
    link_to "New Magic Item", new_admin_magic_item_path
  end

  index do
    column :id
    column :army, :sortable => :army_id
    column :magic_item_category, :sortable => :magic_item_category_id
    column :name
    column :value_points
    default_actions
  end
end