require "rails_helper"

RSpec.describe "Listas", type: :request do
  describe "raiz" do
    it "abre a primeira lista ativa do painel" do
      create(:list, name: "Casa", position: 1)
      create(:list, name: "Apagada", position: 0).soft_delete!
      first = create(:list, name: "Trabalho", position: 0)

      get root_path

      expect(response).to redirect_to(list_path(first))
    end

    it "sem nenhuma lista, mostra o convite para criar a primeira" do
      get root_path

      expect(response).to have_http_status(:ok)
      assert_select ".content-page", text: /Nenhuma lista ainda/
      assert_select "#tasks-panel"
    end
  end

  describe "página da lista" do
    it "abre com o nome no título e o painel com as listas ativas na ordem, marcando a aberta" do
      casa = create(:list, name: "Casa", position: 1)
      trabalho = create(:list, name: "Trabalho", position: 0)
      create(:list, name: "Apagada", position: 2).soft_delete!

      get list_path(casa)

      assert_select "title", text: "Casa · Quadra Do"
      assert_select ".page-title", text: "Casa"
      assert_select "#tasks-panel-lists li", count: 2
      assert_select "#tasks-panel-lists li:nth-of-type(1) a[href=?]", list_path(trabalho)
      assert_select "#tasks-panel-lists li.active a[href=?]", list_path(casa)
    end

    it "responde 404 para lista apagada" do
      list = create(:list)
      list.soft_delete!

      get list_path(list)

      expect(response).to have_http_status(:not_found)
    end
  end
end
