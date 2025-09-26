class CreatePatients < ActiveRecord::Migration[7.2]
  def change
    create_table :patients do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :middle_name
      t.date :birthday
      t.boolean :gender, null: false # true = мужской, false = женский
      t.integer :height
      t.integer :weight

      t.timestamps
    end

    add_index :patients, [:first_name, :last_name, :middle_name, :birthday], unique: true, name: "index_patients_on_name_and_birthday"
  end
end
