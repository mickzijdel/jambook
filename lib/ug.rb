require "json"
require "nokogiri"

# Reads the public data Ultimate Guitar embeds in its pages. For a host's own saved tabs only.
module Ug
  def self.page_data(html)
    store = Nokogiri::HTML(html).at_css(".js-store")&.attr("data-content")
    store ? JSON.parse(store).dig("store", "page", "data") || {} : {}
  end
end
