class CreateFamilyCoupons < ActiveRecord::Migration[7.2]
  def change
    create_table :family_coupons do |t|
      t.string :title
      t.string :coupon_type
      t.decimal :amount
      t.date :valid_until
      t.string :status, default: "available"
      t.text :description


      t.timestamps
    end
  end
end
