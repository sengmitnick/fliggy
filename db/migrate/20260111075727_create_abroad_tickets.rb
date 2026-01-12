class CreateAbroadTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :abroad_tickets do |t|
      t.string :region, default: "japan"
      t.string :ticket_type, default: "train"
      t.string :origin
      t.string :destination
      t.date :departure_date
      t.string :time_slot_start
      t.string :time_slot_end
      t.decimal :price, default: 0
      t.string :seat_type
      t.string :status, default: "available"
      t.string :origin_en
      t.string :destination_en


      t.timestamps
    end
  end
end
