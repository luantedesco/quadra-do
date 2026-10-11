require "rails_helper"

RSpec.describe "Painel", type: :request do
  describe "arrastar lista" do
    it "grava a lista na posição em que foi solta" do
      lists = Array.new(3) { |index| create(:list, position: index) }

      patch move_sidebar_path, params: { id: lists.last.id, index: 0 }, as: :json

      expect(response).to have_http_status(:ok)
      expect(List.actives.order(:position).pluck(:id)).to eq(lists.values_at(2, 0, 1).map(&:id))
    end

    it "responde 404 para lista apagada" do
      list = create(:list)
      list.soft_delete!

      patch move_sidebar_path, params: { id: list.id, index: 0 }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  it "liga o arrastar à lista do painel" do
    list = create(:list)

    get list_path(list)

    assert_select "#tasks-panel-lists[data-controller=sidebar-tree] li[data-id=?]", list.id
  end
end
