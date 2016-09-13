module OMTK
  module Roster
    class MarkdownGenerator

      include ::OMTK::Config::Configured
      include ::OMTK::Mission::Sided

      def generate
        logger.info("Generating '#{get_output_file}' file for module infantry_loadouts")
        template = Liquid::Template.parse(File.read(File.expand_path('../generated_loadouts.sqf.tpl', __FILE__)))

        begin
          sqm_file = File.join(conf['mission-directory'], 'mission.sqm')
          mission = OMTK::Mission::Mission.new
          sqm_file_to_parse = File.exists?(sqm_file + '.orig') ? sqm_file + '.orig' : sqm_file
          logger.debug("parsing mission file '#{sqm_file_to_parse}'")
          json = mission.to_json(File.read(sqm_file_to_parse))
          values = get_info(json)
        rescue Exception => e
          logger.fatal("fail to parse mission file '#{sqm_file_to_parse}'")
          raise e
        end

        File.open(get_output_file, 'w+') { |file|
          file.write(template.render(values))
        }
        logger.debug("file '#{get_output_file}' completed.")
      end

      def get_info(json)
        json[:Mission][:Entities].drop(1).select {|s| s[1][:dataType] == 'Group'}.each { |group|
          if %w'EAST WEST RESISTANCE'.include? (group[1][:side].upcase)
            group_callsign = ''
            if group[1].key?(:CustomAttributes)
              group_callsign = group[1][:CustomAttributes].select{ |s,v|
                if v.is_a?(Hash)
                  v.key?(:property) and v[:property] == 'groupID'
                else
                  false
                end
              }.values[0][:Value].values[0][:value]
            end

            group[1][:Entities].drop(1).select {|s| s[1][:dataType] == 'Object'}.each { |u|
              unit = u[1]

              mtkClass = get_MTK_class(unit[:type], unit[:side])
              unit[:Attributes][:isPlayable] = 1 if options[:all_playable]
              unit[:Attributes][:rank] = mtkClass.values[0]['rank'].nil? ? 'PRIVATE' : mtkClass.values[0]['rank']
              unit[:Attributes][:description] = mtkClass.values[0]['description'] unless mtkClass.values[0]['rank'].nil?
              add_group_id(unit, group_callsign) if unit.key?(:flags) and unit[:flags] > 1
              unless unit[:Attributes].key?(:init) and unit[:Attributes][:init].include?('this setVariable [""mt_skip"", 1];')
                unit[:Attributes][:init] += get_loadout(mtkClass.keys[0], unit[:side])
              end
            }
            group[1][:Entities] = sort_groups(group[1][:Entities])
          end
        }
        json
      end


      def get_output_file
        File.join(conf['mission-directory'.to_sym], 'generated_briefing.md').to_s
      end

   end
  end
end

