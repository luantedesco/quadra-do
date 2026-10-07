require "rails_helper"

RSpec.describe List, type: :model do
  it { is_expected.to have_many(:tasks).order(:position) }
  it { is_expected.to validate_presence_of(:name) }

  it_behaves_like "soft deletable"

  describe ".first e .last" do
    it "seguem a ordem de criação" do
      older = create(:list, created_at: 2.days.ago)
      newer = create(:list, created_at: 1.day.ago)

      expect([ described_class.first, described_class.last ]).to eq([ older, newer ])
    end
  end

  describe "#build_task" do
    subject(:list) { create(:list) }

    it "põe a primeira tarefa na posição 0" do
      expect(list.build_task(title: "Nova").position).to eq(0)
    end

    it "põe a tarefa nova depois da última tarefa de topo ativa" do
      create(:task, list:, position: 2)
      create(:task, list:, position: 5).soft_delete!
      parent = create(:task, list:, position: 1)
      create(:task, list:, position: 9, parent_id: parent.id)

      expect(list.build_task(title: "Nova").position).to eq(3)
    end

    it "monta a tarefa na lista sem salvar" do
      task = list.build_task(title: "Nova")

      expect(task).to have_attributes(list:, title: "Nova", new_record?: true)
    end
  end
end
