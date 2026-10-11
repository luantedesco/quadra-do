require "rails_helper"

RSpec.describe Core::Domain::TaskSort do
  let(:list) { create(:list) }

  def ordered_titles(key, direction = nil)
    list.tasks.actives.reorder(described_class.new(key, direction).order).pluck(:title)
  end

  before do
    create(:task, list:, title: "banana", position: 2, priority: :low, deadline: 2.days.from_now, created_at: 3.days.ago)
    create(:task, list:, title: "Abacaxi", position: 0, priority: :none, deadline: nil, created_at: 1.day.ago)
    create(:task, list:, title: "cereja", position: 1, priority: :high, deadline: 1.day.from_now, created_at: 2.days.ago)
  end

  it "personalizada segue a posição do arrasto" do
    expect(ordered_titles("manual")).to eq(%w[Abacaxi cereja banana])
  end

  it "prazo põe a mais próxima primeiro e as sem prazo por último" do
    expect(ordered_titles("deadline")).to eq(%w[cereja banana Abacaxi])
  end

  it "prioridade põe a alta primeiro e as sem prioridade por último" do
    expect(ordered_titles("priority")).to eq(%w[cereja banana Abacaxi])
  end

  it "título ignora maiúsculas" do
    expect(ordered_titles("title")).to eq(%w[Abacaxi banana cereja])
  end

  it "criação põe a mais nova primeiro" do
    expect(ordered_titles("created")).to eq(%w[Abacaxi cereja banana])
  end

  it "valor desconhecido cai na personalizada, que não tem direção" do
    expect(described_class.new("qualquer", "asc")).to have_attributes(key: "manual", manual?: true, direction: nil)
  end

  describe "direção" do
    it "cada ordem tem a sua direção padrão, e direção desconhecida cai nela" do
      expect(%w[deadline priority title created].map { |key| described_class.new(key, "qualquer").direction }).to eq(%w[asc desc asc desc])
    end

    it "prazo decrescente põe a mais distante primeiro e mantém as sem prazo no fim" do
      expect(ordered_titles("deadline", "desc")).to eq(%w[banana cereja Abacaxi])
    end

    it "prioridade crescente põe a baixa primeiro e mantém as sem prioridade no fim" do
      expect(ordered_titles("priority", "asc")).to eq(%w[banana cereja Abacaxi])
    end

    it "título decrescente e criação crescente invertem a ordem padrão" do
      expect([ ordered_titles("title", "desc"), ordered_titles("created", "asc") ]).to eq([ %w[cereja banana Abacaxi], %w[banana cereja Abacaxi] ])
    end
  end
end
