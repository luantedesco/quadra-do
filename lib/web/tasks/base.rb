module Web
  module Tasks
    class Base < Web::Base
      private

      def klass
        Task
      end

      def set_response
        super.merge(task: instance)
      end

      def task_params
        params.require(:task).permit(:title, :deadline)
      end
    end
  end
end
