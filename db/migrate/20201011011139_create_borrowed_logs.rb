class CreateBorrowedLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :borrowed_logs do |t|
      t.string :book_id, null: false
      t.string :user_id, null: false

      t.timestamps
    end
  end
end
