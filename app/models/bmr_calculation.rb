class BmrCalculation < ApplicationRecord
  belongs_to :patient

  validates :formula, inclusion: { in: %w[mifflin harris] }
end
