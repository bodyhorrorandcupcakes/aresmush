module AresMUSH
  module Pf2e
    class CgRacketCmd
      include CommandHandler

      attr_accessor :option_slug, :key_ability

      def parse_args
        parts = cmd.args.to_s.split
        self.option_slug = parts[0] ? parts[0].strip.downcase : nil
        self.key_ability = parts[1] ? parts[1].strip.downcase : nil
      end

      def handle
        result = Pf2e.cg_set_racket(enactor, self.option_slug, key_ability: self.key_ability)
        if !result[:ok]
          client.emit_failure t(result[:error])
          return
        end

        if result[:list]
          client.emit Pf2e.cg_format_option_list(
            t('pf2e.cg_list_subclass', :label => result[:label]),
            result[:rows] || []
          )
          return
        end

        msg = t(
          'pf2e.cg_subclass_set',
          :label => result[:label],
          :name => result[:option_name]
        )
        if result[:key_ability]
          msg = "#{msg} Key ability: #{result[:key_ability]}."
        end
        client.emit_success msg
      end
    end
  end
end
