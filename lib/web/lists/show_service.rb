module Web
  module Lists
    class ShowService < Base
      private

      def set_response
        super.merge(sort: task_sort, tasks: tasks(:open), finished_tasks: tasks(:finished))
      end

      def tasks(scope)
        Web::Queries::Lists::TasksQuery.new(list: instance, task_sort:, scope:).call
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
