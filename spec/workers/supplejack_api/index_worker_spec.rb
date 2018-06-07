require "spec_helper"

module SupplejackApi
  describe IndexWorker do
    describe "#find_all" do
      let(:record1) { FactoryBot.create(:record, record_id: 12345) }
      let(:record2) { FactoryBot.create(:record, record_id: 67890) }

      it "finds all records by id" do
        expect(IndexWorker.new.find_all("SupplejackApi::Record", [record1.id, record2.id])).to eq [record1, record2]
      end

      it "returns records even when some where not found" do
        expect(IndexWorker.new.find_all("SupplejackApi::Record", ["504d333aa9b6ad1860000056", record1.id])).to eq [record1]
      end

      it "handles individual records" do
        expect(IndexWorker.new.find_all("SupplejackApi::Record", record1.id)).to eq [record1]
      end
    end

    describe "perform" do
      let(:record) { double(:record).as_null_object }

      it "indexes all given record id's" do
        worker = IndexWorker.new

        expect(worker).to receive(:find_all).with("Record", ["123"]) { [record] }
        expect(worker).to receive(:index).with([record]).and_return(nil)

        worker.perform(:index, {class: "Record", id: ["123"]})
      end

      it "removes all given record id's" do
        worker = IndexWorker.new

        expect(worker).to receive(:find_all).with("Record", ["123"]) { [record] }
        expect(worker).to receive(:remove).with([record])

        worker.perform(:remove, {class: "Record", id: ["123"]})
      end

      it "rescues from a RSolr::Error::Http errors when commiting SOLR" do
       allow(Sunspot).to receive(:commit).and_raise(RSolr::Error::Http.new({}, {}))

       IndexWorker.new.perform(:commit)
      end
    end
  end

end
