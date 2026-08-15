module AresMUSH
  module Pf2e
    class SpellSearchTemplate < ErbTemplateRenderer

      attr_accessor :paginator, :query

      def initialize(paginator, query = nil)
        @paginator = paginator
        @query = query
        super File.dirname(__FILE__) + "/spell_search.erb"
      end

      def title
        if @query.to_s.strip.empty?
          t('pf2e.spell_search_title_all')
        else
          t('pf2e.spell_search_title_query', :query => @query)
        end
      end

      def wrap_effect(text, width = 74, indent = "  ")
        return "" if text.nil? || text.to_s.strip.empty?
        words = text.to_s.strip.gsub(/\s+/, " ").split(" ")
        lines = []
        line = ""
        words.each do |word|
          candidate = line.empty? ? word : "#{line} #{word}"
          if candidate.length > width && !line.empty?
            lines << "#{indent}#{line}"
            line = word
          else
            line = candidate
          end
        end
        lines << "#{indent}#{line}" unless line.empty?
        lines.join("%r")
      end
    end
  end
end
