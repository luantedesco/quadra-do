module Web
  module Lists
    class ShowService < Base
      private

      # As abertas de topo vão para as seções; as subtarefas abertas ficam por pai, para a tabela
      # desenhar a árvore. Filha de pai concluído não tem caminho até o topo, e não aparece.
      def set_response
        open_tasks = tasks(:open).group_by(&:parent_id)
        super.merge(
          sort: task_sort,
          group: task_group,
          sections: task_group.sections(open_tasks.fetch(nil, [])),
          subtasks: open_tasks,
          expanded: expanded_tasks,
          finished_tasks: tasks(:finished)
        )
      end

      def tasks(scope)
        Web::Queries::Lists::TasksQuery.new(list: instance, task_sort:, scope:).call
      end

      # Tarefas com as subtarefas abertas na tabela, guardadas em cookie pelo controller subtask-toggle;
      # sem cookie, todas recolhidas.
      def expanded_tasks
        cookies["expanded_tasks"].to_s.split(".").to_set
      end

      # O agrupamento pedido no menu ou, sem ele, o lembrado no cookie da lista.
      def task_group
        @task_group ||= Core::Domain::TaskGroup.new(params[:group].presence || cookies["list_group_#{instance.id}"])
      end

      # A ordem e a direção pedidas no menu ou, sem elas, as lembradas no cookie da lista.
      def task_sort
        @task_sort ||= if params[:sort].present?
          Core::Domain::TaskSort.new(params[:sort], params[:direction])
        else
          Core::Domain::TaskSort.new(cookies["list_sort_#{instance.id}"], cookies["list_direction_#{instance.id}"])
        end
      end
    end
  end
end
