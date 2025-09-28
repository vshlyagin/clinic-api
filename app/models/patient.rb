class Patient < ApplicationRecord
  has_and_belongs_to_many :doctors

  scope :by_full_name, ->(name) {
    return all if name.blank?

    terms = name.split
    query = all
    terms.each do |term|
      query = query.where(
        "first_name ILIKE :q OR last_name ILIKE :q OR middle_name ILIKE :q",
        q: "%#{term}%"
      )
    end
    query
  }

  scope :by_gender, ->(gender) {
    return all if gender.nil?
    where(gender:)
  }

  scope :by_age, ->(start_age, end_age) {
    return all if start_age.blank? && end_age.blank?

    today = Date.today
    query = all

    if start_age.present?
      max_birthday = today - start_age.to_i.years
      query = query.where("birthday <= ?", max_birthday)
    end

    if end_age.present?
      min_birthday = today - end_age.to_i.years
      query = query.where("birthday >= ?", min_birthday)
    end

    query
  }
end