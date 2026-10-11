class CreateLists < ActiveRecord::Migration[8.1]
  def change
    create_table :lists, id: :uuid do |t|
      t.string :name, null: false
      t.string :color
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
