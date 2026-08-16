module AresMUSH
  module Pf2e

    # Chargen policy — openness is data-driven via chargen_open: true on catalog
    # entries (ancestries, heritages, backgrounds, classes, subclasses).
    # Missing key = closed. Structural maps stay in code.

    CG_REQUIRED_SUBCLASS = {
      "witch" => "contact",
      "sorcerer" => "bloodline",
      "champion" => "cause",
      "bard" => "muse",
      "rogue" => "racket",
      "investigator" => "methodology",
      "druid" => "order",
      "ranger" => "edge",
      "wizard" => "school",
      "cleric" => "doctrine"
    }.freeze

    CG_SUBCLASS_LABELS = {
      "contact" => "Contact",
      "bloodline" => "Bloodline",
      "cause" => "Cause",
      "muse" => "Muse",
      "racket" => "Racket",
      "methodology" => "Methodology",
      "order" => "Order",
      "edge" => "Hunter's Edge",
      "school" => "School",
      "doctrine" => "Doctrine"
    }.freeze

    CG_SUBCLASS_NAMES = {
      "faiths_flamekeeper" => "Faith's Flamekeeper",
      "the_inscribed_one" => "The Inscribed One",
      "silence_in_snow" => "Silence in Snow",
      "spinner_of_threads" => "Spinner of Threads",
      "wilding_steward" => "Wilding Steward",
      "imperial" => "Imperial",
      "elemental" => "Elemental",
      "fey" => "Fey",
      "angelic" => "Angelic",
      "justice" => "Justice",
      "liberation" => "Liberation",
      "redemption" => "Redemption",
      "obedience" => "Obedience",
      "maestro" => "Maestro",
      "enigma" => "Enigma",
      "polymath" => "Polymath",
      "warrior" => "Warrior",
      "ruffian" => "Ruffian",
      "scoundrel" => "Scoundrel",
      "thief" => "Thief",
      "mastermind" => "Mastermind",
      "empiricism" => "Empiricism",
      "forensic_medicine" => "Forensic Medicine",
      "interrogation" => "Interrogation",
      "alchemical_sciences" => "Alchemical Sciences",
      "animal" => "Animal",
      "leaf" => "Leaf",
      "storm" => "Storm",
      "wild" => "Wild",
      "wave" => "Wave",
      "flame" => "Flame",
      "precision" => "Precision",
      "flurry" => "Flurry",
      "outwit" => "Outwit",
      "abjuration" => "Abjuration",
      "conjuration" => "Conjuration",
      "divination" => "Divination",
      "enchantment" => "Enchantment",
      "evocation" => "Evocation",
      "illusion" => "Illusion",
      "transmutation" => "Transmutation",
      "universalist" => "Universalist",
      "cloistered" => "Cloistered Cleric",
      "warpriest" => "Warpriest"
    }.freeze

    def self.chargen_open_entry?(entry)
      entry.is_a?(Hash) && entry["chargen_open"] == true
    end

    def self.cg_ancestry_open?(slug)
      chargen_open_entry?(cg_ancestry_entry(slug))
    end

    def self.cg_heritage_open?(slug)
      chargen_open_entry?(cg_heritage_entry(slug))
    end

    def self.cg_background_open?(slug)
      chargen_open_entry?(cg_background_entry(slug))
    end

    def self.cg_class_open?(slug)
      chargen_open_entry?(cg_class_entry(slug))
    end

    def self.cg_subclass_field_data(field)
      root = read_data("subclasses") || {}
      data = root[field.to_s]
      data.is_a?(Hash) ? data : {}
    end

    def self.cg_subclass_entry(field, option_slug)
      cg_subclass_field_data(field)[option_slug.to_s.strip.downcase]
    end

    def self.cg_subclass_open?(field, option_slug)
      chargen_open_entry?(cg_subclass_entry(field, option_slug))
    end

    def self.cg_subclass_field_for_class(class_slug)
      CG_REQUIRED_SUBCLASS[class_slug.to_s.strip.downcase]
    end

    def self.cg_subclass_name(slug)
      key = slug.to_s.strip.downcase
      entry = nil
      CG_REQUIRED_SUBCLASS.values.uniq.each do |field|
        e = cg_subclass_entry(field, key)
        if e.is_a?(Hash) && e["name"]
          entry = e
          break
        end
      end
      return entry["name"] if entry.is_a?(Hash) && entry["name"]
      CG_SUBCLASS_NAMES[key] || key.split("_").map(&:capitalize).join(" ")
    end

    def self.cg_subclass_label(field)
      CG_SUBCLASS_LABELS[field.to_s] || field.to_s.capitalize
    end

  end
end
