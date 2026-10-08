class ListsController < ApplicationController
  before_action :remember_sort, only: :show

  service_actions :index, :show, :new, :create, :edit, :update, :destroy

  private

  def index_redirect
    redirect_to list_path(@list) if @list
  end

  # Com erro, o formulário volta no modal com a mensagem no campo.
  def create_redirect
    @error ? render(:new, status: :unprocessable_content) : redirect_to(list_path(@list))
  end

  def update_redirect
    @error ? render(:edit, status: :unprocessable_content) : redirect_to(list_path(@list))
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
end
