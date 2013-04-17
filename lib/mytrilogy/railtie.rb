require 'mytrilogy'
require 'rails'

module Mytrilogy
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/mytrilogy.rake"
    end
  end
end