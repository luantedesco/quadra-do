class TasksController < ApplicationController
  service_actions :create, :move

  private

  # Volta para a lista com o campo de adicionar focado, para a próxima tarefa; o erro aparece abaixo
  # dele.
  def create_redirect
    flash[:quick_add] = @error || :ok
    redirect_to list_path(@task.list)
  end

  # Arrastar na tabela da lista: o JavaScript só precisa saber se gravou.
  def move_redirect
    head(@error ? :unprocessable_content : :ok)
  end
end
