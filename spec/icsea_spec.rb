require "spec_helper"

describe Icsea do
  before(:all) do
    Icsea.log_level = Icsea::LOG_NONE
  end

  let(:target_schools) { School.all }
  let(:target_years) { (2018..2018) }

  describe "#scrape" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("icsea_scrape") do
        Icsea.scrape(schools: target_schools, years: target_years)
      end
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
      VCR.use_cassette("icsea_scrape", :record => :new_episodes) do
        Icsea.scrape(schools: target_schools, years: target_years)
      end
      Icsea.save
    end

    it "creates records" do
      expect(ScraperWiki.select("* FROM #{Icsea.table_name}")).to_not be_empty
    end

    it "does not create empty records" do
      expect(ScraperWiki.select("* FROM #{Icsea.table_name} WHERE q1 IS NULL")).to be_empty
    end
  end

  describe "#all" do
    before(:each) do
      School.source_filename = "spec/schools.csv"
      School.scrape
      School.save
      VCR.use_cassette("icsea_scrape", :record => :new_episodes) do
        Icsea.scrape(schools: target_schools, years: target_years)
      end
      Icsea.save
    end

    it "returns all known records" do
      expect(Icsea.all).to_not be_empty
    end
  end
end
