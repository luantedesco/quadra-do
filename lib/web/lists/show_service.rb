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

      # A ordem pedida no menu ou, sem ela, a lembrada no cookie da lista.
      def task_sort
        @task_sort ||= Core::Domain::TaskSort.new(params[:sort].presence || cookies["list_sort_#{instance.id}"])
      end
    end
  end
end
