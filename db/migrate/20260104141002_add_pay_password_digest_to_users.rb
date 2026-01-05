class AddPayPasswordDigestToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :pay_password_digest, :string

  end
end
