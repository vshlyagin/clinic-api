class CreateBmrCalculations < ActiveRecord::Migration[7.2]
  def change
    create_table :bmr_calculations do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :formula, null: false
      t.float :result, null: false

      t.timestamps
    end
  end
end
