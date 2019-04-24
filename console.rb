require 'scraperwiki'
require 'active_support/inflector'
require 'csv'
require 'pry'
require 'mechanize'
require_relative './scraper'

Pry.config.prompt_name = 'myschool_scraper'
Pry.config.should_load_rc = false
Pry.config.history.should_save = true
Pry.config.history.should_load = true

binding.pry
