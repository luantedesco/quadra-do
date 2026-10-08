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
end
