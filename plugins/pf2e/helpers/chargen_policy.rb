module AresMUSH
  module Pf2e

    # Chargen policy gates — open lists only. Expand constants to unlock later.
    # Player docs: TapestryMUSH OOC/Open Character Options.md

    CG_OPEN_CLASSES = %w[
      bard champion cleric druid fighter investigator
      ranger rogue sorcerer witch wizard
    ].freeze

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

    CG_OPEN_CONTACTS = %w[
      faiths_flamekeeper the_inscribed_one silence_in_snow
      spinner_of_threads wilding_steward
    ].freeze

    CG_OPEN_BLOODLINES = %w[imperial elemental fey angelic].freeze
    CG_OPEN_CAUSES = %w[justice liberation redemption obedience].freeze
    CG_OPEN_MUSES = %w[maestro enigma polymath warrior].freeze
    CG_OPEN_RACKETS = %w[ruffian scoundrel thief mastermind].freeze
    CG_OPEN_METHODOLOGIES = %w[
      empiricism forensic_medicine interrogation alchemical_sciences
    ].freeze
    CG_OPEN_ORDERS = %w[animal leaf storm wild wave flame].freeze
    CG_OPEN_EDGES = %w[precision flurry outwit].freeze
    CG_OPEN_DOCTRINES = %w[cloistered warpriest].freeze
    # necromancy excluded — undeath hard line
    CG_OPEN_SCHOOLS = %w[
      abjuration conjuration divination enchantment
      evocation illusion transmutation universalist
    ].freeze

    CG_SUBCLASS_OPEN = {
      "contact" => CG_OPEN_CONTACTS,
      "bloodline" => CG_OPEN_BLOODLINES,
      "cause" => CG_OPEN_CAUSES,
      "muse" => CG_OPEN_MUSES,
      "racket" => CG_OPEN_RACKETS,
      "methodology" => CG_OPEN_METHODOLOGIES,
      "order" => CG_OPEN_ORDERS,
      "edge" => CG_OPEN_EDGES,
      "school" => CG_OPEN_SCHOOLS,
      "doctrine" => CG_OPEN_DOCTRINES
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

    def self.cg_class_open?(slug)
      CG_OPEN_CLASSES.include?(slug.to_s.strip.downcase)
    end

    def self.cg_subclass_field_for_class(class_slug)
      CG_REQUIRED_SUBCLASS[class_slug.to_s.strip.downcase]
    end

    def self.cg_subclass_open?(field, option_slug)
      list = CG_SUBCLASS_OPEN[field.to_s]
      return false unless list
      list.include?(option_slug.to_s.strip.downcase)
    end

    def self.cg_subclass_name(slug)
      key = slug.to_s.strip.downcase
      CG_SUBCLASS_NAMES[key] || key.split("_").map(&:capitalize).join(" ")
    end

    def self.cg_subclass_label(field)
      CG_SUBCLASS_LABELS[field.to_s] || field.to_s.capitalize
    end

  end
end
