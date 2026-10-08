module Web
  module Lists
    class Base < Web::Base
      private

      def klass
        List
      end

      def set_response
        super.merge(list: instance)
      end
    end
  end
end
