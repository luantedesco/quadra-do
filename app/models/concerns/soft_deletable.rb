module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :actives, -> { where(deleted_at: nil) }
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
