module Web
  module Tasks
    class ToggleFinishService < Base
      private

      def run!
        instance.finished_at ? instance.reopen! : instance.finish!
      end
    end
  end
end
