module AresMUSH
  module Pf2e
    class CgOrderCmd
      include CommandHandler

      attr_accessor :option_slug

      def parse_args
        self.option_slug = cmd.args ? cmd.args.strip.downcase : nil
      end

      def handle
        result = Pf2e.cg_set_order(enactor, self.option_slug)
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

        client.emit_success t(
          'pf2e.cg_subclass_set',
          :label => result[:label],
          :name => result[:option_name]
        )
      end
    end
  end
end
