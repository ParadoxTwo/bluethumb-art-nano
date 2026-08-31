# frozen_string_literal: true

module ArtworksHelper
  PRICE_RANGES = [
    ["Under $500", "0-500"],
    ["$500 – $1,000", "500-1000"],
    ["$1,000 – $2,500", "1000-2500"],
    ["$2,500+", "2500-10000"]
  ].freeze

  SORT_OPTIONS = [
    ["Newest", "newest"],
    ["Price: low to high", "price-asc"],
    ["Price: high to low", "price-desc"],
    ["Popular", "popular"]
  ].freeze

  SIZE_BANDS = [
    ["Small (under 60 cm)", "small"],
    ["Medium (60–100 cm)", "medium"],
    ["Large (over 100 cm)", "large"]
  ].freeze

  COLOUR_SWATCHES = {
    "red" => "#dc2626",
    "orange" => "#ea580c",
    "yellow" => "#ca8a04",
    "green" => "#16a34a",
    "blue" => "#2563eb",
    "purple" => "#9333ea",
    "neutral" => "#78716c"
  }.freeze

  STYLE_ACCENTS = {
    "abstract" => "from-violet-600 to-purple-900",
    "landscape" => "from-emerald-600 to-teal-900",
    "portrait" => "from-rose-500 to-red-800",
    "figurative" => "from-amber-500 to-orange-800",
    "minimalism" => "from-stone-500 to-stone-800",
    "surrealism" => "from-indigo-600 to-blue-900"
  }.freeze

  def artworks_browse_path(facets = {})
    segments = facets.stringify_keys.flat_map { |key, value| [key, value] }
    if segments.any?
      artworks_path(facets: segments.join("/"))
    else
      artworks_path
    end
  end

  def facet_active?(facets, key, value)
    facets[key] == value
  end

  def facet_link_class(facets, key, value)
    if facet_active?(facets, key, value)
      "facet-pill facet-pill-active"
    else
      "facet-pill text-stone-700"
    end
  end

  def sort_link_class(facets, sort_value)
    current = facets["sort"] || "newest"
    current == sort_value ? "sort-pill sort-pill-active" : "sort-pill sort-pill-inactive"
  end

  def facet_remove(facets, key)
    facets.except(key)
  end

  def active_facet_entries(facets)
    entries = []
    if facets["style"].present?
      entries << { key: "style", label: facets["style"].titleize }
    end
    if facets["medium"].present?
      entries << { key: "medium", label: facets["medium"].titleize }
    end
    if facets["price"].present?
      label = PRICE_RANGES.find { |_, range| range == facets["price"] }&.first || facets["price"]
      entries << { key: "price", label: label }
    end
    if facets["size"].present?
      label = SIZE_BANDS.find { |_, band| band == facets["size"] }&.first || facets["size"].titleize
      entries << { key: "size", label: label }
    end
    if facets["orientation"].present?
      entries << { key: "orientation", label: facets["orientation"].titleize }
    end
    if facets["colour"].present?
      entries << { key: "colour", label: facets["colour"].titleize }
    end
    if facets["q"].present?
      entries << { key: "q", label: %("#{facets["q"]}") }
    end
    entries
  end

  def style_accent_class(style)
    STYLE_ACCENTS.fetch(style, "from-stone-600 to-stone-900")
  end

  def artwork_image_tag(artwork, **options)
    if artwork.image.attached?
      image_tag artwork.image, **options
    else
      tag.div class: "bg-stone-200 #{options[:class]}" do
        tag.span artwork.title, class: "sr-only"
      end
    end
  end

  def hue_family_swatch_style(hue)
    colour = COLOUR_SWATCHES.fetch(hue, "#78716c")
    "background-color: #{colour}"
  end

  def browse_page_title(facets)
    if facets["q"].present?
      "Search: #{facets["q"]}"
    elsif facets["style"].present?
      "#{facets["style"].titleize} Artworks"
    else
      "Browse Artworks"
    end
  end

  # Props handed to the ColourPicker island. Rails owns the URL; the island
  # never hardcodes a route or talks to the palette service directly.
  def colour_picker_props(artwork)
    {
      swatches: artwork.palette_swatches,
      endpoint: artwork_colour_matches_path(artwork.slug)
    }
  end
end
