require "spec_helper"

describe NaplanNumbers do
  before(:all) do
    NaplanNumbers.log_level = NaplanNumbers::LOG_NONE
  end

  describe "#scrape" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("naplan_numbers_scrape") do
        NaplanNumbers.scrape(schools: School.all)
      end
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
      VCR.use_cassette("naplan_numbers_scrape") do
        NaplanNumbers.scrape(schools: School.all)
      end
      NaplanNumbers.save
    end

    it "creates records" do
      expect(ScraperWiki.select("* FROM #{NaplanNumbers.table_name}")).to_not be_empty
    end

    context "with bad data" do
      it "does not create empty records" do
        expect(ScraperWiki.select("* FROM #{NaplanNumbers.table_name} WHERE reading IS NULL")).to be_empty
      end

      it "does not create records for empty results" do
        expect(ScraperWiki.select("* FROM #{NaplanNumbers.table_name} WHERE reading IS '-'")).to be_empty
      end
    end
  end

  describe "#all" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("naplan_numbers_scrape") do
        NaplanNumbers.scrape(schools: School.all)
      end
      NaplanNumbers.save
    end

    it "returns all known records" do
      expect(NaplanNumbers.all).to_not be_empty
    end
  end
end
