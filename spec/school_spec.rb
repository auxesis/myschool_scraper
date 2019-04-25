require "spec_helper"

describe School do
  before(:all) do
    School.log_level = School::LOG_NONE
  end

  before(:each) do
    School.source_filename = "spec/schools.csv"
  end

  describe "#scrape" do
    before(:each) do
      School.scrape
    end

    it "reads a csv" do
      expect(School.records).to_not be_empty
    end
  end

  describe "#save" do
    before(:each) do
      School.scrape
      School.save
    end

    it "creates records" do
      expect(ScraperWiki.select("* FROM #{School.table_name}")).to_not be_empty
    end
  end

  describe "#all" do
    before(:each) do
      School.scrape
      School.save
    end

    it "returns all known records" do
      expect(School.all).to_not be_empty
    end
  end
end
