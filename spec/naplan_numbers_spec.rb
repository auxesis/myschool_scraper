require "spec_helper"

describe NaplanNumbers do
  let(:table_name) { "naplan_numbers" }

  describe "#scrape" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("naplan_numbers_scrape") { NaplanNumbers.scrape }
    end

    it "builds shadow records" do
      expect(NaplanNumbers.records).to_not be_empty
    end
  end

  describe "#save" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("naplan_numbers_scrape") { NaplanNumbers.scrape }
      NaplanNumbers.save
    end

    it "creates records" do
      expect(ScraperWiki.select("* from #{table_name}")).to_not be_empty
    end
  end

  describe "#all" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("naplan_numbers_scrape") { NaplanNumbers.scrape }
      NaplanNumbers.save
    end

    it "returns all known records" do
      expect(NaplanNumbers.all).to_not be_empty
    end
  end
end
