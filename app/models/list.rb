class List < ApplicationRecord
  include SoftDeletable

  has_many :tasks, -> { order(:position) }

  validates :name, presence: true

  def build_task(attributes = {})
    position = next_task_position
    tasks.build(attributes).tap { |task| task.position = position }
  end

  private

  def next_task_position
    last_position = tasks.actives.where(parent_id: nil).maximum(:position)
    last_position ? last_position + 1 : 0
  end
end
