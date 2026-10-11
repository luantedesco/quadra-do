module Web
  module Lists
    class UpdateService < Base
      private

      def run!
        instance.update!(list_params)
      end
    end
  end
end
