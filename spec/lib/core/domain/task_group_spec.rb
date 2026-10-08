require "rails_helper"

RSpec.describe Core::Domain::TaskGroup do
  include ActiveSupport::Testing::TimeHelpers

  let(:list) { create(:list) }

  def section_titles(key)
    described_class.new(key).sections(list.tasks.actives.reorder(:position)).map { |section, tasks| [ section, tasks.map(&:title) ] }
  end

  describe "por prazo" do
    it "divide pelo dia do prazo no fuso da aplicação, na ordem fixa e sem as seções vazias" do
      travel_to Time.zone.parse("2026-10-08 10:00") do
        create(:task, list:, title: "ontem", position: 0, deadline: Time.zone.parse("2026-10-07 23:00"))
        create(:task, list:, title: "hoje cedo", position: 1, deadline: Time.zone.parse("2026-10-08 08:00"))
        create(:task, list:, title: "amanhã", position: 2, deadline: Time.zone.parse("2026-10-09 09:00"))
        create(:task, list:, title: "daqui 7 dias", position: 3, deadline: Time.zone.parse("2026-10-15 09:00"))
        create(:task, list:, title: "daqui 8 dias", position: 4, deadline: Time.zone.parse("2026-10-16 09:00"))
        create(:task, list:, title: "sem prazo", position: 5)

        expect(section_titles("deadline")).to eq([
          [ "overdue", [ "ontem" ] ],
          [ "today", [ "hoje cedo" ] ],
          [ "tomorrow", [ "amanhã" ] ],
          [ "next_7_days", [ "daqui 7 dias" ] ],
          [ "later", [ "daqui 8 dias" ] ],
          [ "no_deadline", [ "sem prazo" ] ]
        ])
      end
    end
  end

  describe "por prioridade" do
    it "põe alta, média, baixa e nenhuma, mantendo a ordem das tarefas dentro de cada seção" do
      create(:task, list:, title: "baixa", position: 0, priority: :low)
      create(:task, list:, title: "alta 2", position: 2, priority: :high)
      create(:task, list:, title: "alta 1", position: 1, priority: :high)
      create(:task, list:, title: "sem", position: 3)

      expect(section_titles("priority")).to eq([ [ "high", [ "alta 1", "alta 2" ] ], [ "low", [ "baixa" ] ], [ "none", [ "sem" ] ] ])
    end
  end

  it "sem agrupamento, ou com valor desconhecido, é uma seção só com todas as tarefas" do
    create(:task, list:, title: "a", position: 0)
    create(:task, list:, title: "b", position: 1)

    expect(section_titles("qualquer")).to eq([ [ nil, %w[a b] ] ])
  end
end
