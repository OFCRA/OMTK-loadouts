module OMTK
  module Roster
    class ForumGenerator

      def process(json, options = {})
        case json[:version]
          when 12
            process_v12(json, options)
          when 51
            process_v51(json, options)
        end
      end

      def process_v12(json, options)
        json[:Mission][:Groups].drop(1).each { |group|
          group[1][:Vehicles].drop(1).each { |index, unit|
            if %w'EAST WEST RESISTANCE'.include?(unit[:side])
              mtkClass = get_MTK_class(unit[:vehicle], unit[:side])
              unit[:player] = 'PLAY CDG' if options[:all_playable]
              unit[:rank] = mtkClass.values[0]['rank'].nil? ? 'PRIVATE' : mtkClass.values[0]['rank']
              unless unit[:init].nil? or unit[:init].include?('this setVariable [""mt_skip"", 1];')
                unit[:init] = get_loadout(mtkClass.keys[0], unit[:side])
              end
            end
          }
        }
        json
      end

      def process_v51(json, options)
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

      private


      def get_loadout(mtkClassName, side)
        res = removeAll
        res += addGears(mtkClassName, side)
        res += addWeapons(mtkClassName, side)
        sanitize_init(res)
      end


      def removeAll
        File.read(File.expand_path('../../../../data/lib/infantry/remove_all.txt', __FILE__))
      end


      def addGears(mtkClassName, side)
        gears = @config["#{SideHelper.get_color(side)}_gears".to_sym]

        if gears.nil?
          raise Exception.new("Undefined infantry for #{SideHelper.get_color(side).capitalize} '#{mtkClassName}'")
        end

        gears[:default] ||= Hash.new
        gears[mtkClassName.to_sym] ||= Hash.new
        res = ''
        gears[:default].merge(gears[mtkClassName.to_sym]).each { |key,value|
          case key
            when 'uniform'
              res += "this forceAddUniform \"#{value}\";"
            when 'vest'
              res += "this addVest \"#{value}\";"
            when 'headgear'
              res += "this addHeadgear \"#{value}\";"
            when 'backpack'
              res += "this addBackpack \"#{value}\";"
            when 'googles'
              res += "this addGoggles \"#{value}\";"
            when 'face'
              res += "this setFace \"#{value}\";"
            else
              raise Exception.new("Unsupported gear '#{key}'")
          end unless value.nil? or value.empty?
        }
        res
      end


      def addWeapons(mtkClassName, side)
        weapons = @config["#{SideHelper.get_color(side)}_weapons".to_sym]

        if weapons.nil? or !weapons.key?(mtkClassName.to_sym)
          raise Exception.new("Undefined weapons for #{SideHelper.get_color(side).capitalize} '#{mtkClassName}'")
        end
        res = ''
        weapons[mtkClassName.to_sym] ||= Hash.new
        w = weapons[:default].merge(weapons[mtkClassName.to_sym]) { |key, oldValue, newValue|
          oldValue ||= []
          newValue ||= []
          oldValue + newValue}
        w.each { |key,value|
          value ||= []
          case key
            when 'weapon'
              index = 0
              value.each { |weapon|

                if weapon.is_a?(Hash)
                  if weapon.key?('ammo')
                    res += "[this,1,\"#{weapon['ammo']}\"] call omtk_fnc_addItem;" unless weapon['ammo'].nil?
                  end
                  res += "this addWeapon \"#{weapon.keys[0]}\";"
                  if weapon.key?('items')
                    weapon['items'].each{ |item|
                      action = index < 1 ? 'addPrimaryWeaponItem' : 'addSecondaryWeaponItem'
                      res += "this #{action} \"#{item}\";"
                    }
                  end

                  # weapon.drop(1).each { |category,val|
                  #   case category
                  #     when 'ammo'
                  #       res += "[this,1,\"#{val}\"] call omtk_fnc_addItem;" unless val.nil?
                  #     when 'items'
                  #       val.each{ |item|
                  #         action = index < 1 ? 'addPrimaryWeaponItem' : 'addSecondaryWeaponItem'
                  #         res += "this #{action} \"#{item}\";"
                  #       }
                  #   end
                  # }
                  # res += "this addWeapon \"#{weapon.keys[0]}\";"
                else
                  res += "this addWeapon \"#{weapon}\";"
                end
                index += 1
              }
            when 'uniform'
              value.each {|item| res += add_quantified_item('addItemToUniform', item)}  unless value.nil?
            when 'vest'
              value.each {|item| res += add_quantified_item('addItemToVest', item)}  unless value.nil?
            when 'backpack'
              value.each {|item| res += add_quantified_item('addItemToBackpack', item)} unless value.nil?
            when 'cargo'
              value.each {|item| res += add_quantified_item('addItem', item)}  unless value.nil?
            when 'link_items'
              value.each {|item| res += "this linkItem \"#{item}\";"}  unless value.nil?

          end
          # else
          #   raise Exception.new("Unsupported item '#{key}'")
          # end unless value.nil? or value.empty?
        }
        res
      end

      def add_quantified_item(container, item)
        quantity = 1
        itemClass = item
        m = /^(?<nb>[0-9]+)x (?<item>.*)$/.match(item)
        if m
          quantity = m[:nb]
          itemClass = m[:item]
        end
        return "[this,#{quantity},\"#{itemClass}\"] call omtk_fnc_#{container};"
      end

      def sanitize_init(content)
        content.gsub(/\n/, '') #.gsub(/"/, '""')
      end

      def get_MTK_class(arma3ClassName, side)
        klasses = @config["#{::Arma3::OMTK::SideHelper.get_color(side)}_classes".to_sym]
        k = klasses.select{ |k,v| v['classes'].include?(arma3ClassName) }
        if k.nil? or k.empty?
          raise Exception.new "Class not found: \"#{arma3ClassName}\""
        end
        k
      end

      def sort_groups(groups)
        ranks = %w'PRIVATE PRIVATE CORPORAL SERGEANT LIEUTENANT CAPTAIN MAJOR COLONEL'

        groups = groups.drop(1).select {|s| s[1][:dataType] == 'Object'}.sort { |a,b|
          a_rank = a[1][:Attributes][:rank] || 'PRIVATE'
          b_rank = b[1][:Attributes][:rank] || 'PRIVATE'
          ranks.index(b_rank) <=> ranks.index(a_rank)
        }

        result = Hash.new
        result[:items] =groups.size
        index = 0
        groups.each { |g|
          result["Item#{index.to_s}".to_sym] = g[1]
          index += 1
        }
        result
      end

      def add_group_id(unit, callsign)
        unit[:Attributes][:description] += " #{callsign.upcase}"
        unit[:Attributes][:init] ||= ''
        unit[:Attributes][:init] += "(group this) setGroupId \"#{callsign.upcase}\";"
      end


      def load_yaml_with_symbolized_keys(file)
        YAML.load_file(file).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end

    end
  end
end

