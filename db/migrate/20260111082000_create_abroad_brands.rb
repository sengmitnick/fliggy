class CreateAbroadBrands < ActiveRecord::Migration[7.2]
  def change
    create_table :abroad_brands do |t|
      t.string :name
      t.string :slug
      t.string :country
      t.string :logo_url
      t.text :description
      t.string :category, default: "duty_free"
      t.boolean :featured, default: false


      t.timestamps
    end
  end
end
