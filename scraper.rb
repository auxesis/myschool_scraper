require "scraperwiki"
require "active_support/inflector"
require "csv"
require "pry"
require "mechanize"

class School
  class << self
    attr_writer :source_filename

    def source_filename
      @source_filename || "targets.csv"
    end

    def records
      @schools
    end

    def scrape
      @schools = []

      CSV.foreach(source_filename, :headers => true) do |row|
        # Make the column names saveable in SQLite
        record = Hash[row.map { |k, v| [k.parameterize(separator: "_"), v] }]
        @schools << record
      end
    end

    def pkeys
      %w[acara_school_id calendar_year]
    end

    def table_name
      "schools"
    end

    def save
      ScraperWiki.save_sqlite(pkeys, records, table_name)
    end

    def all
      ScraperWiki.select("* FROM #{table_name}")
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
      page.search("section.student-background div.index p.no-data-message").any?
    end

    def server_error?(page)
      # 5xx series errors return fucking 200s
      page.title == "Internal Server Error"
    end

    def scrape_school(acara_school_id:, calendar_year:)
      record = {
        "acara_school_id" => acara_school_id,
        "calendar_year" => calendar_year,
      }
      url = "https://www.myschool.edu.au/school/#{acara_school_id}/profile/#{calendar_year}"
      page = agent.get(url)
      return record if no_data?(page)
      return record if server_error?(page)

      index = page.search("section.student-background div.index li div.col2").map(&:text)
      record["school_icsea_value"] = index.first
      record["data_source"] = index.last
      json = page.search("section.student-background div.graph script").text[/ChartOptions = (.*}}})/, 1]
      graph_json = JSON.parse(json)
      quartiles = graph_json["series"].first["data"].map(&:values).flatten
      record["q1"] = quartiles[0]
      record["q2"] = quartiles[1]
      record["q3"] = quartiles[2]
      record["q4"] = quartiles[3]
      record
    rescue => e
      binding.pry
    end

    def scrape
      @icsea = []
      years.each do |year|
        School.all.each do |school|
          id = school["acara_school_id"]
          debug("Scraping #{id}")
          @icsea << scrape_school(acara_school_id: id, calendar_year: year)
        end
      end
    end

    def records
      @icsea
    end

    def pkeys
      %w[acara_school_id calendar_year]
    end

    def table_name
      "icsea"
    end

    def save
      ScraperWiki.save_sqlite(pkeys, records, table_name)
    end

    def debug(msg)
      puts "[debug] " + msg
    end

    def all
      ScraperWiki.select("* FROM #{table_name}")
    end
  end
end

class NaplanNumbers
  class << self
    def agent
      @agent ||= Mechanize.new
    end

    def years
      %w[2018]
    end

    def records
      @numbers
    end

    def pkeys
      %w[acara_school_id calendar_year]
    end

    def table_name
      "naplan_numbers"
    end

    def no_data?(page)
      page.search("div.school-naplan div.naplan-landing p.no-data-message").any?
    end

    def scrape_naplan_numbers(acara_school_id:, calendar_year:)
      records = []
      base_record = {
        "acara_school_id" => acara_school_id,
        "calendar_year" => calendar_year,
      }
      url = "https://www.myschool.edu.au/school/#{acara_school_id}/naplan/numbers/#{calendar_year}"
      begin
        page = agent.get(url)
      rescue Mechanize::ResponseCodeError => e
        info("404 on #{url}")
        return {}
      end

      return records if no_data?(page)

      # build up the list of columns
      headers = page.search("table#allSchoolsTable>thead>tr>th").map(&:text)
      headers = page.search("table#allSchoolsTable>thead>tr>th").map(&:text).map(&:parameterize)
      headers[0] = "year"

      rows = page.search("table#allSchoolsTable>tbody>tr")
      rows.each do |row|
        columns = row.children.reject(&:text?)
        values = columns.map { |c| c.children.find(&:text?).text.strip }
        attrs = Hash[headers.zip(values)]
        records << base_record.merge(attrs)
      end
      records
    end

    def scrape
      @numbers = []
      years.each do |year|
        School.all.each do |school|
          id = school["acara_school_id"]
          debug("Scraping NAPLAN numbers for #{id}")
          @numbers << scrape_naplan_numbers(acara_school_id: id, calendar_year: year)
        end
      end
      @numbers.flatten!
      @numbers.reject!(&:empty?)
    end

    def save
      ScraperWiki.save_sqlite(pkeys, records, table_name)
    end

    def debug(msg)
      puts "[debug] " + msg
    end

    def info(msg)
      puts "[info] " + msg
    end

    def all
      ScraperWiki.select("* FROM #{table_name}")
    end
  end
end

def main
  School.scrape
  School.save
  Icsea.scrape
  Icsea.save
  NaplanNumbers.scrape
  NaplanNumbers.save
end

main if $PROGRAM_NAME == __FILE__
