class CreateCities < ActiveRecord::Migration[7.2]
  def change
    create_table :cities do |t|
      t.string :name
      t.string :pinyin
      t.string :airport_code
      t.string :region
      t.boolean :is_hot, default: false

      t.timestamps
    end
    
    add_index :cities, :name, unique: true
    add_index :cities, :pinyin
    add_index :cities, :is_hot
  end
end
