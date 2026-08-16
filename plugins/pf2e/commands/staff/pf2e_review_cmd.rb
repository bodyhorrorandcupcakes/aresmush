module AresMUSH
  module Pf2e
    class Pf2eReviewCmd
      include CommandHandler

      attr_accessor :target_name

      def parse_args
        self.target_name = titlecase_arg(cmd.args)
      end

      def handle
        if self.target_name.blank?
          client.emit_failure t('pf2e.review_usage')
          return
        end

        char = Character.named(self.target_name) || Character.find_one_by_name(self.target_name)
        if !char
          client.emit_failure t('pf2e.character_not_found')
          return
        end

        unless Pf2e.can_view_char_sheet?(enactor, char) || Pf2e.can_manage_pf2e?(enactor)
          client.emit_failure t('pf2e.view_sheet_denied')
          return
        end

        result = Pf2e.sheet_status(char)
        if !result[:ok]
          client.emit_failure t(result[:error] || 'pf2e.no_sheet')
          return
        end
        client.emit Pf2e.format_sheet_status(result)
      end
    end
  end
end
