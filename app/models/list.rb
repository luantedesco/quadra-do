class List < ApplicationRecord
  include SoftDeletable

  has_many :tasks, -> { order(:position) }

  validates :name, presence: true
  validates :color, format: { with: /\A#\h{6}\z/ }, allow_blank: true

  # Lista nova entra no fim do painel.
  def self.next_position
    last_position = actives.maximum(:position)
    last_position ? last_position + 1 : 0
  end

  def build_task(attributes = {})
    position = next_task_position
    tasks.build(attributes).tap { |task| task.position = position }
  end

  # Leva a lista para a posição pedida no painel e renumera as listas ativas a partir de 0.
  def move_to!(position)
    transaction do
      ordered = List.actives.order(:position).where.not(id:).to_a
      ordered.insert(position.clamp(0, ordered.size), self)
      ordered.each_with_index { |list, index| list.update!(position: index) }
    end
  end

  # Apaga também as tarefas; cada tarefa de topo leva as subtarefas dela.
  def soft_delete!
    transaction do
      tasks.actives.where(parent_id: nil).each(&:soft_delete!)
      super
    end
  end

  def next_task_position
    last_position = tasks.actives.where(parent_id: nil).maximum(:position)
    last_position ? last_position + 1 : 0
  end
end
