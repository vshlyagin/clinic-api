ActiveRecord::Schema[7.2].define(version: 2025_09_26_225619) do
  enable_extension "plpgsql"

  create_table "doctors", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_name"
  end

  create_table "doctors_patients", id: false, force: :cascade do |t|
    t.bigint "doctor_id", null: false
    t.bigint "patient_id", null: false
  end

  create_table "patients", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_name"
    t.date "birthday"
    t.boolean "gender", null: false
    t.integer "height"
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["first_name", "last_name", "middle_name", "birthday"], name: "index_patients_on_name_and_birthday", unique: true
  end
end
