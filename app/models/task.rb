class Task < ApplicationRecord
  include SoftDeletable

  belongs_to :list
end
