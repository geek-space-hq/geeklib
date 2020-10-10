class CreateBooks < ActiveRecord::Migration[6.0]
  def change
    create_table :books, id: false, primary_key: :id do |t|
      t.string :id, null: false, primary_key: true, unique: true
      t.string :title, null: false
      t.string :author, null: false
      t.string :status, null: false, default: 'available'
    end
  end
end
