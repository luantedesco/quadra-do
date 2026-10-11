require "rails_helper"

RSpec.describe List, type: :model do
  it { is_expected.to have_many(:tasks).order(:position) }
  it { is_expected.not_to validate_presence_of(:name) }

  it_behaves_like "soft deletable"

  describe "cor" do
    it { is_expected.to allow_values("#727cf5", "#39AFD1", "", nil).for(:color) }
    it { is_expected.not_to allow_values("red", "#fff", "#727cf5; background: url(x)").for(:color) }
  end

  describe ".next_position" do
    it "é 0 sem listas e vem depois da última lista ativa" do
      expect(described_class.next_position).to eq(0)

      create(:list, position: 3)
      create(:list, position: 7).soft_delete!

      expect(described_class.next_position).to eq(4)
    end
  end

  describe "#move_to!" do
    it "leva a lista para a posição pedida e renumera as ativas a partir de 0, sem mexer nas apagadas" do
      lists = Array.new(3) { |index| create(:list, position: index) }
      deleted = create(:list, position: 9)
      deleted.soft_delete!

      lists.last.move_to!(0)

      expect(described_class.actives.order(:position).pluck(:id)).to eq(lists.values_at(2, 0, 1).map(&:id))
      expect(described_class.actives.order(:position).pluck(:position)).to eq([ 0, 1, 2 ])
      expect(deleted.reload.position).to eq(9)
    end

    it "limita a posição ao fim do painel" do
      lists = Array.new(2) { |index| create(:list, position: index) }

      lists.first.move_to!(99)

      expect(lists.first.reload.position).to eq(1)
    end
  end

  describe "#soft_delete!" do
    it "apaga também as tarefas e as subtarefas delas" do
      list = create(:list)
      task = create(:task, list:)
      subtask = create(:task, list:, parent: task)

      list.soft_delete!

      expect([ list, task, subtask ].map { |record| record.reload.deleted_at }).to all(be_present)
    end
  end

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
