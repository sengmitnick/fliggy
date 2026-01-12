class CreateCountries < ActiveRecord::Migration[7.2]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :code
      t.string :slug
      t.string :region
      t.boolean :visa_free, default: false
      t.string :image_url
      t.text :description
      t.text :visa_requirements
      t.jsonb :statistics, default: {}


      t.timestamps
    end
  end
end
