module Web
  module Queries
    module Lists
      # Tarefas de uma lista na visão tabela: as abertas de todos os níveis na ordem escolhida (`:open`),
      # para montar a árvore de uma vez, ou as concluídas de topo da mais recente para a mais antiga
      # (`:finished`).
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
          self.collection = list.tasks.actives
        end

        def set_filter
          self.collection = if scope == :finished
            collection.where(parent_id: nil).where.not(finished_at: nil)
          else
            collection.where(finished_at: nil)
          end
        end

        def sort
          self.collection = scope == :finished ? collection.reorder(finished_at: :desc) : collection.reorder(task_sort.order)
        end
      end
    end
  end
end
