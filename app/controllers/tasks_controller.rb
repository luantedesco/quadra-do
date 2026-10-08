class TasksController < ApplicationController
  service_actions :create

  private

  # Volta para a lista com o campo de adicionar focado, para a próxima tarefa; o erro aparece abaixo
  # dele.
  def create_redirect
    flash[:quick_add] = @error || :ok
    redirect_to list_path(@task.list)
  end
end
