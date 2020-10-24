class CreateTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :tokens, id: false, primary_key: :token do |t|
      t.string :token, null: false
      t.string :user_id, null: false

      t.timestamps
    end
  end
end
