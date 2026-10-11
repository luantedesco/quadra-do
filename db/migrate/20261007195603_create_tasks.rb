class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.integer :priority, null: false, default: 0
      t.datetime :deadline
      t.datetime :finished_at
      t.integer :position, null: false, default: 0
      t.references :list, null: false, foreign_key: true, type: :uuid
      t.references :parent, foreign_key: { to_table: :tasks }, type: :uuid
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :tasks, :deadline
  end
end
