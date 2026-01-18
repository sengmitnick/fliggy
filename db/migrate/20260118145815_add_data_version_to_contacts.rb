class AddDataVersionToContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :contacts, :data_version, :integer, default: 1

  end
end
