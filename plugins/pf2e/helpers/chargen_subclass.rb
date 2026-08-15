module AresMUSH
  module Pf2e

    def self.cg_list_subclass_options(field)
      field = field.to_s.strip.downcase
      list = CG_SUBCLASS_OPEN[field] || []
      list.map do |slug|
        { slug: slug, name: cg_subclass_name(slug), note: nil }
      end
    end

    def self.cg_required_subclass_field(sheet)
      cc = sheet.charclass || {}
      class_slug = (cc["slug"] || cc[:slug]).to_s.strip.downcase
      return nil if class_slug.empty?
      cg_subclass_field_for_class(class_slug)
    end

    def self.cg_subclass_complete?(sheet)
      field = cg_required_subclass_field(sheet)
      return true if field.nil?
      cc = sheet.charclass || {}
      val = (cc[field] || cc[field.to_sym]).to_s.strip
      !val.empty? && cg_subclass_open?(field, val)
    end

    def self.cg_normalize_subclass_slug(field, raw)
      opt = raw.to_s.strip.downcase.tr(" ", "_").delete("'")
      case field
      when "contact"
        return "faiths_flamekeeper" if opt =~ /faith|flame/
        return "the_inscribed_one" if opt =~ /inscribed/
        return "silence_in_snow" if opt =~ /silence|snow/
        return "spinner_of_threads" if opt =~ /spinner|thread/
        return "wilding_steward" if opt =~ /wilding|steward/
      when "methodology"
        return "forensic_medicine" if opt =~ /forensic/
        return "alchemical_sciences" if opt =~ /alchemical/
      end
      opt
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
      unless CG_SUBCLASS_OPEN.key?(field)
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

      if option_slug.nil? || option_slug.to_s.strip.empty?
        return {
          ok: true, error: nil, sheet: sheet, list: true,
          field: field, rows: cg_list_subclass_options(field),
          label: cg_subclass_label(field)
        }
      end

      opt = cg_normalize_subclass_slug(field, option_slug)
      unless cg_subclass_open?(field, opt)
        return { ok: false, error: "pf2e.cg_subclass_not_open", sheet: sheet }
      end

      cc[field] = opt
      sheet.update(charclass: cc)

      {
        ok: true, error: nil, sheet: sheet, field: field, option: opt,
        option_name: cg_subclass_name(opt), label: cg_subclass_label(field)
      }
    end

    def self.cg_set_contact(char, slug);      cg_set_subclass(char, "contact", slug); end
    def self.cg_set_bloodline(char, slug);    cg_set_subclass(char, "bloodline", slug); end
    def self.cg_set_cause(char, slug);        cg_set_subclass(char, "cause", slug); end
    def self.cg_set_muse(char, slug);         cg_set_subclass(char, "muse", slug); end
    def self.cg_set_racket(char, slug);       cg_set_subclass(char, "racket", slug); end
    def self.cg_set_methodology(char, slug);  cg_set_subclass(char, "methodology", slug); end
    def self.cg_set_order(char, slug);        cg_set_subclass(char, "order", slug); end
    def self.cg_set_edge(char, slug);         cg_set_subclass(char, "edge", slug); end
    def self.cg_set_school(char, slug);       cg_set_subclass(char, "school", slug); end
    def self.cg_set_doctrine(char, slug);     cg_set_subclass(char, "doctrine", slug); end

  end
end
