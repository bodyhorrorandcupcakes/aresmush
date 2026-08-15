module AresMUSH
  module Pf2e

    # Intelligence-based skills (Remaster). Lore covered via lore / *_lore.
    CG_INT_SKILLS = %w[arcana crafting occultism society].freeze

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

      # Changing subclass clears prior free skill picks for that option
      cc[field] = opt
      cc["skill_choices"] = []
      sheet.update(charclass: cc)

      # Racket may change legal key ability — keep if still legal, else first option
      if field == "racket"
        reconcile_key_ability_for_sheet!(sheet)
      end

      {
        ok: true, error: nil, sheet: sheet, field: field, option: opt,
        option_name: cg_subclass_name(opt), label: cg_subclass_label(field),
        key_ability: (sheet.charclass || {})["key_ability"]
      }
    end

    def self.cg_set_contact(char, slug);      cg_set_subclass(char, "contact", slug); end
    def self.cg_set_bloodline(char, slug);    cg_set_subclass(char, "bloodline", slug); end
    def self.cg_set_cause(char, slug);        cg_set_subclass(char, "cause", slug); end
    def self.cg_set_muse(char, slug);         cg_set_subclass(char, "muse", slug); end
    def self.cg_set_methodology(char, slug);  cg_set_subclass(char, "methodology", slug); end
    def self.cg_set_order(char, slug);        cg_set_subclass(char, "order", slug); end
    def self.cg_set_edge(char, slug);         cg_set_subclass(char, "edge", slug); end
    def self.cg_set_school(char, slug);       cg_set_subclass(char, "school", slug); end
    def self.cg_set_doctrine(char, slug);     cg_set_subclass(char, "doctrine", slug); end

    # Racket: optional key ability as second argument
    def self.cg_set_racket(char, slug, key_ability: nil)
      result = cg_set_subclass(char, "racket", slug)
      return result if !result[:ok] || result[:list]

      if key_ability
        ka = cg_set_key_ability(char, key_ability)
        return ka unless ka[:ok]
        result[:key_ability] = (ka[:sheet].charclass || {})["key_ability"]
        result[:sheet] = ka[:sheet]
      end
      result
    end

    # ---- Key ability (class + racket alternate) ----

    def self.cg_effective_key_ability_options(sheet)
      return [] unless sheet
      cc = sheet.charclass || {}
      class_slug = (cc["slug"] || cc[:slug]).to_s.strip.downcase
      return [] if class_slug.empty?

      entry = cg_class_entry(class_slug)
      opts = Array((entry.is_a?(Hash) ? entry["key_ability"] : nil) || {}).fetch("options", [])
      opts = opts.map { |a| ability_key(a) }.compact

      racket = (cc["racket"] || cc[:racket]).to_s.strip.downcase
      if !racket.empty?
        rent = subclass_entry("racket", racket)
        if rent.is_a?(Hash) && rent["key_ability_options"]
          opts = Array(rent["key_ability_options"]).map { |a| ability_key(a) }.compact
        end
      end
      opts.uniq
    end

    def self.reconcile_key_ability_for_sheet!(sheet)
      return unless sheet
      opts = cg_effective_key_ability_options(sheet)
      return if opts.empty?
      cc = {}
      (sheet.charclass || {}).each { |k, v| cc[k.to_s] = v }
      current = ability_key(cc["key_ability"])
      return if current && opts.include?(current)
      cc["key_ability"] = opts.first
      sheet.update(charclass: cc)
      cg_recalc_abilities(sheet)
    end

    def self.cg_set_key_ability(char, ability)
      result = cg_ensure_sheet(char)
      return result unless result[:ok]
      sheet = result[:sheet]

      blocked = cg_require_not_approved(char, sheet)
      return blocked if blocked
      locked = cg_require_identity_unlocked(sheet)
      return locked if locked

      chosen = ability_key(ability)
      return { ok: false, error: "pf2e.cg_unknown_ability", sheet: sheet } if chosen.nil?

      opts = cg_effective_key_ability_options(sheet)
      if opts.empty?
        return { ok: false, error: "pf2e.cg_need_class", sheet: sheet }
      end
      unless opts.include?(chosen)
        return { ok: false, error: "pf2e.cg_invalid_key_ability", sheet: sheet, options: opts }
      end

      cc = {}
      (sheet.charclass || {}).each { |k, v| cc[k.to_s] = v }
      if cc["slug"].to_s.empty?
        return { ok: false, error: "pf2e.cg_need_class", sheet: sheet }
      end
      cc["key_ability"] = chosen
      sheet.update(charclass: cc)
      cg_recalc_abilities(sheet)
      { ok: true, error: nil, sheet: sheet, key_ability: chosen, options: opts }
    end

    # ---- Subclass free skill choices (empiricism / mastermind) ----

    def self.subclass_skill_choice_spec(sheet)
      pick = sheet_subclass_pick(sheet)
      return nil unless pick && pick[:entry].is_a?(Hash)
      sc = pick[:entry]["skill_choices"]
      sc.is_a?(Hash) ? sc : nil
    end

    def self.subclass_skill_choices_taken(sheet)
      cc = sheet.charclass || {}
      Array(cc["skill_choices"] || cc[:skill_choices]).map { |s| s.to_s.strip.downcase }.reject(&:empty?)
    end

    def self.subclass_skill_choices_pending(sheet)
      spec = subclass_skill_choice_spec(sheet)
      return 0 unless spec
      [spec["count"].to_i - subclass_skill_choices_taken(sheet).size, 0].max
    end

    def self.skill_valid_for_subclass_choice?(sheet, skill_slug)
      spec = subclass_skill_choice_spec(sheet)
      return false unless spec
      key = skill_slug.to_s.strip.downcase
      return false if key.empty?

      if spec["from"].is_a?(Array) && !spec["from"].empty?
        return Array(spec["from"]).map { |s| s.to_s.strip.downcase }.include?(key)
      end

      attr = spec["from_attribute"].to_s.strip.downcase
      if attr == "int" || attr == "intelligence"
        return true if CG_INT_SKILLS.include?(key)
        return true if key == "lore" || key.end_with?("_lore")
      end
      false
    end

    def self.record_subclass_skill_choice!(sheet, skill_slug)
      key = skill_slug.to_s.strip.downcase
      cc = {}
      (sheet.charclass || {}).each { |k, v| cc[k.to_s] = v }
      picks = Array(cc["skill_choices"]).map { |s| s.to_s.strip.downcase }
      return if picks.include?(key)
      picks << key
      cc["skill_choices"] = picks
      sheet.update(charclass: cc)
    end

    def self.subclass_fixed_skills(sheet)
      pick = sheet_subclass_pick(sheet)
      return [] unless pick && pick[:entry].is_a?(Hash)
      Array(pick[:entry]["skills"]).map { |s| s.to_s.strip.downcase }.reject(&:empty?)
    end

  end
end
