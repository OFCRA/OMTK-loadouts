module OMTK
  module Roster
    class Manager

      include ::OMTK::Config::Configured

      def generate
        case conf[:format]
          when :markdown
            OMTK::Roster::Markdown.process
          when :bbcode
            OMTK::Roster::BBCode.process
          else
            raise Exception.new "Unsupported format '#{conf[:format]}'"
        end
      end

    end
  end
end

