module Web
  module Lists
    class IndexService < Base
      private

      def set_response
        super.merge(lists: Web::Queries::Lists::IndexQuery.new.call)
      end
    end
  end
end
