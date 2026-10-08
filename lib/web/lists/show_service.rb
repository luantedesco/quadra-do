module Web
  module Lists
    class ShowService < Base
      private

      def set_response
        super.merge(tasks: Web::Queries::Lists::TasksQuery.new(list: instance).call)
      end
    end
  end
end
