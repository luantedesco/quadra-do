class TasksController < ApplicationController
  layout -> { turbo_frame_request? ? "turbo_rails/frame" : "application" }
  helper_method :task_return_path

  service_actions :show, :create, :update, :destroy, :move, :toggle_finish, :move_to_list

  private

  # O painel da tarefa abre num turbo-frame; acesso direto (link copiado, recarregar) volta para a tela
  # de origem com o painel aberto.
  def show_redirect
    redirect_to "#{return_path}?task=#{@task.id}" unless turbo_frame_request?
  end

  def create_redirect
    render status: :unprocessable_content if @error
  end

  # Com erro, o painel volta com a mensagem no campo.
  def update_redirect
    render status: :unprocessable_content if @error
  end

  # A tarefa só muda de lista se a mudança é válida; o erro não tem tela própria.
  def move_to_list_redirect
    head :unprocessable_content if @error
  end

  # Arrastar na tabela da lista: o JavaScript só precisa saber se gravou.
  def move_redirect
    head(@error ? :unprocessable_content : :ok)
  end

  # Tela de onde a tarefa foi aberta (param `from`), aceita só se for interna do app; sem ela, a lista
  # da tarefa.
  def task_return_path(task)
    url_from(params[:from]) || list_path(task.list)
  end

  def return_path
    task_return_path(@task)
  end
end
