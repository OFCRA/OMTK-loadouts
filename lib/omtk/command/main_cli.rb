module OMTK
  module Command

    class MainCli < Thor
      class_option 'mission-directory', type: :string, aliases: [:m], desc: 'path to the folder containing the mission.sqm file', default: '..'



      desc 'version', 'print tool version and misc. information'
      def version
        puts "##################################################"
        puts "# OFCRA Mission ToolKit Loadouts (OMTK-loadouts) #"
        puts "##################################################"
        puts "version:\n\t#{OMTK::VERSION}\n"
        puts "author:\n\tgalevsky@gmail.com\n"
        puts "Supported SQM versions:\n\tv#{::Sqm2Json.get_supported_versions.join(' - v')}"
        puts "More info:\n\thttp://github.org/ofcra/omtk-loadouts"
        puts "contact:\n\thttp://ofcrav2.org/forum/index.php"
      end


      desc 'test', 'test if the mission.sqm file and all loadouts .yml files can be parsed successfully, but DOES NOT MODIFY anything'
      option 'classes-bluefor', type: :string, aliases: [:cg], desc: 'Bluefor infantry classes definition file',  default: File.join('.', 'infantry', 'bluefor-classes.yml')
      option 'classes-redfor', type: :string, aliases: [:cg], desc: 'Redfor infantry classes definition file', default: File.join('.', 'infantry', 'redfor-classes.yml')
      option 'infantry-bluefor', type: :string, aliases: [:bg], desc: 'Bluefor infantry loadouts definition file',  default: File.join('.', 'infantry', 'bluefor-loadouts.yml')
      option 'infantry-redfor', type: :string, aliases: [:rg], desc: 'Redfor infantry loadouts definition file', default: File.join('.', 'infantry', 'redfor-loadouts.yml')
      option 'vehicles-bluefor', type: :string, aliases: [:bw], desc: 'Bluefor vehicle cargos definition file',  default: File.join('.', 'vehicles', 'bluefor-cargos.yml')
      option 'vehicles-redfor', type: :string, aliases: [:rw], desc: 'Redfor vehicle cargos definition file', default: File.join('.', 'vehicles', 'redfor-cargos.yml')
      def test
        opts = options.dup
        opts.merge!(simulate: true)
        begin
          OMTK::Config::Manager.instance.load_conf(opts)
          OMTK::Mission::Manager.insert_target('all')
          OMTK::Config::Manager.instance.logger.info('Test successful.')
        rescue Exception => e
          OMTK::Config::Manager.instance.logger.fatal(e.message)
          OMTK::Config::Manager.instance.logger.error('Test failed !!!')
        end

      end


      desc 'insert <target>', 'insert loadouts in mission.sqm file about the specified <target>, among {infantry|vehicles|all}'

      long_desc <<-LONGDESC
        Insert the specified <target> into the mission.sqm file, with these possible values:

          * infantry: set loadouts for every supported infantry unit

          * vehicles: set cargos content for every supported vehicle

          * all: all previous targets

        -m, --mission-directory=PATH\npath to the folder containing the mission.sqm to process. Default: ..

        -d, --debug
          print out debug information
      LONGDESC

      option 'classes-bluefor',    type: :string, aliases: [:bc], desc: 'Bluefor classes definition file',                default: File.join('.', 'infantry', 'bluefor-classes.yml')
      option 'classes-redfor',     type: :string, aliases: [:rc], desc: 'Redfor classes definition file',                 default: File.join('.', 'infantry', 'redfor-classes.yml')
      option 'infantry-bluefor',   type: :string, aliases: [:bg], desc: 'Bluefor infantry loadouts definition file',      default: File.join('.', 'infantry', 'bluefor-loadouts.yml')
      option 'infantry-redfor',    type: :string, aliases: [:rg], desc: 'Redfor infantry loadouts definition file',       default: File.join('.', 'infantry', 'redfor-loadouts.yml')
      option 'vehicles-bluefor',   type: :string, aliases: [:bw], desc: 'Bluefor vehicles cargos definition file',        default: File.join('.', 'vehicles', 'bluefor-cargos.yml')
      option 'vehicles-redfor',    type: :string, aliases: [:rw], desc: 'Redfor vehicles cargos weapons definition file', default: File.join('.', 'vehicles', 'redfor-cargos.yml')
      #option 'script',             type: :string, aliases: [:s],  desc: 'generate loadouts as scripts functions'
      option 'debug',              type: :boolean, aliases: [:d], desc: 'print out debug logs', default: false

      def insert(target)

        raise Exception.new "unsupported <target> value '#{target}', must be {all|infantry|vehicles}" unless %w"all infantry vehicles".include?(target)
        begin
          OMTK::Config::Manager.instance.load_conf(options)
          OMTK::Mission::Manager.insert_target(target)
          #OMTK::Loadout::Script.new.generate if options[:script]
        rescue Exception => e
          OMTK::Config::Manager.instance.logger.fatal(e.message)
        end
      end


      desc 'restore', 'restore the original mission file, deleting any changes'
      def restore
        OMTK::Config::Manager.instance.load_conf(options)
        OMTK::Mission::Manager.restore_backup(File.join(options['mission-directory'.to_sym], 'mission.sqm'))
        #OMTK::Loadout::Script.new.remove
      end


    end
  end
end
