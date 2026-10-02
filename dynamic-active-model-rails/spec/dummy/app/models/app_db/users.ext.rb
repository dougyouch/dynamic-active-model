# frozen_string_literal: true

update_model do
  def full_name
    "#{first_name} #{last_name}"
  end
end
