module Web
  module Tasks
    class CreateService < Base
      private

      # A tarefa nova entra no fim da ordem da lista; a subtarefa, no fim das subtarefas da tarefa pai.
      def set_instance
        parent_id, list_id = params.require(:task).values_at(:parent_id, :list_id)
        self.instance = if parent_id.present?
          Task.actives.find(parent_id).build_subtask(task_params)
        else
          List.actives.find(list_id).build_task(task_params)
        end
      end

      def run!
        instance.save!
      end
    end
  end
end
