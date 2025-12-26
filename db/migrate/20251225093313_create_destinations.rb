class CreateDestinations < ActiveRecord::Migration[7.2]
  def change
    create_table :destinations do |t|
      t.string :name
      t.string :region
      t.text :description
      t.string :image_url
      t.boolean :is_hot, default: false


      t.timestamps
    end
  end
end
