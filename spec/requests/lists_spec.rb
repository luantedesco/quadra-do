require "rails_helper"

RSpec.describe "Listas", type: :request do
  it "mostra as listas ativas na ordem do painel" do
    create(:list, name: "Casa", position: 1)
    create(:list, name: "Trabalho", position: 0)
    create(:list, name: "Apagada", position: 2).soft_delete!

    get root_path

    expect(response).to have_http_status(:ok)
    assert_select "li", count: 2
    assert_select "li:nth-of-type(1)", text: "Trabalho"
    assert_select "li:nth-of-type(2)", text: "Casa"
  end
end
