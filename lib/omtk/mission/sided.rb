module OMTK
  module Mission
    module Sided

      OMTK_MISSION_SIDES = { bluefor: 'WEST', redfor: 'EAST', greenfor: 'RESISTANCE'}

      def get_side(color)
        OMTK_MISSION_SIDES[color.downcase.to_sym]
      end

      def get_color(side)
        OMTK_MISSION_SIDES.key(side.to_s.upcase)
      end

    end
  end
end
