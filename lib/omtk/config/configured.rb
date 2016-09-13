module OMTK
  module Config
    module Configured

      def logger
        @logger ||= OMTK::Config::Manager.instance.logger
      end

      def conf
        @conf ||= OMTK::Config::Manager.instance.get_conf
      end

    end
  end
end