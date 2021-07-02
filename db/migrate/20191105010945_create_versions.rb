class CreateVersions < ActiveRecord::Migration[6.0]
  def change
    create_table :versions do |t|
      t.references :model, polymorphic: true
      t.text :current
      t.text :diff

      t.timestamps
    end
  end
end
