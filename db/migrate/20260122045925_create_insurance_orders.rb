class CreateInsuranceOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :insurance_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :insurance_product, null: false, foreign_key: true
      
      t.string :order_number, null: false
      t.string :source, default: 'standalone'
      
      # 保险期间
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :days, null: false
      
      # 目的地信息
      t.string :destination
      t.string :destination_type
      
      # 被保险人信息
      t.jsonb :insured_persons, default: []
      
      # 订单金额
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.integer :quantity, default: 1
      t.decimal :total_price, precision: 10, scale: 2, null: false
      
      # 订单状态
      t.string :status, default: 'pending'
      t.datetime :paid_at
      
      # 关联的旅行订单（polymorphic）
      t.references :related_booking, polymorphic: true, null: true
      
      # 保单信息
      t.string :policy_number
      t.text :policy_file_url

      t.timestamps
    end
    
    add_index :insurance_orders, :order_number, unique: true
    add_index :insurance_orders, [:user_id, :status]
    add_index :insurance_orders, :start_date
  end
end
