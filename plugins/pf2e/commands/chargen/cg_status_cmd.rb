module AresMUSH
  module Pf2e
    class CgStatusCmd
      include CommandHandler

      def handle
        result = Pf2e.sheet_status(enactor)
        if !result[:ok]
          client.emit_failure t(result[:error] || 'pf2e.no_sheet')
          return
        end
        client.emit Pf2e.format_sheet_status(result)
      end
    end
  end
end
