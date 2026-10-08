module Web
  module Lists
    class CreateService < Base
      private

      def set_instance
        self.instance = List.new(list_params.merge(position: List.next_position))
      end

      def run!
        instance.save!
      end
    end
  end
end
