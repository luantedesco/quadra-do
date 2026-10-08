module Web
  module Tasks
    # Leva a tarefa para o fim da lista do painel em que ela foi solta, com as subtarefas; subtarefa
    # segue o pai e não muda de lista sozinha.
    class MoveToListService < Base
      private

      def validate!
        raise Core::Errors::ValidationError, I18n.t("tasks.move_to_list.sub_task") if instance.parent_id?
      end

      def run!
        instance.move_to_list!(List.actives.find(params.require(:task)[:list_id]))
      end
    end
  end
end
