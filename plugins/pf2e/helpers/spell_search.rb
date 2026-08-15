module AresMUSH
  module Pf2e

    # Catalog search over merged spells data (cantrips, ranks, focus, rituals).
    # Query matches slug, name, category, traits, traditions, rarity, source text.
    # Pure digits match rank exactly (0 = cantrips).
    # Results sorted alphabetically by name.
    def self.spell_search(query = nil)
      data = read_data("spells") || {}
      q = query.to_s.strip.downcase
      rows = []

      data.each do |slug, entry|
        next unless entry.is_a?(Hash)
        # Skip meta keys if any non-hash slipped in; traditions list under spells.yml is a Hash of spell entries only after merge
        next if slug.to_s == "traditions" && !entry.key?("name") && !entry.key?("rank")

        slug_s = slug.to_s
        name = (entry["name"] || slug_s).to_s
        rank = entry["rank"].to_i
        category = entry["category"].to_s
        traits = Array(entry["traits"]).map(&:to_s)
        traditions = Array(entry["traditions"]).map(&:to_s)
        rarity = entry["rarity"].to_s
        cast = entry["cast"].to_s
        range = entry["range"].to_s
        target = entry["target"].to_s
        area = entry["area"].to_s
        duration = entry["duration"].to_s
        source = entry["source"].to_s
        effect = entry["effect"].to_s

        if !q.empty?
          if q =~ /\A\d+\z/
            next unless rank == q.to_i
          else
            haystack = [
              slug_s,
              name.downcase,
              category.downcase,
              traits.map(&:downcase).join(" "),
              traditions.map(&:downcase).join(" "),
              rarity.downcase,
              cast.downcase,
              range.downcase,
              target.downcase,
              area.downcase,
              duration.downcase,
              source.downcase,
              effect.downcase
            ].join(" ")
            next unless haystack.include?(q)
          end
        end

        rows << {
          slug: slug_s,
          name: name,
          rank: rank,
          category: category.empty? ? rank_category_label(rank, traits) : category,
          traits: traits,
          traditions: traditions,
          rarity: rarity,
          cast: cast,
          range: range,
          target: target,
          area: area,
          duration: duration,
          effect: effect.strip.gsub(/\s+/, " ")
        }
      end

      rows.sort_by { |r| r[:name].to_s.downcase }
    end

    def self.rank_category_label(rank, traits)
      t = Array(traits).map { |x| x.to_s.downcase }
      return "cantrip" if rank.to_i == 0 || t.include?("cantrip")
      return "focus" if t.include?("focus")
      return "ritual" if t.include?("ritual")
      "spell"
    end

  end
end
