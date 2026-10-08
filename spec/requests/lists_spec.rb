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

  describe "criar, editar e apagar pelo painel" do
    it "abre o formulário de lista nova no modal" do
      get new_list_path, headers: { "Turbo-Frame" => "modal" }

      assert_select "turbo-frame#modal[target=_top] .modal form[action=?]", lists_path
    end

    it "cria a lista no fim do painel e abre ela" do
      create(:list, position: 4)

      post lists_path, params: { list: { name: "Casa", color: "#39afd1" } }

      list = List.find_by!(name: "Casa")
      expect(list).to have_attributes(color: "#39afd1", position: 5)
      expect(response).to redirect_to(list_path(list))
    end

    it "cria a lista sem cor quando \"Sem cor\" vem marcado, e o painel mostra a bolinha neutra" do
      post lists_path, params: { list: { name: "Casa", color: "#000000", no_color: "1" } }
      list = List.find_by!(name: "Casa")
      follow_redirect!

      expect(list.color).to be_nil
      assert_select "#tasks-panel-lists a[href=?] i.ri-circle-fill.text-muted:not([style])", list_path(list)
    end

    it "abre o formulário de lista nova com \"Sem cor\" marcado" do
      get new_list_path

      assert_select "#list_no_color[checked]"
    end

    it "não cria lista inválida e devolve o formulário com a mensagem no campo" do
      expect do
        post lists_path, params: { list: { name: "", color: "vermelho" } }
      end.not_to change(List, :count)

      expect(response).to have_http_status(:unprocessable_content)
      assert_select ".modal #list_name.is-invalid + .invalid-feedback", text: "Nome não pode ficar em branco"
      assert_select ".modal #list_color.is-invalid"
      assert_select ".modal .invalid-feedback.d-block", text: /Cor/
    end

    it "edita a lista e volta para ela" do
      list = create(:list, name: "Casa")

      patch list_path(list), params: { list: { name: "Lar" } }

      expect(list.reload.name).to eq("Lar")
      expect(response).to redirect_to(list_path(list))
    end

    it "tira a cor da lista na edição" do
      list = create(:list, color: "#39afd1")

      patch list_path(list), params: { list: { name: list.name, color: "#39afd1", no_color: "1" } }

      expect(list.reload.color).to be_nil
    end

    it "não salva a edição inválida e devolve o formulário" do
      list = create(:list, name: "Casa")

      patch list_path(list), params: { list: { name: "" } }

      expect(list.reload.name).to eq("Casa")
      expect(response).to have_http_status(:unprocessable_content)
      assert_select ".modal form[action=?] #list_name.is-invalid", list_path(list)
    end

    it "apaga a lista com as tarefas e volta para a raiz" do
      list = create(:list)
      task = create(:task, list:)

      delete list_path(list)

      expect([ list.reload.deleted_at, task.reload.deleted_at ]).to all(be_present)
      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
    end
  end
end
