class AddHasMagicColumnsTables < ActiveRecord::Migration
  def change
    create_table :magic_columns do |t|
      t.column :name,           :string
      t.column :pretty_name,    :string
      t.column :pretty_name_cn,    :string
      t.column :datatype,       :string, :default => "string"
      t.column :default,        :string
      t.column :is_required,    :boolean, :default => false
      t.column :include_blank,  :boolean, :default => false
      t.column :allow_other,    :boolean, :default => true
      t.column :type_scoped,    :string
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end

    create_table :magic_attributes do |t|
      t.column :magic_column_id, :integer
      t.column :value, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end


    create_table :magic_column_relationships do |t|
      t.column :magic_column_id, :integer
      t.column :owner_id, :integer
      t.column :owner_type, :string
      t.column :name, :string
      t.column :type_scoped,   :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :magic_attribute_relationships do |t|
      t.column :magic_attribute_id, :integer
      t.column :owner_id, :integer
      t.column :owner_type, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :magic_attribute_relationships, [:magic_attribute_id, :owner_id, :owner_type], name:"magic_attribute_id_owner", :unique => true
    add_index :magic_column_relationships, [:magic_column_id, :owner_id, :owner_type], name:"magic_column_id_owner", :unique => true
    add_index :magic_column_relationships, [:name, :type_scoped, :owner_id, :owner_type], name:"magic_column_name_owner", :unique => true
  end

end
