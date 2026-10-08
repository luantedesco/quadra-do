# Drag and drop do painel de Tarefas: põe a lista arrastada na posição de destino.
class SidebarController < ApplicationController
  service_actions :move

  private

  def move_redirect
    head(@error ? :unprocessable_content : :ok)
  end
end
