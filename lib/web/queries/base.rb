module Web
  module Queries
    # Listagem da interface: set_collection -> set_filter -> sort; `call` devolve a relation.
    class Base
      attr_accessor :collection

      def initialize
        self.collection = nil
      end

      def call
        set_collection
        set_filter
        sort
        collection
      end

      private

      def set_collection
        nil
      end

      def set_filter
        nil
      end

      def sort
        nil
      end
    end
  end
end
