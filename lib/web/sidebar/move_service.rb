module Web
  module Sidebar
    # Arrastar no painel: a lista vai para a posição em que foi solta.
    class MoveService < Web::Base
      private

      def klass
        List
      end

      def run!
        instance.move_to!(params[:index].to_i)
      end
    end
  end
end
