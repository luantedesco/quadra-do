module Web
  module Queries
    module Lists
      class IndexQuery < Base
        private

        def set_collection
          self.collection = List.actives
        end

        def sort
          self.collection = collection.order(:position)
        end
      end
    end
  end
end
