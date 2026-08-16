module AresMUSH
  module Pf2e

    # Intelligence-based skills (Remaster). Lore covered via lore / *_lore.
    CG_INT_SKILLS = %w[arcana crafting occultism society].freeze

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

      key = cg_normalize_subclass_slug(field, option_slug)
      unless cg_subclass_open?(field, key)
        return { ok: false, error: "pf2e.cg_subclass_not_open", sheet: sheet }
      end

      entry = cg_subclass_entry(field, key)
      cc[field] = key
      sheet.update(charclass: cc)

      { ok: true, error: nil, sheet: sheet, field: field, option: key, entry: entry }
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

    def self.cg_set_racket(char, slug, key_ability: nil)
      result = cg_set_subclass(char, "racket", slug)
      return result unless result[:ok]

      sheet = result[:sheet]
      entry = result[:entry]
      opts = Array(entry && entry["key_ability_options"]).map { |a| ability_key(a) || a.to_s.downcase }.compact

      if key_ability
        chosen = ability_key(key_ability)
        if chosen.nil? || (opts.any? && !opts.include?(chosen))
          return { ok: false, error: "pf2e.cg_invalid_key_ability", sheet: sheet, options: opts }
        end
        cc = {}
        (sheet.charclass || {}).each { |k, v| cc[k.to_s] = v }
        cc["key_ability"] = chosen
        sheet.update(charclass: cc)
        cg_recalc_abilities(sheet)
        result[:key_ability] = chosen
      elsif opts.any?
        # leave key as-is; commit validation will require it if options diverge
      end

      result[:key_ability_options] = opts
      result
    end

    def self.cg_effective_key_ability_options(sheet)
      cc = sheet.charclass || {}
      class_slug = (cc["slug"] || cc[:slug]).to_s.strip.downcase
      class_entry = cg_class_entry(class_slug)
      base = []
      if class_entry.is_a?(Hash)
        base = Array((class_entry["key_ability"] || {})["options"]).map { |a| ability_key(a) || a.to_s }.compact
      end

      racket = (cc["racket"] || cc[:racket]).to_s.strip.downcase
      if !racket.empty?
        entry = cg_subclass_entry("racket", racket)
        if entry.is_a?(Hash) && entry["key_ability_options"]
          return Array(entry["key_ability_options"]).map { |a| ability_key(a) || a.to_s }.compact
        end
      end
      base
    end

    def self.reconcile_key_ability_for_sheet!(sheet)
      opts = cg_effective_key_ability_options(sheet)
      return if opts.empty?
      cc = {}
      (sheet.charclass || {}).each { |k, v| cc[k.to_s] = v }
      current = ability_key(cc["key_ability"])
      return if current && opts.include?(current)
      if opts.size == 1
        cc["key_ability"] = opts.first
        sheet.update(charclass: cc)
        cg_recalc_abilities(sheet)
      end
    end

    def self.cg_set_key_ability(char, ability)
      result = cg_ensure_sheet(char)
      return result unless result[:ok]
      sheet = result[:sheet]
      blocked = cg_require_not_approved(char, sheet)
      return blocked if blocked

      opts = cg_effective_key_ability_options(sheet)
      chosen = ability_key(ability)
      if chosen.nil?
        return { ok: false, error: "pf2e.cg_unknown_ability", sheet: sheet }
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
