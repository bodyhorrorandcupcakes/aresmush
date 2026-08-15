module AresMUSH
  module Pf2e

    # -------------------------------------------------
    # Browse helpers — available identity options
    # Returns arrays of { slug:, name:, note: } for CLI/web.
    # -------------------------------------------------

    def self.cg_list_ancestries
      data = read_data("ancestries") || {}
      data.keys.sort.map do |slug|
        entry = data[slug] || {}
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: "HP #{entry["hp"]} · Spd #{entry["speed"]}"
        }
      end
    end

    # If sheet has an ancestry, only heritages allowed for that ancestry.
    def self.cg_list_heritages(sheet = nil)
      data = read_data("heritages") || {}
      allowed = nil
      if sheet && !sheet.ancestry.to_s.empty?
        anc = cg_ancestry_entry(sheet.ancestry)
        allowed = Array(anc && anc["heritages"]).map(&:to_s) if anc.is_a?(Hash)
      end
      data.keys.sort.map do |slug|
        next if allowed && !allowed.include?(slug.to_s)
        entry = data[slug] || {}
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: entry["ancestry"] ? "ancestry: #{entry["ancestry"]}" : nil
        }
      end.compact
    end

    def self.cg_list_backgrounds
      data = read_data("backgrounds") || {}
      data.keys.sort.map do |slug|
        entry = data[slug] || {}
        {
          slug: slug.to_s,
          name: entry["name"] || slug.to_s,
          note: nil
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
