class CreateAttractionReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :attraction_reviews do |t|
      t.references :attraction
      t.references :user
      t.decimal :rating, default: 5.0
      t.text :comment
      t.boolean :is_featured, default: false
      t.integer :helpful_count, default: 0


      t.timestamps
    end
  end
end
