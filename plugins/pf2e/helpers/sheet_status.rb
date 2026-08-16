module AresMUSH
  module Pf2e

    # Unified chargen / sheet completeness checklist.
    # Used by cg/status (self) and pf2e/review <name> (staff).

    def self.cg_boost_status(sheet)
      stored = sheet.ability_boosts || {}
      rows = []
      CG_BOOST_SOURCES.each do |source|
        needed, options = cg_free_boost_requirements(sheet, source)
        next if needed <= 0
        assigned = Array(stored[source] || stored[source.to_sym]).map { |a| ability_key(a) || a.to_s }
        left = [needed - assigned.size, 0].max
        rows << {
          source: source,
          needed: needed,
          assigned: assigned,
          remaining: left,
          options: options
        }
      end
      rows
    end

    def self.sheet_status(char)
      result = cg_ensure_sheet(char)
      return result unless result[:ok]
      sheet = result[:sheet]

      items = []
      hints = []

      locked = cg_identity_locked?(sheet)
      approved = cg_char_approved?(char)

      def_item = lambda do |key, label, done, detail, required: true, hint: nil, stage: "A"|
        if done
          status = :done
        elsif !required
          status = :optional
        elsif stage == "A"
          status = :missing
        else
          status = :pending
        end
        items << {
          key: key,
          label: label,
          status: status,
          detail: detail,
          required: required,
          stage: stage,
          hint: hint
        }
        hints << hint if hint && !done && required
      end

      anc = cg_ancestry_entry(sheet.ancestry)
      def_item.call(
        "ancestry", "Ancestry",
        !sheet.ancestry.to_s.strip.empty?,
        anc.is_a?(Hash) ? (anc["name"] || sheet.ancestry) : (sheet.ancestry.to_s.strip.empty? ? "—" : sheet.ancestry.to_s),
        hint: "cg/ancestry <slug>"
      )

      her = cg_heritage_entry(sheet.heritage)
      def_item.call(
        "heritage", "Heritage",
        !sheet.heritage.to_s.strip.empty?,
        her.is_a?(Hash) ? (her["name"] || sheet.heritage) : (sheet.heritage.to_s.strip.empty? ? "—" : sheet.heritage.to_s),
        hint: "cg/heritage <slug>"
      )

      bg = cg_background_entry(sheet.background)
      def_item.call(
        "background", "Background",
        !sheet.background.to_s.strip.empty?,
        bg.is_a?(Hash) ? (bg["name"] || sheet.background) : (sheet.background.to_s.strip.empty? ? "—" : sheet.background.to_s),
        hint: "cg/background <slug>"
      )

      cc = sheet.charclass || {}
      class_slug = (cc["slug"] || cc[:slug]).to_s.strip
      class_entry = cg_class_entry(class_slug)
      class_detail = if class_entry.is_a?(Hash)
                       name = class_entry["name"] || class_slug
                       ka = cc["key_ability"] || cc[:key_ability]
                       ka ? "#{name} (key: #{ka})" : name
                     else
                       class_slug.empty? ? "—" : class_slug
                     end
      def_item.call(
        "class", "Class",
        !class_slug.empty?,
        class_detail,
        hint: "cg/class <slug> [key ability]"
      )

      if !class_slug.empty?
        opts = cg_effective_key_ability_options(sheet)
        ka = ability_key(cc["key_ability"] || cc[:key_ability])
        ka_ok = opts.empty? || (ka && opts.include?(ka))
        def_item.call(
          "key_ability", "Key ability",
          ka_ok,
          ka ? ka.to_s : "—",
          hint: (opts.size > 1 ? "cg/class #{class_slug} <ability>  (or cg/racket … <ability>)" : nil)
        )
      end

      field = cg_required_subclass_field(sheet)
      if field
        val = (cc[field] || cc[field.to_sym]).to_s.strip
        open_ok = !val.empty? && cg_subclass_open?(field, val)
        label = cg_subclass_label(field)
        name = open_ok ? cg_subclass_name(val) : (val.empty? ? "—" : val)
        def_item.call(
          "subclass", label,
          open_ok,
          name,
          hint: "cg/#{field} <slug>"
        )
      end

      identity_complete = items.select { |i| i[:stage] == "A" && i[:required] }.all? { |i| i[:status] == :done }

      def_item.call(
        "commit", "Identity committed",
        locked,
        locked ? "LOCKED" : "unlocked — run cg/commit when Stage A is done",
        hint: identity_complete && !locked ? "cg/commit" : nil
      )

      if locked
        cg_boost_status(sheet).each do |row|
          src = row[:source]
          left = row[:remaining]
          detail = if left <= 0
                     "#{row[:assigned].join(', ')} (#{row[:needed]}/#{row[:needed]})"
                   else
                     "assigned #{row[:assigned].empty? ? '(none)' : row[:assigned].join(', ')}; #{left} of #{row[:needed]} left"
                   end
          def_item.call(
            "boost_#{src}", "Free boosts (#{src})",
            left <= 0,
            detail,
            stage: "B",
            hint: left > 0 ? "cg/boost #{src} <ability>..." : nil
          )
        end

        bg_left = cg_background_skill_slots_remaining(sheet)
        if (cg_background_skill_slots(sheet) || []).any? || bg_left > 0
          picks = cg_background_skill_picks(sheet)
          def_item.call(
            "bgskill", "Background skill choices",
            bg_left <= 0,
            bg_left <= 0 ? (picks.empty? ? "none required" : picks.join(", ")) : "#{bg_left} remaining",
            stage: "B",
            hint: bg_left > 0 ? "cg/bgskill <option>" : nil
          )
        end

        skill_left = cg_skill_picks_remaining(sheet)
        skill_total = cg_skill_picks_total(sheet)
        skill_used = cg_skill_picks_used(sheet)
        if skill_total > 0 || skill_left > 0
          def_item.call(
            "skills", "Class skill picks",
            skill_left <= 0,
            "#{skill_used}/#{skill_total} used (#{skill_left} left)",
            stage: "B",
            hint: skill_left > 0 ? "cg/skill <skill>..." : nil
          )
        end

        sc_pending = subclass_skill_choices_pending(sheet)
        sc_taken = subclass_skill_choices_taken(sheet)
        if sc_pending > 0 || !sc_taken.empty?
          def_item.call(
            "subclass_skills", "Subclass free skill",
            sc_pending <= 0,
            sc_pending <= 0 ? "taken: #{sc_taken.join(', ')}" : "#{sc_pending} pending (taken: #{sc_taken.empty? ? 'none' : sc_taken.join(', ')})",
            stage: "B",
            hint: sc_pending > 0 ? "cg/skill <skill>  (free subclass pick)" : nil
          )
        end

        lang_left = cg_language_picks_remaining(sheet)
        lang_total = cg_language_picks_total(sheet)
        lang_used = cg_language_picks_used(sheet)
        if lang_total > 0 || lang_left > 0
          def_item.call(
            "languages", "Language picks",
            lang_left <= 0,
            "#{lang_used}/#{lang_total} used (#{lang_left} left)",
            stage: "B",
            hint: lang_left > 0 ? "cg/language <slug>" : nil
          )
        end

        remaining_slots = feat_slots_remaining(sheet)
        open_bits = remaining_slots.select { |_k, v| v.to_i > 0 }
        if open_bits.any?
          detail = open_bits.map { |k, v| "#{k}:#{v}" }.join(", ")
          def_item.call(
            "feats", "Feat slots",
            false,
            "open — #{detail}",
            stage: "B",
            hint: "cg/feat <slug> [slot]"
          )
        else
          totals = feat_slots_total(sheet)
          if totals.values.any? { |v| v.to_i > 0 }
            def_item.call(
              "feats", "Feat slots",
              true,
              "filled",
              stage: "B"
            )
          end
        end
      else
        def_item.call(
          "stage_b", "Stage B (boosts / skills / languages / feats)",
          false,
          "available after cg/commit",
          required: false,
          stage: "B"
        )
      end

      advancing = sheet.respond_to?(:advancing) && (sheet.advancing == true || sheet.advancing.to_s == "true")
      pending_adv = sheet_pending(sheet)
      if advancing
        %w[skill_increase ability_boost class_feat skill_feat general_feat ancestry_feat].each do |k|
          n = pending_adv[k].to_i
          next if n <= 0
          def_item.call(
            "adv_#{k}", "Advancement: #{k.tr('_', ' ')}",
            false,
            "#{n} remaining",
            required: %w[skill_increase ability_boost].include?(k),
            stage: "ADV",
            hint: (k == "skill_increase" ? "adv/skill <skill>" :
                   k == "ability_boost" ? "adv/boost <ability>..." :
                   "adv/feat <slug>")
          )
        end
      end

      open_required = items.select { |i| i[:required] && i[:status] != :done }
      complete = open_required.empty?

      phase = if approved
                advancing ? "approved+advancing" : "approved"
              elsif advancing
                "advancing"
              elsif complete && locked
                "chargen complete"
              elsif locked
                "Stage B"
              else
                "Stage A"
              end

      {
        ok: true,
        error: nil,
        sheet: sheet,
        char: char,
        char_name: char.name,
        approved: approved,
        identity_locked: locked,
        advancing: advancing,
        phase: phase,
        complete: complete,
        identity_complete: identity_complete,
        items: items,
        open_required: open_required,
        hints: hints.compact.uniq
      }
    end

    def self.format_sheet_status(status)
      return t(status[:error] || "pf2e.no_sheet") unless status[:ok]

      mark = lambda do |st|
        case st
        when :done then "[x]"
        when :pending then "[ ]"
        when :missing then "[!]"
        else "[ ]"
        end
      end

      lines = []
      lines << t('pf2e.status_header',
                 :name => status[:char_name],
                 :phase => status[:phase],
                 :lock => status[:identity_locked] ? "LOCKED" : "unlocked")

      %w[A B ADV].each do |stage|
        stage_items = status[:items].select { |i| i[:stage] == stage }
        next if stage_items.empty?
        title = case stage
                when "A" then t('pf2e.status_stage_a')
                when "B" then t('pf2e.status_stage_b')
                else t('pf2e.status_stage_adv')
                end
        lines << title
        stage_items.each do |item|
          lines << t('pf2e.status_item',
                     :mark => mark.call(item[:status]),
                     :label => item[:label],
                     :detail => item[:detail])
        end
      end

      if status[:complete]
        lines << t('pf2e.status_complete')
      else
        n = status[:open_required].size
        lines << t('pf2e.status_incomplete', :count => n)
        if status[:hints].any?
          lines << t('pf2e.status_next_header')
          status[:hints].first(6).each do |h|
            lines << t('pf2e.status_next_line', :hint => h)
          end
        end
      end

      lines.join("%r")
    end

  end
end
