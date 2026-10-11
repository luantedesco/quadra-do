module Web
  module Lists
    class IndexService < Base
      private

      # A raiz abre a primeira lista do painel; sem nenhuma, a tela convida a criar.
      def run!
        self.instance = Web::Queries::Lists::IndexQuery.new.call.first
      end
    end
  end
end
