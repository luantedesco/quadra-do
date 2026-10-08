class Task < ApplicationRecord
  include SoftDeletable

  belongs_to :list
  belongs_to :parent, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: :parent_id, inverse_of: :parent

  # Subtarefas vão até 5 níveis abaixo da tarefa de topo.
  MAX_DEPTH = 5

  enum :priority, { none: 0, low: 1, medium: 2, high: 3 }, prefix: true, validate: true

  validates :title, presence: true
  # Só quando a tarefa ganha pai ou muda de lista: reordenar irmãs não reconfere a árvore.
  validate :parent_must_be_in_same_list, :parent_must_not_be_descendant, :tree_within_max_depth, if: :parent_changing?

  # Subtarefa nova entra na lista da tarefa e no fim da ordem das subtarefas dela.
  def build_subtask(attributes = {})
    position = subtasks.actives.maximum(:position)&.succ || 0
    subtasks.build(attributes).tap do |subtask|
      subtask.list = list
      subtask.position = position
    end
  end

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
      move_subtasks_to!(new_list)
    end
  end

  # Nível da tarefa: 0 na de topo, 1 na subtarefa dela, e assim por diante.
  def depth
    parent ? parent.depth + 1 : 0
  end

  def accepts_subtasks?
    depth < MAX_DEPTH
  end

  # Quantos níveis de subtarefas ativas há abaixo da tarefa.
  def subtree_height
    subtasks.actives.map { |subtask| subtask.subtree_height + 1 }.max || 0
  end

  def soft_delete!
    transaction do
      subtasks.actives.each(&:soft_delete!)
      super
    end
  end

  protected

  # A árvore inteira acompanha a tarefa, de cima para baixo: cada filha muda depois da mãe.
  def move_subtasks_to!(new_list)
    subtasks.actives.each do |subtask|
      subtask.update!(list: new_list)
      subtask.move_subtasks_to!(new_list)
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

  def parent_changing?
    parent_id? && (new_record? || will_save_change_to_parent_id? || will_save_change_to_list_id?)
  end

  def parent_must_not_be_descendant
    ancestor = parent
    while ancestor
      return errors.add(:parent, :invalid) if ancestor.id == id

      ancestor = ancestor.parent
    end
  end

  # A tarefa e as subtarefas dela, somadas à profundidade do pai novo, cabem nos 5 níveis. Pai já
  # recusado (ciclo) não tem profundidade para medir.
  def tree_within_max_depth
    return if errors.include?(:parent)

    errors.add(:parent, :invalid) if parent.depth + 1 + (new_record? ? 0 : subtree_height) > MAX_DEPTH
  end
end
