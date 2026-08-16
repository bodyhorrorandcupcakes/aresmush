module AresMUSH
  module Pf2e

    def self.cg_list_ancestries
      data = read_data("ancestries") || {}
      data.keys.sort.select { |slug| cg_ancestry_open?(slug) }.map do |slug|
        entry = data[slug] || {}
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: "HP #{entry["hp"]} · Spd #{entry["speed"]}"
        }
      end
    end

    def self.cg_list_heritages(char = nil)
      sheet = char ? (cg_ensure_sheet(char)[:sheet] rescue nil) : nil
      heritages = read_data("heritages") || {}

      if sheet && !sheet.ancestry.blank?
        anc = cg_ancestry_entry(sheet.ancestry)
        allowed = Array(anc && anc["heritages"]).map(&:to_s)
        return allowed.sort.select { |slug| cg_heritage_open?(slug) }.map do |slug|
          entry = heritages[slug] || {}
          {
            slug: slug,
            name: entry["name"] || slug,
            note: sheet.ancestry.to_s
          }
        end
      end

      heritages.keys.sort.select { |slug| cg_heritage_open?(slug) }.map do |slug|
        entry = heritages[slug] || {}
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: entry["ancestry"].to_s
        }
      end
    end

    def self.cg_list_backgrounds
      data = read_data("backgrounds") || {}
      data.keys.sort.select { |slug| cg_background_open?(slug) }.map do |slug|
        entry = data[slug] || {}
        choices = Array(entry["skill_choices"]).size
        note_parts = []
        note_parts << "#{choices} choice(s)" if choices > 0
        feat = entry["feat"].to_s
        note_parts << "feat: #{feat}" if !feat.empty? && feat != "null"
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: note_parts.join(" · ")
        }
      end
    end

    def self.cg_list_classes
      data = read_data("charclasses") || read_data("classes") || {}
      data.keys.sort.select { |slug| cg_class_open?(slug) }.map do |slug|
        entry = data[slug] || {}
        keys = Array((entry["key_ability"] || {})["options"]).map(&:to_s)
        field = cg_subclass_field_for_class(slug)
        note_bits = []
        note_bits << ("key: " + keys.join("/")) unless keys.empty?
        note_bits << "HP #{entry["hp"]}"
        note_bits << ("pick: " + cg_subclass_label(field)) if field
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: note_bits.join(" · ")
        }
      end
    end

    def self.cg_format_option_list(title, rows)
      return "#{title}\n  (none in data)" if rows.nil? || rows.empty?
      lines = [title]
      rows.each do |row|
        note = row[:note].to_s
        if note.empty?
          lines << "  #{row[:slug]} — #{row[:name]}"
        else
          lines << "  #{row[:slug]} — #{row[:name]} (#{note})"
        end
      end
      lines.join("\n")
    end

  end
end
