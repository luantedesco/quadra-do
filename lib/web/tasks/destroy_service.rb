module Web
  module Tasks
    class DestroyService < Base
      private

      def run!
        instance.soft_delete!
      end
    end
  end
end
