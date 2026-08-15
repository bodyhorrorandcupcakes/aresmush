module AresMUSH
  module Pf2e

    # -------------------------------------------------
    # Class-option (subclass) mechanical grants
    #
    # Data: plugins/pf2e/data/subclasses.yml under top key "subclasses"
    # Applied on cg/commit and on every feature rebuild (adv/start).
    # Idempotent: skills only raise if Untrained; feats only added if missing;
    # focus spells merged onto the class magic source.
    # -------------------------------------------------

    def self.subclass_field_data(field)
      field = field.to_s.strip.downcase
      data = read_data("subclasses") || {}
      entry = data[field]
      entry.is_a?(Hash) ? entry : {}
    end

    def self.subclass_entry(field, slug)
      field = field.to_s.strip.downcase
      slug = slug.to_s.strip.downcase
      return nil if field.empty? || slug.empty?
      entry = subclass_field_data(field)[slug]
      entry.is_a?(Hash) ? entry : nil
    end

    def self.sheet_subclass_pick(sheet)
      return nil unless sheet
      field = cg_required_subclass_field(sheet)
      return nil unless field
      cc = sheet.charclass || {}
      slug = (cc[field] || cc[field.to_sym]).to_s.strip.downcase
      return nil if slug.empty?
      { field: field, slug: slug, entry: subclass_entry(field, slug) }
    end

    def self.apply_subclass_grants!(sheet)
      return [] unless sheet
      pick = sheet_subclass_pick(sheet)
      return [] unless pick && pick[:entry].is_a?(Hash)

      entry = pick[:entry]
      field = pick[:field]
      slug = pick[:slug]
      level = [sheet.level.to_i, 1].max
      applied = []

      # --- top-level skills (bloodline, racket stubs, etc.) ---
      Array(entry["skills"]).each do |sk|
        sk_key = sk.to_s.strip.downcase
        next if sk_key.empty?
        if skill_rank(sheet, sk_key) == "U"
          set_skill_rank(sheet, sk_key, "T")
          applied << "skill:#{sk_key}"
        end
      end

      # --- tradition onto class magic source ---
      tradition = entry["tradition"].to_s.strip.downcase
      if !tradition.empty?
        apply_subclass_tradition!(sheet, tradition)
        applied << "tradition:#{tradition}"
      end

      # --- cantrips / repertoire gift rank 0 onto class source ---
      Array(entry["cantrips"]).each do |c|
        key = c.to_s.strip.downcase
        next if key.empty?
        add_class_cantrip!(sheet, key)
        applied << "cantrip:#{key}"
      end

      # --- focus spells ---
      Array(entry["focus_spells"]).each do |fs|
        key = fs.to_s.strip.downcase
        next if key.empty?
        add_class_focus_spell!(sheet, key)
        applied << "focus:#{key}"
      end

      # --- repertoire gifts by rank (bloodline sorcerous gifts) ---
      gifts = entry["repertoire_gifts"]
      if gifts.is_a?(Hash)
        gifts.each do |rank_key, spell|
          r = rank_key.to_i
          next if r > level  # only grant gifts the character has unlocked by level
          key = spell.to_s.strip.downcase
          next if key.empty?
          if r == 0
            add_class_cantrip!(sheet, key)
          else
            add_class_repertoire_spell!(sheet, key, r)
          end
          applied << "gift:#{key}@#{r}"
        end
      end

      # --- doctrine / stepped options ---
      steps = entry["steps"]
      if steps.is_a?(Hash)
        steps.each do |lvl_key, package|
          next if lvl_key.to_i > level
          next unless package.is_a?(Hash)
          apply_subclass_step_package!(sheet, package, applied)
        end
      end

      # --- top-level feats (rare) ---
      Array(entry["feats"]).each do |f|
        grant_subclass_feat!(sheet, f, applied)
      end

      # --- top-level proficiency overlay ---
      if entry["proficiency"].is_a?(Hash)
        merge_proficiency_overlay!(sheet, entry["proficiency"])
        applied << "proficiency"
      end

      # --- feature tag for the option itself ---
      add_feature(sheet, "#{field}_#{slug}")
      applied << "feature:#{field}_#{slug}"

      applied.uniq
    end

    def self.apply_subclass_step_package!(sheet, package, applied)
      Array(package["features"]).each do |f|
        key = f.to_s.strip.downcase
        next if key.empty?
        add_feature(sheet, key)
        applied << "feature:#{key}"
      end

      Array(package["feats"]).each do |f|
        grant_subclass_feat!(sheet, f, applied)
      end

      Array(package["skills"]).each do |sk|
        sk_key = sk.to_s.strip.downcase
        next if sk_key.empty?
        if skill_rank(sheet, sk_key) == "U"
          set_skill_rank(sheet, sk_key, "T")
          applied << "skill:#{sk_key}"
        end
      end

      if package["proficiency"].is_a?(Hash)
        merge_proficiency_overlay!(sheet, package["proficiency"])
        applied << "proficiency"
      end

      sc = package["spellcasting"]
      if sc.is_a?(Hash) && sc["proficiency"]
        apply_subclass_spell_proficiency!(sheet, sc["proficiency"])
        applied << "spell_prof:#{sc["proficiency"]}"
      end
    end

    def self.grant_subclass_feat!(sheet, feat_slug, applied)
      key = feat_slug.to_s.strip.downcase
      return if key.empty?
      owned = Array(sheet.feats).map { |f| f.to_s.strip.downcase }
      return if owned.include?(key)
      owned << key
      map = (sheet.feat_slot_map || {}).dup
      map[key] = "granted"
      sheet.update(feats: owned, feat_slot_map: map)
      applied << "feat:#{key}"
    end

    def self.class_magic_source_key(sheet)
      cc = sheet.charclass || {}
      class_slug = (cc["slug"] || cc[:slug]).to_s.strip.downcase
      return nil if class_slug.empty?
      class_entry = class_entry_for_sheet(sheet) || cg_class_entry(class_slug)
      sc = class_entry.is_a?(Hash) ? class_entry["spellcasting"] : nil
      if sc.is_a?(Hash)
        return normalize_magic_source(sc["source"] || class_slug)
      end
      normalize_magic_source(class_slug)
    end

    def self.apply_subclass_tradition!(sheet, tradition)
      src = class_magic_source_key(sheet)
      return unless src
      set_magic_source(sheet, src, "tradition" => tradition.to_s.downcase)
    end

    def self.apply_subclass_spell_proficiency!(sheet, rank)
      src = class_magic_source_key(sheet)
      return unless src
      r = rank.to_s.strip.upcase
      return if r.empty?
      existing = magic_source(sheet, src) || {}
      cur = existing["proficiency"].to_s.upcase
      if teml_rank_value(r) > teml_rank_value(cur)
        set_magic_source(sheet, src, "proficiency" => r)
      end
    end

    def self.add_class_cantrip!(sheet, slug)
      src = class_magic_source_key(sheet)
      return unless src
      entry = magic_source(sheet, src) || default_magic_source
      list = Array(entry["cantrips"]).map { |s| s.to_s.strip.downcase }
      key = slug.to_s.strip.downcase
      return if list.include?(key)
      list << key
      set_magic_source(sheet, src, "cantrips" => list)
    end

    def self.add_class_focus_spell!(sheet, slug)
      src = class_magic_source_key(sheet)
      return unless src
      entry = magic_source(sheet, src) || default_magic_source
      list = Array(entry["focus_spells"]).map { |s| s.to_s.strip.downcase }
      key = slug.to_s.strip.downcase
      return if list.include?(key)
      list << key
      set_magic_source(sheet, src, "focus_spells" => list)
      ensure_focus_pool_from_spells!(sheet)
    end

    def self.add_class_repertoire_spell!(sheet, slug, rank)
      src = class_magic_source_key(sheet)
      return unless src
      entry = magic_source(sheet, src) || default_magic_source
      rep = entry["repertoire"].is_a?(Hash) ? entry["repertoire"].dup : {}
      rkey = rank.to_i.to_s
      list = Array(rep[rkey]).map { |s| s.to_s.strip.downcase }
      key = slug.to_s.strip.downcase
      return if list.include?(key)
      list << key
      rep[rkey] = list
      set_magic_source(sheet, src, "repertoire" => rep)
    end

  end
end
