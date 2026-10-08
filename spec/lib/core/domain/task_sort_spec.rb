require "rails_helper"

RSpec.describe Core::Domain::TaskSort do
  let(:list) { create(:list) }

  def ordered_titles(key)
    list.tasks.actives.reorder(described_class.new(key).order).pluck(:title)
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

  it "valor desconhecido cai na personalizada" do
    expect(described_class.new("qualquer")).to have_attributes(key: "manual", manual?: true)
  end
end
