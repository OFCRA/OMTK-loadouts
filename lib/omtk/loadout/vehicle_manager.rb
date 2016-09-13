module OMTK
  module Loadout
    class VehicleManager

      include ::OMTK::Config::Configured
      include ::OMTK::Mission::Sided

      attr_accessor :config, :modifications

      def generate(json)
        logger.info('inserting items in vehicles cargos...')
        @modifications = { processed: {}, unprocessed: {} }
        json[:Mission][:Entities].drop(1).select {|s| s[1][:dataType] == 'Object'}.each { |group|
          if %w'EMPTY'.include? (group[1][:side].upcase)
            vehicleSide,vehicleType = get_vehicle_side(group[1][:type])
            unless vehicleSide.nil? or is_ignored(group[1][:Attributes])
              @modifications[:processed][group[1][:type].to_sym] = 0 unless @modifications[:processed].key?(group[1][:type].to_sym)
              @modifications[:processed][group[1][:type].to_sym] += 1
              cargo_items = get_cargo_items(vehicleType, vehicleSide)
              if group[1][:CustomAttributes].nil? or group[1][:CustomAttributes].empty?
                group[1][:CustomAttributes] = {}
                group[1][:CustomAttributes][:Attribute0] = get_new_cargo(cargo_items)
                group[1][:CustomAttributes][:nAttributes] = 1
              else
                cargo = group[1][:CustomAttributes].select{ |s,v| v.is_a?Hash and v[:property] == 'ammoBox' }
                unless cargo.nil?
                  cargo.values.last[:Value][:data][:value] = cargo_items
                else
                  group[1][:CustomAttributes]["Attribute#{group[1][:CustomAttributes][:nAttributes]}".to_sym] = get_new_cargo(cargo_items)
                  group[1][:CustomAttributes][:nAttributes] += 1
                  group[1][:CustomAttributes] = group[1][:CustomAttributes].sort.to_h
                end
              end
            else
              logger.debug("Unprocessed vehicle, class: '#{group[1][:type]}'")
              @modifications[:unprocessed][group[1][:type].to_sym] = 0 unless @modifications[:unprocessed].key?(group[1][:type].to_sym)
              @modifications[:unprocessed][group[1][:type].to_sym] += 1
            end

          end
        }

        print_modifications
        json
      end


      def print_modifications
        logger.info('Unprocessed vehicles (classes not registered):')
        @modifications[:unprocessed].each { |v| logger.info("\t- #{v[1]}x #{v[0]}") }
        logger.info('Processed vehicles:')
        @modifications[:processed].each { |v| logger.info("\t- #{v[1]}x #{v[0]}") }
      end


      def get_cargo_items(type, side)

        c = conf["vehicles-#{side}"][:common]['cargo'].merge(conf["vehicles-#{side}"][type]['cargo']) { |key, oldValue, newValue|
          oldValue ||= []
          newValue ||= []
          oldValue + newValue
        }
        res = []
        c.each { |k,v|
           if v.nil? or v.empty?
             res << [[],[]]
           else
              res2 = [[], []]
              v.each{ |item|
                q = get_quantified_item(item)
                res2[0] << q[1]
                res2[1] << q[0]
              }
              res << res2
          end
        }
        [res , false].to_s #.gsub('"', '""')
      end


      def get_new_cargo(items)
        {
            property: 'ammoBox',
            expression: '[_this,_value] call bis_fnc_initAmmoBox;',
            Value: {
                data: {
                    type: {
                        type: ["STRING"]
                    },
                    value: items
                }
            }
        }
      end

      def get_quantified_item(item)
        itemClass = item
        quantity = 1
        if m = /^((?<quantity>[0-9]+)x )?(?<item>.*)$/.match(item)
          quantity = m[:quantity].to_i unless m[:quantity].nil?
          itemClass = m[:item]
        end
        [quantity, itemClass]
      end


      def merge_cargos(cargo1, classGears)
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

      def is_ignored(attributes)
        unless attributes.nil? or attributes[:init].nil?
          return attributes[:init] =~ /this\s*setVariable\s*\\\[\s*\['"\]{1}omtk_ignore\['"\]\s*,\s*1\s*\\\]\s*;/i
        end
        false
      end


      def get_vehicle_side(classname)
        %w'bluefor redfor'.each { |color|
          conf["vehicles-#{color}"].each { |key, value|
            return color,key if value.is_a?(Hash) and !value['classes'].nil? and value['classes'].include?(classname)
          }
        }
        return nil,nil
      end

    end
  end
end

