# frozen_string_literal: true

update_model do
  scope :by_make, ->(name) { joins(:make).where(makes: { name: name }) }
end
