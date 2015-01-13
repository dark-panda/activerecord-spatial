# -*- encoding: utf-8 -*-

require File.expand_path('../lib/activerecord-spatial/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "activerecord-spatial"
  s.version = ActiveRecordSpatial::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "ActiveRecord Spatial gives AR the ability to work with PostGIS columns."
  s.summary = s.description
  s.email = "dark.panda@gmail.com"
  s.license = "MIT"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "https://github.com/dark-panda/activerecord-spatial"
  s.require_paths = ["lib"]

  s.add_dependency("rails", [">= 5.0"])
  s.add_dependency("geos-extensions", [">= 0.5"])
end

