require 'bundler/setup'
Bundler.require(:default)

Dotenv.load

require './lib/writer'

Dir.glob('lib/tasks/*.rake').each{|r| load r }
