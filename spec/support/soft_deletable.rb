RSpec.shared_examples "soft deletable" do
  subject(:record) { create(described_class.model_name.singular) }

  describe "#soft_delete!" do
    it "preenche deleted_at sem remover a linha" do
      record.soft_delete!

      expect(record.reload.deleted_at).to be_present
    end
  end

  describe ".actives" do
    it "traz só os registros sem deleted_at" do
      deleted = create(described_class.model_name.singular)
      deleted.soft_delete!

      expect(described_class.actives).to contain_exactly(record)
    end
  end
end
