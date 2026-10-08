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
        assert_select "h4", text: "Revisar relatório"
        assert_select ".badge", text: "Alta"
        assert_select "p", text: "Ver os números"
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

      assert_select "#list-tasks[data-controller=task-sort][data-task-sort-reorder-value=false][data-task-sort-group-value=deadline]"
      assert_select "#list-tasks .task-drag-handle", count: 2
      assert_select "#finished-tasks .task-drag-handle", count: 0
      assert_select "#list-tasks [data-section=no_deadline][data-droppable=true]"
    end
  end
end
