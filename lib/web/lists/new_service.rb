module Web
  module Lists
    class NewService < Base
      private

      def set_instance
        self.instance = List.new
      end
    end
  end
end
