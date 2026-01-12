class CreateUserCoupons < ActiveRecord::Migration[7.2]
  def change
    create_table :user_coupons do |t|
      t.integer :user_id
      t.integer :abroad_coupon_id
      t.string :status, default: "unclaimed"
      t.datetime :claimed_at
      t.datetime :used_at
      t.datetime :expires_at


      t.timestamps
    end
  end
end
