class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users, id: false, primary_key: :id do |t|
      t.string :id, null: false, primary_key: true, unique: true
      t.string :name, null: false, unique: true
    end
  end
end
