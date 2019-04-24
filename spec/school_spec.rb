require 'spec_helper'

describe School do
  describe '#save' do
    before(:each) do
      School.save
    end

    it 'creates records' do
      expect(ScraperWiki.select('* from schools')).to_not be_empty
    end
  end
end
