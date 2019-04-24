require 'spec_helper'

describe School do
  describe '#scrape' do
    before(:each) do
      School.scrape
    end

    it 'creates records' do
      expect(ScraperWiki.select('* from schools')).to_not be_empty
    end
  end
end
