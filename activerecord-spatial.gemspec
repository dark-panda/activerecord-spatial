# -*- encoding: utf-8 -*-

require File.expand_path('../lib/activerecord-spatial/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "activerecord-spatial"
  s.version = ActiveRecordSpatial::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "ActiveRecord Spatial gives AR the ability to work with PostGIS columns."
  s.summary = s.description
  s.email = "code@zoocasa.com"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "https://github.com/zoocasa/activerecord-spatial"
  s.require_paths = ["lib"]

  s.add_dependency("activerecord", ["~> 3.2"])
  s.add_dependency("geos-extensions", [">= 0.3.0.dev"])
  if RUBY_PLATFORM == "java"
    s.add_development_dependency("activerecord-jdbcpostgresql-adapter")
  else
    s.add_development_dependency("pg")
  end
  s.add_development_dependency("rdoc")
  s.add_development_dependency("rake", ["~> 0.9"])
  s.add_development_dependency("minitest")
  s.add_development_dependency("turn")
end

