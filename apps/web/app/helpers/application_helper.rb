# frozen_string_literal: true

module ApplicationHelper
  def format_price(cents)
    number_to_currency(cents / 100.0, unit: "$", precision: 0)
  end

  def nav_link_class(path)
    base = "text-stone-700 hover:text-stone-900 transition-colors"
    current_page?(path) ? "#{base} font-semibold text-stone-900" : base
  end

  def artist_initials(name)
    name.to_s.split.map { |part| part[0] }.join.upcase.first(2)
  end
end
