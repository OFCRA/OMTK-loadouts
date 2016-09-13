module OMTK
  module Config
    class Manager

      include ::Singleton

      def logger
        @logger ||= create_logger
      end

      def create_logger
        logger = Logger.new(STDOUT)
        logger.level = (!@instance.nil? and @instance[:debug]) ? Logger::DEBUG : Logger::INFO
        logger
      end

      def load_conf(options = {})
        @instance = options.dup

        validate_path(options['mission-directory'])
        sqm_file = File.join(options['mission-directory'], 'mission.sqm')
        sqm_file = "#{sqm_file}.orig" if File.exist? "#{sqm_file}.orig"
        validate_sqm(sqm_file)

        %W'bluefor redfor'.each { |color|
          %W(classes-#{color} infantry-#{color} vehicles-#{color}).each { |file|
            unless options[file.to_sym].nil?
              OMTK::Config::Manager.instance.logger.info("loading data file '#{options[file.to_sym]}'")
              @instance[file.to_sym] = options[:no_symbol] ? YAML.load_file(options[file.to_sym]) : load_yaml_with_symbolized_keys(options[file.to_sym])
            end
          }
        }
      end


      def get_conf
        @instance
      end


      def load_yaml_with_symbolized_keys(file)
        YAML.load_file(file).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end


      def validate_path(path)
        logger.debug("Validating mission directory '#{path}'")
        prefix = 'invalid location,'
        logger.debug("Checking that '#{path}' is a directory")
        raise "#{prefix} '#{File.absolute_path(path)}' not a directory" unless File.directory?(path)
        logger.debug("Checking that '#{path}' contains file 'mission.sqm'")
        raise "#{prefix} '#{File.absolute_path(File.join(path, 'mission.sqm'))}' mission file missing" unless File.exist?(File.join(path, 'mission.sqm'))
        logger.debug("Checking that '#{path}' contains 'omtk-loadouts' sub-directory")
        raise "#{prefix} '#{File.absolute_path(File.join(path, 'omtk-loadouts'))}' OMTK data missing" unless Dir.exist?(File.join(path, 'omtk-loadouts'))
      end


      def validate_sqm(sqmFilePath)
        logger.debug("Validating mission file '#{sqmFilePath}'")
        if (/^version=(?<version>[0-9]+);\s*?$/ =~ File.new(sqmFilePath, 'r').readline).nil?
          raise "No version in first line of mission file '#{sqmFilePath}'"
        end


        if ::Sqm2Json.is_version_supported?(version.to_i)
          logger.debug("SQM version in '#{sqmFilePath}' matches the supported SQM versions (v#{::Sqm2Json.get_supported_versions.to_s})")
        else
          logger.warn("SQM version v#{version.to_i} in '#{sqmFilePath}' is not officially supported (v#{::Sqm2Json.get_supported_versions.to_s})")
          logger.warn('The loadouts insertion may work but it is not sure !!!')
        end
      end

    end
  end
end
