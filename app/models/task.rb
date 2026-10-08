class Task < ApplicationRecord
  include SoftDeletable

  belongs_to :list
  belongs_to :parent, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: :parent_id, inverse_of: :parent

  enum :priority, { none: 0, low: 1, medium: 2, high: 3 }, prefix: true, validate: true

  validates :title, presence: true
  validate :parent_must_be_in_same_list, :subtask_must_be_one_level, if: :parent_id?

  def finish!
    update!(finished_at: Time.current)
  end

  def reopen!
    update!(finished_at: nil)
  end

  def move_to!(position)
    transaction do
      ordered = siblings.where.not(id:).to_a
      ordered.insert(position.clamp(0, ordered.size), self)
      ordered.each_with_index { |task, index| task.update!(position: index) }
    end
  end

  # Encaixa a tarefa logo depois de `previous` ou, sem ele, logo antes de `following`; sem nenhum dos
  # dois, a posição não muda.
  def move_beside!(previous: nil, following: nil)
    ids = siblings.where.not(id:).pluck(:id)
    index = previous ? ids.index(previous.id)&.succ : following && ids.index(following.id)
    move_to!(index) if index
  end

    def move_to_list!(new_list)
    transaction do
      update!(list: new_list, position: new_list.next_task_position)
      subtasks.actives.each { |subtask| subtask.update!(list: new_list) }
    end
  end

  def soft_delete!
    transaction do
      subtasks.actives.each(&:soft_delete!)
      super
    end
  end

  private

  # Só as abertas: a concluída sai da ordem da lista e mantém a posição que tinha.
  def siblings
    list.tasks.actives.where(parent_id:, finished_at: nil)
  end

  def parent_must_be_in_same_list
    errors.add(:parent, :invalid) unless parent.list_id == list_id
  end

  def subtask_must_be_one_level
    errors.add(:parent, :invalid) if parent.parent_id.present? || subtasks.exists?
  end
end
