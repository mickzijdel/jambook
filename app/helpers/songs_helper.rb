module SongsHelper
  # Links only to http(s) addresses; the model validates the same, this guards older rows.
  def web_link_to(label, url)
    if url.to_s.match?(%r{\Ahttps?://\S+\z}i)
      link_to label, url, rel: "noopener noreferrer", target: "_blank"
    end
  end
end
