class CreateLiveProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :live_products do |t|
      t.references :productable, polymorphic: true
      t.integer :position, default: 0
      t.string :live_room_name


      t.timestamps
    end
  end
end
