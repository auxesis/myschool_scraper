require "spec_helper"

describe Icsea do
  let(:table_name) { "icsea" }

  describe "#scrape" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("icsea_scrape") { Icsea.scrape }
    end

    it "builds shadow records" do
      expect(Icsea.records).to_not be_empty
    end
  end

  describe "#save" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("icsea_scrape") { Icsea.scrape }
      Icsea.save
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
      VCR.use_cassette("icsea_scrape") { Icsea.scrape }
      Icsea.save
    end

    it "returns all known records" do
      expect(Icsea.all).to_not be_empty
    end
  end
end
