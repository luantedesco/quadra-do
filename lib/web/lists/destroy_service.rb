module Web
  module Lists
    class DestroyService < Base
      private

      def run!
        instance.soft_delete!
      end
    end
  end
end
