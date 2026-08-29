source "https://rubygems.org"

# Standalone Jekyll (we host on AWS, not GitHub Pages, so we're not pinned to the
# `github-pages` gem's older Jekyll version and plugin allow-list).
gem "jekyll", "~> 4.3"

group :jekyll_plugins do
  gem "jekyll-feed"     # generates /feed.xml (RSS/Atom)
  gem "jekyll-sitemap"  # generates /sitemap.xml
  gem "jekyll-seo-tag"  # <title>/OpenGraph/meta via {% seo %}
end

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]

# Windows/JRuby don't include zoneinfo; needed for time-zone handling.
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
