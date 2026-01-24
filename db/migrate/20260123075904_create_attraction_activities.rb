class CreateAttractionActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :attraction_activities do |t|
      t.references :attraction
      t.string :name
      t.string :activity_type, default: "experience"
      t.decimal :original_price
      t.decimal :current_price
      t.string :discount_info
      t.string :refund_policy
      t.text :description
      t.string :duration
      t.integer :sales_count, default: 0


      t.timestamps
    end
  end
end
