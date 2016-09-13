module OMTK
  module Mission
    class Manager

      extend ::OMTK::Config::Configured
      extend ::OMTK::Mission::Sided

      def self.insert_target(target)
        sqm_file = File.join(conf['mission-directory'], 'mission.sqm')
        create_backup(sqm_file) unless conf[:simulate]

        mission = OMTK::Mission::Mission.new
        begin
          sqm_file_to_parse = File.exists?(sqm_file + '.orig') ? sqm_file + '.orig' : sqm_file
          logger.debug("parsing mission file '#{sqm_file_to_parse}'")
          json = mission.to_json(File.read(sqm_file_to_parse))
        rescue Exception => e
          logger.fatal("fail to parse mission file '#{sqm_file_to_parse}'")
          raise e
        end

        modified_json = json
        case target
          when 'all'
            modified_json = OMTK::Loadout::InfantryManager.new.generate(modified_json )
            modified_json = OMTK::Loadout::VehicleManager.new.generate(modified_json)
          when 'infantry'
            modified_json = OMTK::Loadout::InfantryManager.new.generate(modified_json )
          when 'vehicles'
            modified_json = OMTK::Loadout::VehicleManager.new.generate(modified_json)
        end

        unless conf[:simulate]
          logger.debug("writing new mission file '#{sqm_file}'")
          File.open(sqm_file, 'w+') { |f|
            f.puts mission.to_sqm(modified_json) #JSON::pretty_generate modified_json
          }
          logger.info("loadouts successfully written to '#{sqm_file}'")
        end
      end


      def self.create_backup(sqm_file)
        backup_file =  sqm_file + '.orig'
        logger.debug("creating back-up file '#{backup_file}'")
        unless File.exist?(backup_file)
          FileUtils.cp(sqm_file, backup_file)
        else
          logger.warn("original mission back-up already exists: #{backup_file}")
        end
      end


      def self.restore_backup(sqm_file)
        backup_file = sqm_file + '.orig'
        logger.info("restoring back-up file '#{backup_file}'")
        if File.exist?(backup_file)
          logger.debug("deleting current mission file '#{sqm_file}'")
          FileUtils.remove(sqm_file)
          logger.debug("renaming backup '#{backup_file}' to '#{sqm_file}'")
          FileUtils.move(backup_file, sqm_file)
        else
          logger.error("'#{backup_file}' back-up file not found !")
        end
      end

    end
  end
end