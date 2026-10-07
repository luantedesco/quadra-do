require "rails_helper"

RSpec.describe Web::Queries::Base do
  let(:query_class) do
    Class.new(described_class) do
      private

      def set_collection
        self.collection = List.actives
      end

      def set_filter
        self.collection = collection.where.not(name: "Arquivo")
      end

      def sort
        self.collection = collection.order(:position)
      end
    end
  end

  it "aplica coleção, filtro e ordem, e devolve a relation sem carregar" do
    second = create(:list, name: "Casa", position: 1)
    first = create(:list, name: "Trabalho", position: 0)
    create(:list, name: "Arquivo", position: 2)
    create(:list, name: "Apagada", position: 3).soft_delete!

    result = query_class.new.call

    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).not_to be_loaded
    expect(result.to_a).to eq([ first, second ])
  end
end
