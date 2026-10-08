module Web
  module Tasks
    class UpdateService < Base
      private

      def run!
        instance.update!(task_params)
      end
    end
  end
end
