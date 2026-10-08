require "rails_helper"

RSpec.describe "Tarefas", type: :request do
  describe "adicionar pelo título" do
    let(:list) { create(:list) }

    it "cria a tarefa no fim da lista e volta para ela com o campo focado" do
      create(:task, list:, position: 4)

      post tasks_path, params: { task: { list_id: list.id, title: "Comprar café", deadline: "2026-10-08T14:00" } }

      task = Task.find_by!(title: "Comprar café")
      expect(task).to have_attributes(list:, position: 5, deadline: Time.zone.parse("2026-10-08 14:00"))
      expect(response).to redirect_to(list_path(list))

      follow_redirect!
      assert_select "#task_title[autofocus]"
      assert_select "#list-tasks [data-id=?]", task.id
    end

    it "abre a lista sem o campo focado quando não veio de adicionar" do
      get list_path(list)

      assert_select "#task_title:not([autofocus])"
    end

    it "não cria tarefa sem título e mostra o erro abaixo do campo" do
      expect do
        post tasks_path, params: { task: { list_id: list.id, title: "" } }
      end.not_to change(Task, :count)

      follow_redirect!
      assert_select "form[action=?] .invalid-feedback", tasks_path, text: "Título não pode ficar em branco"
    end

    it "responde 404 para lista apagada" do
      list.soft_delete!

      post tasks_path, params: { task: { list_id: list.id, title: "Comprar café" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "painel da tarefa" do
    let(:list) { create(:list) }
    let(:task) { create(:task, list:, title: "Revisar relatório", description: "Ver os números", priority: :high) }

    it "abre a tarefa no frame da direita, com o fechar voltando para a tela de origem" do
      get task_path(task, from: list_path(list)), headers: { "Turbo-Frame" => "task_detail" }

      assert_select "turbo-frame#task_detail #task-detail" do
        assert_select "#detail_task_title[value=?]", "Revisar relatório"
        assert_select "#detail_task_priority option[selected][value=high]", text: "Alta"
        assert_select "#detail_task_description", text: "Ver os números"
        assert_select "a[data-turbo-frame=_top][href=?]", list_path(list)
      end
    end

    it "acesso direto volta para a lista com o painel carregando a tarefa" do
      get task_path(task)

      expect(response).to redirect_to("#{list_path(list)}?task=#{task.id}")

      follow_redirect!
      assert_select "turbo-frame#task_detail[src=?]", task_path(task, from: list_path(list))
    end

    it "ignora a tela de origem que não é do app" do
      get task_path(task, from: "https://exemplo.com/roubo"), headers: { "Turbo-Frame" => "task_detail" }

      assert_select "#task-detail a[data-turbo-frame=_top][href=?]", list_path(list)
    end

    it "responde 404 para tarefa apagada" do
      task.soft_delete!

      get task_path(task), headers: { "Turbo-Frame" => "task_detail" }

      expect(response).to have_http_status(:not_found)
    end

    it "liga o título da linha ao painel, avançando a URL" do
      task

      get list_path(list)

      assert_select "#list-tasks a[href=?][data-turbo-frame=task_detail][data-turbo-action=advance]", task_path(task, from: list_path(list)), text: "Revisar relatório"
      assert_select "turbo-frame#task_detail:not([src])"
    end
  end

  describe "editar no painel" do
    let(:task) { create(:task, title: "Revisar relatório") }

    it "salva título, descrição, prazo e prioridade e responde com o refresh da página, sem o request-id" do
      patch task_path(task), params: { task: { title: "Revisar o relatório", description: "Ver os números", deadline: "2026-10-09T14:00", priority: "medium" } }, as: :turbo_stream

      expect(task.reload).to have_attributes(title: "Revisar o relatório", description: "Ver os números", deadline: Time.zone.parse("2026-10-09 14:00"), priority: "medium")
      assert_turbo_stream action: :refresh
      expect(response.body).not_to include("request-id")
    end

    it "não salva título vazio e troca o painel com o erro embaixo do campo" do
      patch task_path(task), params: { task: { title: "" } }, as: :turbo_stream

      expect(task.reload.title).to eq("Revisar relatório")
      expect(response).to have_http_status(:unprocessable_content)
      assert_turbo_stream(action: :replace, target: "task-detail") do
        assert_select "#detail_task_title.is-invalid + .invalid-feedback", text: "Título não pode ficar em branco"
      end
    end

    it "recusa prioridade fora da lista como erro de validação, sem erro 500" do
      patch task_path(task), params: { task: { priority: "urgente" } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(task.reload).to be_priority_none
    end
  end

  describe "mover para outra lista" do
    let(:origin) { create(:list) }
    let(:destination) { create(:list, name: "Casa") }
    let(:task) { create(:task, list: origin) }

    it "leva a tarefa com as subtarefas para o fim da lista nova e responde com o refresh da página" do
      create(:task, list: destination, position: 4)
      subtask = create(:task, list: origin, parent: task)

      patch move_to_list_task_path(task), params: { task: { list_id: destination.id } }, as: :turbo_stream

      expect(task.reload).to have_attributes(list: destination, position: 5)
      expect(subtask.reload.list).to eq(destination)
      assert_turbo_stream action: :refresh

      get list_path(origin)
      assert_select "#list-tasks [data-id=?]", task.id, count: 0
    end

    it "recusa mover subtarefa sozinha" do
      subtask = create(:task, list: origin, parent: task)

      patch move_to_list_task_path(subtask), params: { task: { list_id: destination.id } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(subtask.reload.list).to eq(origin)
    end

    it "responde 404 para lista apagada" do
      destination.soft_delete!

      patch move_to_list_task_path(task), params: { task: { list_id: destination.id } }, as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "subtarefas no painel" do
    let(:list) { create(:list) }
    let(:task) { create(:task, list:, title: "Revisar relatório") }

    it "cria a subtarefa no fim das subtarefas e responde com o refresh, sem fechar o painel" do
      post tasks_path, params: { task: { parent_id: task.id, title: "Ver os números" } }, as: :turbo_stream

      subtask = task.subtasks.find_by!(title: "Ver os números")
      expect(subtask).to have_attributes(list:, position: 0)
      assert_turbo_stream action: :refresh
      expect(response.body).not_to include("request-id")
    end

    it "apaga a subtarefa e responde com o refresh" do
      subtask = create(:task, list:, parent: task)

      delete task_path(subtask), as: :turbo_stream

      expect(subtask.reload.deleted_at).to be_present
      assert_turbo_stream action: :refresh
    end

    it "lista as subtarefas ativas com a contagem de concluídas, o concluir, o apagar e o campo de criar" do
      done = create(:task, list:, parent: task, title: "Passo 1", position: 0, finished_at: Time.current)
      create(:task, list:, parent: task, title: "Passo 2", position: 1)
      create(:task, list:, parent: task, title: "Apagada", position: 2).soft_delete!

      get task_path(task, from: list_path(list)), headers: { "Turbo-Frame" => "task_detail" }

      assert_select "#task-subtasks" do
        assert_select "h5 span", text: "1/2"
        assert_select "##{ActionView::RecordIdentifier.dom_id(done)} input[type=checkbox][checked]"
        assert_select "a[href=?][data-turbo-frame=task_detail]", task_path(done, from: list_path(list)), text: "Passo 1"
        assert_select "a[href=?][data-turbo-method=delete]", task_path(done)
        assert_select "a", text: "Apagada", count: 0
        assert_select "form[action=?] input[name='task[parent_id]'][value=?]", tasks_path, task.id
      end
    end

    it "abre a subtarefa no painel com o link para a tarefa pai e o bloco das subtarefas dela" do
      subtask = create(:task, list:, parent: task)

      get task_path(subtask, from: list_path(list)), headers: { "Turbo-Frame" => "task_detail" }

      assert_select "#task-detail a[href=?]", task_path(task, from: list_path(list)), text: /Revisar relatório/
      assert_select "#task-subtasks form input[name='task[parent_id]'][value=?]", subtask.id
    end

    it "no 5º nível de subtarefa, não oferece criar mais" do
      deepest = 5.times.reduce(task) { |current, _| create(:task, list:, parent: current) }

      get task_path(deepest), headers: { "Turbo-Frame" => "task_detail" }

      assert_select "#task-subtasks", count: 0
    end
  end

  describe "concluir e reabrir" do
    let(:list) { create(:list) }
    let(:task) { create(:task, list:) }

    it "conclui a tarefa aberta e responde com o refresh da página, sem o request-id" do
      patch toggle_finish_task_path(task), as: :turbo_stream

      expect(task.reload.finished_at).to be_present
      assert_turbo_stream action: :refresh
      expect(response.body).not_to include("request-id")
    end

    it "reabre a tarefa concluída" do
      task.finish!

      patch toggle_finish_task_path(task), as: :turbo_stream

      expect(task.reload.finished_at).to be_nil
    end

    it "põe o checkbox na linha e no painel, marcado na concluída" do
      task.finish!

      get list_path(list)
      assert_select "#finished-tasks form[action=?] input[type=checkbox][checked]", toggle_finish_task_path(task)

      get task_path(task), headers: { "Turbo-Frame" => "task_detail" }
      assert_select "#task-detail form[action=?] input[type=checkbox][checked]", toggle_finish_task_path(task)
    end
  end

  describe "arrastar" do
    include ActiveSupport::Testing::TimeHelpers

    let(:list) { create(:list) }
    let!(:tasks) { Array.new(3) { |index| create(:task, list:, position: index) } }

    it "na ordem personalizada, encaixa a tarefa entre os vizinhos, e a ordem continua igual ao recarregar" do
      patch move_task_path(tasks.last), params: { group: "none", following_id: tasks.first.id }, as: :json

      expect(response).to have_http_status(:ok)
      get list_path(list)
      assert_select "#list-tasks [data-id]:nth-of-type(1)[data-id=?]", tasks.last.id
    end

    it "solta em outra seção de prioridade, muda a prioridade" do
      patch move_task_path(tasks.first), params: { group: "priority", section: "high" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(tasks.first.reload).to be_priority_high
    end

    it "solta em Amanhã, a tarefa sem prazo vale o dia inteiro" do
      travel_to Time.zone.parse("2026-10-08 10:00") do
        patch move_task_path(tasks.first), params: { group: "deadline", section: "tomorrow" }, as: :json

        expect(tasks.first.reload.deadline).to eq(Time.zone.parse("2026-10-09 23:59"))
      end
    end

    it "recusa soltar numa faixa de prazo, sem mudar a tarefa" do
      patch move_task_path(tasks.first), params: { group: "deadline", section: "overdue" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(tasks.first.reload.deadline).to be_nil
    end

    it "responde 404 para tarefa apagada" do
      tasks.first.soft_delete!

      patch move_task_path(tasks.first), params: { group: "none", previous_id: tasks.last.id }, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "põe a alça em toda tarefa aberta, e marca as seções que recebem tarefa e se a ordem é a personalizada" do
      tasks.first.finish!

      get list_path(list, sort: "title", group: "deadline")

      assert_select "#list-tasks[data-controller~=task-sort][data-task-sort-reorder-value=false][data-task-sort-group-value=deadline][data-task-sort-list-value=?]", list.id
      assert_select "#list-tasks .task-drag-handle", count: 2
      assert_select "#finished-tasks .task-drag-handle", count: 0
      assert_select "#list-tasks [data-section=no_deadline][data-droppable=true]"
    end
  end
end
