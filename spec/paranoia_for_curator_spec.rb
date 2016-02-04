require 'spec_helper'
require 'byebug'

describe ParanoiaForCurator do
  context "with riak" do
    with_config do
      Curator.configure(:resettable_riak) do |config|
        config.environment = "test"
        config.migrations_path = "/tmp/curator_migrations"
        config.bucket_prefix = 'curator'
        config.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
      end
    end

    before :each do
      def_transient_class(:TestModelRepository) do
        include Curator::Repository
        attr_reader :id, :some_field, :deleted_at
        attr_writer :deleted_at

        acts_as_paranoid
        indexed_fields :some_field
      end

      def_transient_class(:TestModel) do
        include Curator::Model
        attr_reader :id, :some_field, :deleted_at
        attr_writer :deleted_at
      end

      @model1 = TestModel.new(:some_field => "Some Value 1")
      TestModelRepository.save(@model1)
      TestModelRepository.delete(@model1)

      @model2 = TestModel.new(:some_field => "Some Value 2")
      TestModelRepository.save(@model2)
    end

    describe "all" do
      it "finds all" do
        expect(TestModelRepository.all.map(&:some_field).sort).to eq ["Some Value 2"]
        expect(TestModelRepository.all_with_deleted.map(&:some_field).sort).to eq ["Some Value 1", "Some Value 2"]
      end
    end

    describe "find_by_index" do
      it "find by attribute" do
        expect(TestModelRepository.find_by_some_field("Some Value 1").map(&:some_field).sort).to eq []
        expect(TestModelRepository.find_by_some_field("Some Value 1", with_deleted: true).map(&:some_field).sort).to eq ["Some Value 1"]
      end
    end

    context "find_first_by_index" do
      it "find first by index" do
        expect(TestModelRepository.find_first_by_some_field("Some Value 1")).to eq nil
        expect(TestModelRepository.find_first_by_some_field("Some Value 1", with_deleted: true).some_field).to eq 'Some Value 1'
      end
    end

    describe "only_deleted" do
      it "find only deleted" do
        expect(TestModelRepository.only_deleted.map(&:some_field).sort).to eq ["Some Value 1"]
      end
    end

    describe "find_by_id" do
      it "find by id" do
        expect(TestModelRepository.find_by_id(@model1.id)).to eq nil
        expect(TestModelRepository.find_by_id(@model1.id, with_deleted: true).some_field).to eq 'Some Value 1'
      end
    end

    describe "delete" do
      it "act as soft delete" do
        model1 = TestModelRepository.find_by_id(@model1.id, with_deleted: true)
        expect(model1.deleted_at).to_not be_nil
      end
    end

    describe "really_delete" do
      it "act as really delete" do
        TestModelRepository.really_delete(@model2)
        model2 = TestModelRepository.find_by_id(@model2.id, with_deleted: true)
        expect(model2).to be_nil
      end
    end

    describe "restore" do
      it "restore" do
        model1 = TestModelRepository.find_by_id(@model1.id, with_deleted: true)
        expect(model1.deleted_at).to_not be_nil

        TestModelRepository.restore(model1)
        model = TestModelRepository.find_by_id(model1.id)
        expect(model.deleted_at).to be_nil
      end
    end
  end
end
