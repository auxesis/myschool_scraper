require 'spec_helper'

describe School do
  before(:each) do
    School.source_filename = 'spec/schools.csv'
  end

  describe '#scrape' do
    before(:each) do
      School.scrape
    end

    it 'reads a csv' do
      expect(School.records).to_not be_empty
    end
  end

  describe '#save' do
    before(:each) do
      School.scrape
      School.save
    end

    it 'creates records' do
      expect(ScraperWiki.select('* from schools')).to_not be_empty
    end
  end
end
