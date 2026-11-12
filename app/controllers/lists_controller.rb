class ListsController < ApplicationController
  before_action :remember_sort, :remember_group, only: :show

  service_actions :index, :show, :new, :create, :edit, :update, :destroy

  private

  def index_redirect
    redirect_to list_path(@list) if @list
  end

  # A lista nova abre; com erro, o formulário do modal volta com a mensagem no campo.
  def create_redirect
    @error ? render(status: :unprocessable_content) : redirect_to(list_path(@list))
  end

  def update_redirect
    render status: :unprocessable_content if @error
  end

  def destroy_redirect
    redirect_to root_path, status: :see_other
  end

  # Ordem e direção escolhidas no menu "Ordenar por", lembradas por lista em cookie; ordem sem direção
  # volta à direção padrão dela.
  def remember_sort
    return unless Core::Domain::TaskSort.valid?(params[:sort])

    cookies["list_sort_#{params[:id]}"] = { value: params[:sort], expires: 1.year }
    if Core::Domain::TaskSort.valid_direction?(params[:direction])
      cookies["list_direction_#{params[:id]}"] = { value: params[:direction], expires: 1.year }
    else
      cookies.delete("list_direction_#{params[:id]}")
    end
  end

  # Agrupamento escolhido no menu "Agrupar por", lembrado por lista em cookie.
  def remember_group
    return unless Core::Domain::TaskGroup.valid?(params[:group])

    cookies["list_group_#{params[:id]}"] = { value: params[:group], expires: 1.year }
  end
end
