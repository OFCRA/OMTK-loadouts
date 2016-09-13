require 'singleton'
require 'json'
require 'yaml'
require 'thor'

class Thor
  def self.basename
    File.basename($PROGRAM_NAME, '.rb').split(" ").first + '.exe'
  end
end

require 'sqm2json'
require 'fileutils'
require 'logger'
require 'liquid'

require File.expand_path('../omtk/version', __FILE__)

require File.expand_path('../omtk/config/manager', __FILE__)
require File.expand_path('../omtk/config/configured', __FILE__)

require File.expand_path('../omtk/mission/sided', __FILE__)
require File.expand_path('../omtk/mission/mission', __FILE__)
require File.expand_path('../omtk/mission/manager', __FILE__)

require File.expand_path('../omtk/loadout/infantry_manager', __FILE__)
require File.expand_path('../omtk/loadout/vehicle_manager', __FILE__)
require File.expand_path('../omtk/loadout/script', __FILE__)

require File.expand_path('../omtk/command/roster', __FILE__)
require File.expand_path('../omtk/command/main_cli', __FILE__)

