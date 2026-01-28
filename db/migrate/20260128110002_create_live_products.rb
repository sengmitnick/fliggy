class CreateLiveProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :live_products do |t|
      t.references :productable, polymorphic: true, null: false
      t.integer :position, default: 0
      t.string :live_room_name
      t.string :data_version, limit: 50, default: '0', null: false

      t.timestamps
    end

    add_index :live_products, :data_version
    add_index :live_products, :live_room_name
  end
end
