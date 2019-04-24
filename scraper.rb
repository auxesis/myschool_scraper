require 'scraperwiki'
require 'active_support/inflector'
require 'csv'
require 'pry'
require 'mechanize'

def load_targets
  @targets = []

  CSV.foreach('targets.csv', :headers => true) do |row|
    @targets << row
  end
end

def target_ids
  @ids ||= @targets.map { |t| t['ACARA School ID'] }
end

def find_by_id(id)
  @targets.find { |t| t['ACARA School ID'] == id }
end

def save_schools
  target_ids.each do |id|
    row = find_by_id(id).to_hash
    record = Hash[row.map { |k,v| [ k.parameterize(separator: '_'), v ] }]
    ScraperWiki.save_sqlite(['acara_school_id', 'calendar_year'], record, table_name='schools')
  end
end

class School
  class << self
    attr_writer :source_filename

    def source_filename
      @source_filename || 'targets.csv'
    end

    def records
      @schools
    end

    def scrape
      @schools = []

      CSV.foreach(source_filename, :headers => true) do |row|
        # Make the column names saveable in SQLite
        record = Hash[row.map { |k,v| [ k.parameterize(separator: '_'), v ] }]
        @schools << record
      end
    end

    def pkeys
      %w[acara_school_id calendar_year]
    end

    def table_name
      'schools'
    end

    def save
      ScraperWiki.save_sqlite(pkeys, records, table_name)
    end
  end
end

class Icsea
  class << self
    def agent
      @agent ||= Mechanize.new
    end

    def years
      %w[2018]
    end

    def no_data?(page)
      page.search('section.student-background div.index p.no-data-message').any?
    end

    def server_error?(page)
      # 5xx series errors return fucking 200s
      page.title == "Internal Server Error"
    end

    def scrape_and_build_record(acara_school_id:, calendar_year:)
      record = {
        'acara_school_id' => acara_school_id,
        'calendar_year' => calendar_year
      }
      url = "https://www.myschool.edu.au/school/#{acara_school_id}/profile/#{calendar_year}"
      page = agent.get(url)
      return record if no_data?(page)
      return record if server_error?(page)

      index = page.search('section.student-background div.index li div.col2').map(&:text)
      record['school_icsea_value'] = index.first
      record['data_source'] = index.last
      json = page.search('section.student-background div.graph script').text[/ChartOptions = (.*}}})/, 1]
      graph_json = JSON.parse(json)
      quartiles = graph_json['series'].first['data'].map(&:values).flatten
      record['q1'] = quartiles[0]
      record['q2'] = quartiles[1]
      record['q3'] = quartiles[2]
      record['q4'] = quartiles[3]
      record
    rescue => e
      binding.pry
    end

    def scrape
      load_targets

      records = []
      target_ids.each do |id|
        years.each do |year|
          debug("Scraping #{id}")
          records << scrape_and_build_record(acara_school_id: id, calendar_year: year)
        end
      end

      records
    end

    def save
      records = scrape

      records.each do |record|
        ScraperWiki.save_sqlite(['acara_school_id', 'calendar_year'], record, table_name='icsea')
      end
    end

    def debug(msg)
      puts '[debug] ' + msg
    end
  end
end

def main
  load_targets
  save_schools
  Icsea.save
end

main if $PROGRAM_NAME == __FILE__
