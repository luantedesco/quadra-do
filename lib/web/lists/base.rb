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

      # "Sem cor" marcado limpa a cor: o seletor do navegador sempre envia uma.
      def list_params
        attributes = params.require(:list).permit(:name, :color)
        attributes[:color] = nil if params.dig(:list, :no_color) == "1"
        attributes
      end
    end
  end
end
