class AddPassword < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :digest_password, :string, null: false
  end
end
