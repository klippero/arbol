ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup"
ENV["BOOTSNAP_CACHE_DIR"] ||= File.expand_path("tmp/cache", __dir__)
require "bootsnap/setup"
