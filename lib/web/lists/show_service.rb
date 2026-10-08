module Web
  module Lists
    class ShowService < Base
      private

      def set_response
        super.merge(tasks: tasks(:open), finished_tasks: tasks(:finished))
      end

      def tasks(scope)
        Web::Queries::Lists::TasksQuery.new(list: instance, scope:).call
      end
    end
  end
end
