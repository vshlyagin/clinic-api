class Patient < ApplicationRecord
  has_many :bmr_calculations, dependent: :destroy
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

  def age
    return unless birthday
    now = Date.today
    now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
  end

  def calculate_bmr(formula)
    case formula
    when "mifflin"
      base = 10 * weight + 6.25 * height - 5 * age
      gender ? base + 5 : base - 161
    when "harris"
      if gender
        66.473 + (13.752 * weight) + (5.003 * height) - (6.755 * age)
      else
        655.096 + (9.563 * weight) + (1.85 * height) - (4.679 * age)
      end
    else
      raise ArgumentError, "Unknown formula: #{formula}"
    end
  end
end