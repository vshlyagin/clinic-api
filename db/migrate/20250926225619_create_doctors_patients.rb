class CreateDoctorsPatients < ActiveRecord::Migration[7.2]
  def change
    create_join_table :doctors, :patients
  end
end
