module Web
  module Queries
    module Lists
      # Tarefas de topo de uma lista na visão tabela: abertas na ordem escolhida (`:open`) ou concluídas
      # da mais recente para a mais antiga (`:finished`).
      class TasksQuery < Base
        attr_accessor :list, :task_sort, :scope

        def initialize(list:, task_sort: Core::Domain::TaskSort.new(nil), scope: :open)
          super()
          self.list = list
          self.task_sort = task_sort
          self.scope = scope
        end

        private

        def set_collection
          self.collection = list.tasks.actives.where(parent_id: nil)
        end

        def set_filter
          self.collection = scope == :finished ? collection.where.not(finished_at: nil) : collection.where(finished_at: nil)
        end

        def sort
          self.collection = scope == :finished ? collection.reorder(finished_at: :desc) : collection.reorder(task_sort.order)
        end
      end
    end
  end
end
