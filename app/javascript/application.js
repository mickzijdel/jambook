// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Installable as a home-screen app; the worker caches nothing, live pages always come from the server.
if ("serviceWorker" in navigator) navigator.serviceWorker.register("/service-worker.js")
