class CreateAbroadCoupons < ActiveRecord::Migration[7.2]
  def change
    create_table :abroad_coupons do |t|
      t.string :title
      t.integer :abroad_brand_id
      t.integer :abroad_shop_id
      t.string :discount_type
      t.string :discount_value
      t.text :description
      t.date :valid_from
      t.date :valid_until
      t.boolean :active, default: true


      t.timestamps
    end
  end
end
