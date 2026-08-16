module AresMUSH
  module Pf2e

    def self.cg_list_subclass_options(field)
      field = field.to_s.strip.downcase
      data = cg_subclass_field_data(field)
      data.keys.sort.select { |slug| cg_subclass_open?(field, slug) }.map do |slug|
        entry = data[slug] || {}
        { slug: slug, name: entry["name"] || cg_subclass_name(slug), note: nil }
      end
    end

    def self.cg_required_subclass_field(sheet)
      cc = sheet.charclass || {}
      slug = (cc["slug"] || cc[:slug]).to_s.strip.downcase
      return nil if slug.empty?
      cg_subclass_field_for_class(slug)
    end

    def self.cg_subclass_complete?(sheet)
      field = cg_required_subclass_field(sheet)
      return true if field.nil?
      cc = sheet.charclass || {}
      val = (cc[field] || cc[field.to_sym]).to_s.strip
      !val.empty? && cg_subclass_open?(field, val)
    end

    def self.cg_set_subclass(char, field, option_slug)
      result = cg_ensure_sheet(char)
      return result unless result[:ok]
      sheet = result[:sheet]
      blocked = cg_require_not_approved(char, sheet)
      return blocked if blocked
      locked = cg_require_identity_unlocked(sheet)
      return locked if locked

      field = field.to_s.strip.downcase
      unless CG_SUBCLASS_LABELS.key?(field) || cg_subclass_field_data(field).any?
        return { ok: false, error: "pf2e.cg_unknown_subclass_type", sheet: sheet }
      end

      cc = {}
      (sheet.charclass || {}).each { |k, v| cc[k.to_s] = v }
      class_slug = cc["slug"].to_s.strip.downcase
      if class_slug.empty?
        return { ok: false, error: "pf2e.cg_need_class", sheet: sheet }
      end

      required = cg_subclass_field_for_class(class_slug)
      if required != field
        return { ok: false, error: "pf2e.cg_subclass_not_for_class", sheet: sheet }
      end

      key = option_slug.to_s.strip.downcase
      entry = cg_subclass_entry(field, key)
      return { ok: false, error: "pf2e.cg_subclass_not_open", sheet: sheet } unless chargen_open_entry?(entry)

      cc[field] = key
      sheet.update(charclass: cc)
      { ok: true, error: nil, sheet: sheet, field: field, option: key, entry: entry }
    end

  end
end
