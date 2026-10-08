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

    it "mostra as tarefas abertas de topo na ordem, com prazo e prioridade, sem concluídas e apagadas" do
      list = create(:list)
      second = create(:task, list:, title: "Comprar café", position: 1, priority: :high, deadline: Time.zone.parse("2026-10-08 14:00"))
      first = create(:task, list:, title: "Revisar relatório", position: 0)
      create(:task, list:, title: "Concluída", position: 3, finished_at: Time.current)
      create(:task, list:, title: "Apagada", position: 4).soft_delete!

      get list_path(list)

      assert_select "#list-tasks .card-body > [data-id]", count: 2
      assert_select "#list-tasks .card-body > [data-id]:nth-of-type(1)[data-id=?]", first.id
      assert_select "#list-tasks [data-id=?]", second.id do
        assert_select ".ri-calendar-line"
        assert_select ".badge.badge-danger-lighten", text: "Alta"
      end
      assert_select "#list-tasks [data-id=?] .badge", first.id, count: 0
    end

    describe "subtarefas na tabela" do
      let(:list) { create(:list) }
      let!(:task) { create(:task, list:, title: "Revisar relatório") }
      let!(:second) { create(:task, list:, parent: task, title: "Passo B", position: 1) }
      let!(:first) { create(:task, list:, parent: task, title: "Passo A", position: 0) }
      let!(:nested) { create(:task, list:, parent: first, title: "Detalhe") }

      it "aparecem recolhidas sob a tarefa, na ordem, com a seta para mostrar" do
        create(:task, list:, parent: task, title: "Feita", finished_at: Time.current)

        get list_path(list)

        assert_select "#list-tasks .card-body > [data-id]", count: 1
        assert_select "[data-id=?] a.subtask-toggle[aria-expanded=false][href=?]", task.id, "#subtasks-#{task.id}"
        assert_select "#subtasks-#{task.id}.collapse:not(.show) > [data-id]", count: 2
        assert_select "#subtasks-#{task.id} > [data-id]:nth-of-type(1)[data-id=?]", first.id
        assert_select "#subtasks-#{first.id} > [data-id=?]", nested.id
        assert_select "#list-tasks a", text: "Feita", count: 0
      end

      it "abre as que estão guardadas no cookie" do
        cookies[:expanded_tasks] = [ task.id, first.id ].join(".")

        get list_path(list)

        assert_select "#subtasks-#{task.id}.collapse.show"
        assert_select "#subtasks-#{first.id}.collapse.show"
        assert_select "[data-id=?] a.subtask-toggle[aria-expanded=true]", task.id
      end

      it "não mostra as subtarefas de uma tarefa concluída" do
        task.finish!

        get list_path(list)

        assert_select "#list-tasks a", text: "Passo A", count: 0
      end

      it "agrupada, a subtarefa fica sob a tarefa, na seção dela" do
        first.update!(priority: :high)

        get list_path(list, group: "priority")

        assert_select "#list-tasks .list-section-high", count: 0
        assert_select "#list-tasks .list-section-none #subtasks-#{task.id} [data-id=?]", first.id
      end

      it "só a tarefa de topo tem a alça de arrastar" do
        get list_path(list)

        assert_select "#list-tasks .task-drag-handle", count: 1
        assert_select "[data-id=?] > .row .task-drag-handle", task.id
      end
    end

    it "mostra as concluídas de topo numa seção recolhida no fim, da mais recente para a mais antiga" do
      list = create(:list)
      older = create(:task, list:, title: "Antiga", finished_at: 2.days.ago)
      newer = create(:task, list:, title: "Recente", finished_at: 1.day.ago)
      create(:task, list:, title: "Subtarefa concluída", parent: older, finished_at: 1.hour.ago)
      create(:task, list:, title: "Aberta")

      get list_path(list)

      assert_select "#finished-tasks a[aria-expanded=false]", text: /Concluídas\s*\(2\)/
      assert_select "#finished-tasks-body.collapse:not(.show) [data-id]", count: 2
      assert_select "#finished-tasks-body [data-id]:nth-of-type(1)[data-id=?] .text-decoration-line-through", newer.id
    end

    it "não mostra a seção de concluídas quando não há nenhuma" do
      list = create(:list)
      create(:task, list:)

      get list_path(list)

      assert_select "#finished-tasks", count: 0
    end

    describe "ordenar por" do
      let(:list) { create(:list) }
      let!(:low) { create(:task, list:, title: "Baixa", position: 0, priority: :low) }
      let!(:high) { create(:task, list:, title: "Alta", position: 1, priority: :high) }

      it "ordena as abertas pela opção escolhida, marca a opção no menu e a lembra para a lista" do
        get list_path(list, sort: "priority")

        assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", high.id
        assert_select "#sort-menu .dropdown-item.active", text: "Prioridade"
        expect(cookies["list_sort_#{list.id}"]).to eq("priority")

        get list_path(list)

        assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", high.id
      end

      it "inverte a direção, marca no menu e a lembra junto com a ordem" do
        get list_path(list, sort: "priority", direction: "asc")

        assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", low.id
        assert_select "#sort-menu .dropdown-item.active", text: "Crescente"

        get list_path(list)

        assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", low.id
      end

      it "trocar de ordem sem direção volta à direção padrão dela" do
        get list_path(list, sort: "priority", direction: "asc")
        get list_path(list, sort: "priority")

        assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", high.id
        expect(cookies["list_direction_#{list.id}"]).to be_blank
      end

      it "não oferece direção na ordem personalizada" do
        get list_path(list)

        assert_select "#sort-menu .dropdown-item", text: "Crescente", count: 0
      end

      it "abre na ordem personalizada sem escolha e ignora opção desconhecida" do
        get list_path(list, sort: "qualquer")

        assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", low.id
        assert_select "#sort-menu .dropdown-item.active", text: "Personalizada"
        expect(cookies["list_sort_#{list.id}"]).to be_blank
      end
    end

    describe "agrupar por" do
      let(:list) { create(:list) }

      it "divide a tabela em seções com título e contagem, marca a opção no menu e a lembra para a lista" do
        high = create(:task, list:, priority: :high)
        create(:task, list:, priority: :none)

        get list_path(list, group: "priority")

        assert_select "#list-tasks .list-section-high h5", text: /Alta\s*\(1\)/
        assert_select "#list-tasks .list-section-high [data-id=?]", high.id
        assert_select "#list-tasks .list-section-none h5", text: /Nenhuma/
        assert_select "#list-tasks .list-section-medium", count: 0
        assert_select "#group-menu .dropdown-item.active", text: "Prioridade"

        get list_path(list)

        assert_select "#list-tasks .list-section-high"
      end

      it "mantém a ordenação escolhida ao trocar o agrupamento" do
        get list_path(list, sort: "title")
        get list_path(list, group: "deadline")

        assert_select "#sort-menu .dropdown-item.active", text: "Título"
        assert_select "#group-menu .dropdown-item.active", text: "Prazo"
      end
    end

    it "avisa quando a lista não tem tarefa aberta" do
      get list_path(create(:list))

      assert_select "#list-tasks", text: /Nenhuma tarefa aberta/
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
