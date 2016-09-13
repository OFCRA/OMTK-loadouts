module OMTK
  module Loadout
    class Script

      include ::OMTK::Config::Configured
      include ::OMTK::Mission::Sided

      def generate
        logger.info("Generating '#{get_script_path}' file for module infantry_loadouts")
        template = Liquid::Template.parse(
<<-TEMPLATE_LOADOUTS
// BLUEFOR loadouts
{% for class in bluefor %}
omtk_il_set_loadout_bluefor_{{class[0]}} = {
{{class[1]['infantry']}}
{{class[1]['weapons']}}
};
{% endfor %}

// REDFOR loadouts
{% for class in redfor %}
omtk_il_set_loadout_redfor_{{class[0]}} = {
{{class[1]['infantry']}}
{{class[1]['weapons']}}
};
{% endfor %}
TEMPLATE_LOADOUTS
        )
        #File.read(File.expand_path('../generated_loadouts.sqf.tpl', __FILE__)))

        loadoutManager = OMTK::Loadout::InfantryManager.new
        values = {}

        %W'bluefor redfor'.each { |side|
          values[side] = Hash.new
          loadoutManager.get_classes[side.to_sym].each { |clazz, val|
            values[side][val['class']] = Hash.new
            values[side][val['class']]['infantry'] = loadoutManager.add_gears(clazz, get_side(side)).gsub('this', '(_this select 0)')
            values[side][val['class']]['weapons'] = loadoutManager.add_weapons(clazz, get_side(side)).gsub('this', '(_this select 0)')
          }
        }

        File.open(get_script_path, 'w+') { |file|
          file.write(template.render(values))
        }
        logger.info("infantry_loadouts successfully written to script '#{get_script_path}'")
      end

      def remove
        if File.exist?(get_script_path)
          logger.info("deleting script file '#{get_script_path}'")
          File.delete(get_script_path)
        else
          logger.warn("script file '#{get_script_path}' does not exist yet.")
        end

      end

      def get_script_path
        File.join(conf['mission-directory'.to_sym], 'omtk', 'infantry_loadouts', 'generated_loadouts.sqf').to_s
      end
    end
  end
end
