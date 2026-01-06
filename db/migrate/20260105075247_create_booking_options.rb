class CreateBookingOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :booking_options do |t|
      t.references :train
      t.string :title
      t.text :description
      t.decimal :extra_fee, default: 0
      t.text :benefits
      t.integer :priority, default: 0
      t.boolean :is_active, default: true


      t.timestamps
    end
  end
end
