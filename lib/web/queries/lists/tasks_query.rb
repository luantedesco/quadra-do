module Web
  module Queries
    module Lists
      # Tarefas abertas de uma lista na visão tabela, sem as subtarefas.
      class TasksQuery < Base
        attr_accessor :list

        def initialize(list:)
          super()
          self.list = list
        end

        private

        def set_collection
          self.collection = list.tasks.actives
        end

        def set_filter
          self.collection = collection.where(parent_id: nil, finished_at: nil)
        end

        def sort
          self.collection = collection.reorder(:position)
        end
      end
    end
  end
end
