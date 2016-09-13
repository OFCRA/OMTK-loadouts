module OMTK
  module Command

    class Roster < Thor

      desc 'generate', 'generate an external file in the requested format, describing all slots'
      option type: :required, alias: :t
      option side: :required, alias: :s
      def generate
        OMTK::Config::Manager.instance.load_conf(options)
        OMTK::Roster::Manager.new.generate
      end

    end

  end
end
