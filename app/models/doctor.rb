class Doctor < ApplicationRecord
  has_and_belongs_to_many :patients

  self.record_timestamps = false
end