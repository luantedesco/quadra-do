require "rails_helper"

RSpec.describe Task, type: :model do
  it { is_expected.to belong_to(:list) }
  it { is_expected.to belong_to(:parent).class_name("Task").optional }
  it { is_expected.to have_many(:subtasks).class_name("Task").with_foreign_key(:parent_id) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to define_enum_for(:priority).with_values(none: 0, low: 1, medium: 2, high: 3).with_prefix }

  it_behaves_like "soft deletable"

  describe "subtarefa" do
    let(:list) { create(:list) }
    let(:parent) { create(:task, list:) }

    it "fica na mesma lista do pai" do
      subtask = build(:task, parent:, list: create(:list))

      expect(subtask).not_to be_valid
      expect(subtask.errors.details[:parent]).to include(error: :invalid)
    end

    it "não tem subtarefa de subtarefa" do
      subtask = create(:task, parent:, list:)
      nested = build(:task, parent: subtask, list:)

      expect(nested).not_to be_valid
      expect(nested.errors.details[:parent]).to include(error: :invalid)
    end

    it "não vira subtarefa quando já tem subtarefas" do
      create(:task, parent:, list:)
      parent.parent = create(:task, list:)

      expect(parent).not_to be_valid
      expect(parent.errors.details[:parent]).to include(error: :invalid)
    end
  end

  describe "#finish! e #reopen!" do
    let(:task) { create(:task) }

    it "finish! preenche finished_at" do
      task.finish!

      expect(task.reload.finished_at).to be_present
    end

    it "reopen! limpa finished_at" do
      task.finish!
      task.reopen!

      expect(task.reload.finished_at).to be_nil
    end
  end

  describe "#move_to!" do
    let(:list) { create(:list) }
    let!(:tasks) { Array.new(4) { |index| create(:task, list:, position: index) } }

    it "leva a tarefa para a posição pedida e renumera as vizinhas a partir de 0" do
      tasks.last.move_to!(1)

      expect(list.tasks.actives.where(parent_id: nil).pluck(:id)).to eq(tasks.values_at(0, 3, 1, 2).map(&:id))
      expect(list.tasks.pluck(:position)).to eq([ 0, 1, 2, 3 ])
    end

    it "limita a posição ao fim da lista" do
      tasks.first.move_to!(99)

      expect(tasks.first.reload.position).to eq(3)
    end

    it "não mexe nas subtarefas, nas apagadas nem nas concluídas" do
      subtask = create(:task, list:, parent: tasks.first, position: 7)
      deleted = create(:task, list:, position: 8)
      deleted.soft_delete!
      finished = create(:task, list:, position: 9, finished_at: Time.current)

      tasks.last.move_to!(0)

      expect([ subtask, deleted, finished ].map { |task| task.reload.position }).to eq([ 7, 8, 9 ])
    end

    it "conta a posição só entre as abertas, como a tabela mostra" do
      tasks[1].finish!

      tasks.last.move_to!(1)

      expect(list.tasks.actives.where(finished_at: nil).reorder(:position).pluck(:id)).to eq(tasks.values_at(0, 3, 2).map(&:id))
    end
  end

  describe "#move_beside!" do
    let(:list) { create(:list) }
    let!(:tasks) { Array.new(4) { |index| create(:task, list:, position: index) } }

    def open_order
      list.tasks.actives.where(finished_at: nil).reorder(:position).pluck(:id)
    end

    it "encaixa logo depois do vizinho de cima" do
      tasks.first.move_beside!(previous: tasks[2])

      expect(open_order).to eq(tasks.values_at(1, 2, 0, 3).map(&:id))
    end

    it "sem vizinho de cima, encaixa logo antes do de baixo" do
      tasks.last.move_beside!(following: tasks[1])

      expect(open_order).to eq(tasks.values_at(0, 3, 1, 2).map(&:id))
    end

    it "sem vizinho nenhum, não muda a posição" do
      expect { tasks.first.move_beside! }.not_to(change { tasks.first.reload.position })
    end
  end

  describe "#move_to_list!" do
    let(:task) { create(:task) }
    let(:new_list) { create(:list) }

    it "leva a tarefa para o fim da lista nova, junto com as subtarefas" do
      create(:task, list: new_list, position: 4)
      subtask = create(:task, list: task.list, parent: task)

      task.move_to_list!(new_list)

      expect(task.reload).to have_attributes(list: new_list, position: 5)
      expect(subtask.reload.list).to eq(new_list)
    end
  end

  describe "#soft_delete!" do
    it "apaga também as subtarefas" do
      task = create(:task)
      subtask = create(:task, list: task.list, parent: task)

      task.soft_delete!

      expect(subtask.reload.deleted_at).to be_present
    end
  end
end
