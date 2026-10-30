# Behind Cloudflare's proxy, a request reaches kamal-proxy from a Cloudflare edge, so without this
# request.remote_ip (and every rate limit) sees Cloudflare instead of the visitor. Trusting only
# Cloudflare's published ranges keeps the address unforgeable: a client connecting to the server
# directly is recorded by kamal-proxy under its own, untrusted address. Needs `forward_headers: true`
# in the Kamal proxy config so Cloudflare's X-Forwarded-For survives TLS termination.
# shortcut: Cloudflare's ranges as published on 2026-10-30 (https://www.cloudflare.com/ips/); refresh them if Cloudflare adds one.
CLOUDFLARE_RANGES = %w[
  173.245.48.0/20
  103.21.244.0/22
  103.22.200.0/22
  103.31.4.0/22
  141.101.64.0/18
  108.162.192.0/18
  190.93.240.0/20
  188.114.96.0/20
  197.234.240.0/22
  198.41.128.0/17
  162.158.0.0/15
  104.16.0.0/13
  104.24.0.0/14
  172.64.0.0/13
  131.0.72.0/22
  2400:cb00::/32
  2606:4700::/32
  2803:f800::/32
  2405:b500::/32
  2405:8100::/32
  2a06:98c0::/29
  2c0f:f248::/32
].map { IPAddr.new(it) }.freeze

Rails.application.config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + CLOUDFLARE_RANGES
