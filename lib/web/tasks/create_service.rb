module Web
  module Tasks
    class CreateService < Base
      private

      # A tarefa nova entra no fim da ordem da lista.
      def set_instance
        list = List.actives.find(params.require(:task)[:list_id])
        self.instance = list.build_task(task_params)
      end

      def run!
        instance.save!
      end
    end
  end
end
