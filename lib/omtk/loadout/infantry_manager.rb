module OMTK
  module Loadout
    class InfantryManager

      include ::OMTK::Config::Configured
      include ::OMTK::Mission::Sided

      attr_accessor :config

      def generate(json)
        logger.info('inserting loadouts...')
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
              unit[:Attributes][:isPlayable] = 1 if conf[:all_playable] and (!unit[:Attributes].key?(:isPlayer) or unit[:Attributes][:isPlayer] < 1)
              unit[:Attributes][:rank] = mtkClass.values[0]['rank'].nil? ? 'PRIVATE' : mtkClass.values[0]['rank']
              unit[:Attributes][:description] = mtkClass.values[0]['description'] unless mtkClass.values[0]['description'].nil?
              unless unit[:Attributes].key?(:init) and unit[:Attributes][:init].include?('this setVariable [""omtk_ignore"", 1];')
                unit[:Attributes][:Inventory] = get_loadouts(mtkClass.keys[0], unit[:side])
                #face = get_face(unit, mtkClass)
                #set_face(unit, face) unless face.nil?
              end
              add_group_id(unit, group_callsign)
            }
            group[1][:Entities] = sort_groups(group[1][:Entities])
          end
        }
        json
      end


      def set_face(unit, face)
        logger.debug("setting face '#{face}' to unit class '#{unit[:type]}'")
        new_identity = get_new_identity(face)
        if unit[:CustomAttributes].nil? or unit[:CustomAttributes].empty?
          unit[:CustomAttributes] = {}
          unit[:CustomAttributes][:Attribute0] = new_identity
          unit[:CustomAttributes][:nAttributes] = 1
        else
          id_attribute = unit[:CustomAttributes].select { |k,v| v.is_a?(Hash) and v[:property] == 'face'}
          unless id_attribute.empty?
            id_attribute.values.last[:Value][:data][:value] = face
          else
            unit[:CustomAttributes]["Attribute#{unit[:CustomAttributes][:nAttributes]}".to_sym] = new_identity
            unit[:CustomAttributes][:nAttributes] += 1
            unit[:CustomAttributes] = unit[:CustomAttributes].sort.to_h
          end
        end

      end


      def get_face(unit, mtkClass)
        loadouts = conf["infantry-#{get_color(unit[:side])}".to_sym]
        loadouts[:default].merge(loadouts[mtkClass.keys.first])['face']
      end


      def get_new_identity(face)
        {
            property: 'face',
            expression: '_this setface_value;',
            Value: {
                data: {
                    type: {
                        type: ["STRING"]
                    },
                    value: face
                }
            }
        }
      end

      def get_loadouts(mtkClassName, side)
        logger.debug("fetching loadouts for class '#{mtkClassName}' in side '#{get_color(side)}'")
        res = Hash.new
        side_gears = conf["infantry-#{get_color(side)}".to_sym]

        if side_gears.nil?
          raise Exception.new("Undefined infantry for class '#{mtkClassName}' in side '#{get_color(side)}'")
        end

        side_gears[:default] ||= Hash.new
        side_gears[mtkClassName.to_sym] ||= Hash.new
        gears = merge_loadouts(side_gears[:default], side_gears[mtkClassName.to_sym])
        res = {}
        res[:primaryWeapon] = add_weapon(gears['weapons']['primary']) unless gears['weapons']['primary'].nil?
        res[:secondaryWeapon] = add_weapon(gears['weapons']['launcher']) unless gears['weapons']['launcher'].nil?
        res[:handgun] = add_weapon(gears['weapons']['handgun']) unless gears['weapons']['handgun'].nil?
        res[:binocular] = { name: gears['binocular'] } unless gears['binocular'].nil?
        %w(uniform vest backpack).each { |i| res[i.to_sym] = add_container(gears[i], i == 'backpack') unless gears[i].nil? }
        %w(map compass watch radio goggles headgear).each { |i| res[i.to_sym] = gears[i] unless gears[i].nil? }
        res
      end


      def add_weapon(weapon)
        res = {}
        %w(name optics muzzle).each { |i| res[i.to_sym] = weapon[i] unless weapon[i].nil? }
        unless weapon['magazine'].nil?
          item = get_quantified_item(weapon['magazine'])
          item[1] = 1 if item[1] < 1
          res[:primaryMuzzleMag] = {name: item[2],  ammoLeft: item[1] }
        end
        res
      end

      def add_container(container, is_backpack = false)
        res = { typeName: container['name'] , isBackpack: is_backpack ? 1 : 0}
        res[:MagazineCargo] = add_cargo(container['magazines'], true) unless container['magazines'].nil?
        res[:ItemCargo] = add_cargo(container['items']) unless container['items'].nil?
        res
      end

      def add_cargo(cargo, are_magazines = false)
        res = { items: cargo.size }
        cargo.each_with_index { |item, index|
          values = get_quantified_item(item)
          values[1] = 1 if values[1] < 1 and are_magazines
          res["Item#{index}".to_sym] = { name: values[2], count: values[0]}
          res["Item#{index}".to_sym][:ammoLeft] = values[1] if are_magazines
        }
        res
      end


      def get_quantified_item(item)
        rounds = 0
        itemClass = item
        quantity = 1
        if m = /^((?<quantity>[0-9]+)x )?((?<rounds>[0-9]+)#)?(?<item>.*)$/.match(item)
          quantity = m[:quantity].to_i unless m[:quantity].nil?
          rounds = m[:rounds].to_i unless m[:rounds].nil?
          itemClass = m[:item]
        end
        [quantity, rounds, itemClass]
      end



      def merge_loadouts(defaultGears, classGears)
        result = classGears.dup
        defaultGears.each { |k,v|
          unless classGears.key?(k)
            result[k] = v
          else
            case v
              when Hash
                result[k] = merge_loadouts(v, classGears[k]) if v.kind_of?(Hash) and classGears.key?(k) and !classGears[k].nil?
              when Array
                result[k] += v
                result[k] = sanitize_array(result[k])
            end
          end
        }
        result
      end


      def sanitize_array(array)
        result = Array.new
        matrix = {}
        array.each { |item|
          q = get_quantified_item(item)
          key = q[1] < 1 ?  q[2] : "#{q[1]}##{q[2]}"
          matrix[key] = 0 unless matrix.key?(key)
          matrix[key] += q[0].to_i
        }
        matrix.each { |k,v|
          result << (v > 1 ? "#{v}x #{k}" : k)
        }

        result.sort
      end

      def remove_all
        "removeAllWeapons this;\nremoveAllItems this;\nremoveAllAssignedItems this;\n
        removeUniform this;\nremoveVest this;\nremoveBackpackGlobal this;\nremoveHeadgear this;\nremoveGoggles this;"
      end


      def add_gears(mtkClassName, side)
        logger.debug("fetching infantry for class '#{mtkClassName}' in side '#{get_color(side)}'")
        gears = conf["infantry-#{get_color(side)}".to_sym]

        if gears.nil?
          raise Exception.new("Undefined infantry for class '#{mtkClassName}' in side '#{get_color(side)}'")
        end

        gears[:default] ||= Hash.new
        gears[mtkClassName.to_sym] ||= Hash.new
        result = ''
        gears[:default].merge(gears[mtkClassName.to_sym]).each { |key,value|
          case key
            when 'uniform'
              result += "this forceAddUniform \"#{value}\";"
            when 'vest'
              result += "this addVest \"#{value}\";"
            when 'headgear'
              result += "this addHeadgear \"#{value}\";"
            when 'backpack'
              result += "this addBackpack \"#{value}\";"
            when 'googles'
              result += "this addGoggles \"#{value}\";"
            when 'face'
              result += "this setFace \"#{value}\";"
            else
              raise Exception.new("Unsupported gear '#{key}' for class '#{mtkClassName}' in side '#{get_color(side)}'")
          end unless value.nil? or value.empty?
        }
        result
      end


      def add_weapons(mtkClassName, side)
        logger.debug("fetching weapons for class '#{mtkClassName}' in side '#{get_color(side)}'")
        weapons = conf["weapons-#{get_color(side)}".to_sym]

        if weapons.nil? or !weapons.key?(mtkClassName.to_sym)
          raise Exception.new("Undefined weapons for class '#{mtkClassName}' in side '#{get_color(side)}'")
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
            when 'cargo','uniform','backpack', 'vest', 'uniform'
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
        logger.debug("fetching Arma3 class mapped to '#{arma3ClassName}' in side '#{get_color(side)}'")
        klasses = conf["classes-#{get_color(side)}".to_sym]
        klass = klasses.select{ |k,v| v['class'] == arma3ClassName }
        if klass.nil? or klass.empty?
          raise Exception.new "Class not found: '#{arma3ClassName}' in side '#{get_color(side)}'"
        end
        logger.debug("Arma3 class found: '#{klass}'")
        klass
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
        unit[:Attributes][:description] ||= ''
        unit[:Attributes][:description] += " #{callsign.upcase}"
        unit[:Attributes][:init] = ''
        unit[:Attributes][:init] += "(group this) setGroupId [\"#{callsign.upcase}\"];"
      end


      def get_classes
        result = { bluefor: nil, redfor: nil}
        result[:bluefor] = conf['classes-bluefor'.to_sym]
        result[:redfor] = conf['classes-redfor'.to_sym]
        result
      end

    end
  end
end

