require "rails_helper"

RSpec.describe "Layout", type: :request do
  it "abre a tela dentro do menu de ícones, com o item marcado e o título dele" do
    get root_path

    assert_select "title", text: "Tarefas · Quadra Do"
    assert_select "html[data-sidenav-size=condensed]"
    assert_select ".leftside-menu .side-nav-link.active[title=Tarefas][href=?]", root_path
    assert_select ".page-title", text: "Tarefas"
  end

  it "carrega só o CSS compilado, sem os .css crus que ele já importa" do
    get root_path

    assert_select "link[rel=stylesheet]", count: 1
    assert_select "link[rel=stylesheet][href^='/assets/application-']"
  end

  it "põe o tema no pé do menu" do
    get root_path

    assert_select ".side-nav-bottom .side-nav-link", text: "Tema"
  end
end
