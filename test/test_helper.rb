
if RUBY_VERSION >= '1.9'
  require 'simplecov'

  SimpleCov.command_name('Unit Tests')
  SimpleCov.start do
    add_filter '/test/'
  end
end

require 'rubygems'
require 'minitest/autorun'

if RUBY_VERSION >= '1.9'
  require 'minitest/reporters'
end

ACTIVERECORD_GEM_VERSION = ENV['ACTIVERECORD_GEM_VERSION'] || '~> 3.2.0'
gem 'activerecord', ACTIVERECORD_GEM_VERSION

require 'active_support'
require 'active_support/core_ext/module/aliasing'
require 'active_support/dependencies'
require 'active_record'
require 'active_record/fixtures'
require 'logger'

require File.join(File.dirname(__FILE__), %w{ .. lib activerecord-spatial })

POSTGIS_PATHS = [
  ENV['POSTGIS_PATH'],
  '/opt/local/share/postgresql*/contrib/postgis-*',
  '/usr/share/postgresql*/contrib/postgis-*',
  '/usr/pgsql-*/share/contrib/postgis-*',
].compact

puts "Testing against ActiveRecord #{Gem.loaded_specs['activerecord'].version.to_s}"

puts "Ruby version #{RUBY_VERSION} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "Geos library version #{Geos::VERSION}" if defined?(Geos::VERSION)
puts "GEOS version #{Geos::GEOS_VERSION}"
puts "GEOS extensions version #{Geos::GEOS_EXTENSIONS_VERSION}"
if defined?(Geos::FFIGeos)
  puts "Using #{Geos::FFIGeos.geos_library_paths.join(', ')}"
end

ActiveRecord::Base.logger = Logger.new("debug.log") if ENV['ENABLE_LOGGER']
ActiveRecord::Base.configurations = {
  'arunit' => {}
}

%w{
  database.yml
  local_database.yml
}.each do |file|
  file = File.join('test', file)

  next unless File.exists?(file)

  configuration = YAML.load(File.read(file))

  if configuration['arunit']
    ActiveRecord::Base.configurations['arunit'].merge!(configuration['arunit'])
  end

  if defined?(JRUBY_VERSION) && configuration['jdbc']
    ActiveRecord::Base.configurations['arunit'].merge!(configuration['jdbc'])
  end
end

ActiveRecord::Base.establish_connection 'arunit'
ARBC = ActiveRecord::Base.connection

if postgresql_version = ARBC.select_rows('SELECT version()').first.first
  puts "PostgreSQL info from version(): #{postgresql_version}"
end

puts "Checking for PostGIS install"
2.times do
  begin
    if postgis_version = ActiveRecordSpatial::POSTGIS[:lib]
      puts "PostGIS info from postgis_full_version(): #{postgis_version}"
      break
    end
  rescue ActiveRecord::StatementInvalid
    puts "Trying to install PostGIS. If this doesn't work, you'll have to do this manually!"

    plpgsql = ARBC.select_rows(%{SELECT count(*) FROM pg_language WHERE lanname = 'plpgsql'}).first.first.to_i
    if plpgsql == 0
      ARBC.execute(%{CREATE LANGUAGE plpgsql})
    end

    %w{
      postgis.sql
      spatial_ref_sys.sql
    }.each do |file|
      if !(found = Dir.glob(POSTGIS_PATHS).collect { |path|
        File.join(path, file)
      }.first)
        puts "ERROR: Couldn't find #{file}. Try setting the POSTGIS_PATH to give us a hint!"
        exit
      else
        ARBC.execute(File.read(found))
      end
    end
  end
end

class ActiveRecordSpatialTestCase < ActiveRecord::TestCase
  BASE_PATH = Pathname.new(File.dirname(__FILE__))

  include ActiveRecord::TestFixtures
  self.fixture_path = BASE_PATH.join('fixtures')

  REGEXP_WKB_HEX = /[A-Fa-f0-9\s]+/

  POINT_WKT = 'POINT(10 10.01)'
  POINT_EWKT = 'SRID=4326; POINT(10 10.01)'
  POINT_EWKT_WITH_DEFAULT = 'SRID=default; POINT(10 10.01)'
  POINT_WKB = "0101000000000000000000244085EB51B81E052440"
  POINT_WKB_BIN = "\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x24\x40\x85\xEB\x51\xB8\x1E\x05\x24\x40"
  POINT_EWKB = "0101000020E6100000000000000000244085EB51B81E052440"
  POINT_EWKB_BIN = "\x01\x01\x00\x00\x20\xE6\x10\x00\x00\x00\x00\x00\x00\x00\x00\x24\x40\x85\xEB\x51\xB8\x1E\x05\x24\x40"
  POINT_G_LAT_LNG = "(10.01, 10)"
  POINT_G_LAT_LNG_URL_VALUE = "10.01,10"

  POLYGON_WKT = 'POLYGON((0 0, 1 1, 2.5 2.5, 5 5, 0 0))'
  POLYGON_EWKT = 'SRID=4326; POLYGON((0 0, 1 1, 2.5 2.5, 5 5, 0 0))'
  POLYGON_WKB = "
    0103000000010000000500000000000000000000000000000000000000000000000000F
    03F000000000000F03F0000000000000440000000000000044000000000000014400000
    00000000144000000000000000000000000000000000
  ".gsub(/\s/, '')
  POLYGON_WKB_BIN = [
    "\x01\x03\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xF0\x3F\x00",
    "\x00\x00\x00\x00\x00\xF0\x3F\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00",
    "\x00\x00\x04\x40\x00\x00\x00\x00\x00\x00\x14\x40\x00\x00\x00\x00\x00\x00\x14",
    "\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ].join
  POLYGON_EWKB = "
    0103000020E610000001000000050000000000000000000000000000000000000000000
    0000000F03F000000000000F03F00000000000004400000000000000440000000000000
    1440000000000000144000000000000000000000000000000000
  ".gsub(/\s/, '')
  POLYGON_EWKB_BIN = [
    "\x01\x03\x00\x00\x20\xE6\x10\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\xF0\x3F\x00\x00\x00\x00\x00\x00\xF0\x3F\x00\x00",
    "\x00\x00\x00\x00\x04\x40\x00\x00\x00\x00\x00\x00\x04\x40\x00\x00\x00",
    "\x00\x00\x00\x14\x40\x00\x00\x00\x00\x00\x00\x14\x40\x00\x00\x00\x00",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ].join

  POLYGON_WITH_INTERIOR_RING = "POLYGON((0 0, 5 0, 5 5, 0 5, 0 0),(4 4, 4 1, 1 1, 1 4, 4 4))"

  LINESTRING_WKT = "LINESTRING (0 0, 5 5, 5 10, 10 10)"

  GEOMETRYCOLLECTION_WKT = 'GEOMETRYCOLLECTION (
    MULTIPOLYGON (
      ((0 0, 1 0, 1 1, 0 1, 0 0)),
      (
        (10 10, 10 14, 14 14, 14 10, 10 10),
        (11 11, 11 12, 12 12, 12 11, 11 11)
      )
    ),
    POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)),
    POLYGON ((0 0, 5 0, 5 5, 0 5, 0 0), (4 4, 4 1, 1 1, 1 4, 4 4)),
    MULTILINESTRING ((0 0, 2 3), (10 10, 3 4)),
    LINESTRING (0 0, 2 3),
    MULTIPOINT ((0 0), (2 3)),
    POINT (9 0)
  )'

  BOUNDS_G_LAT_LNG = "((0.1, 0.1), (5.2, 5.2))"
  BOUNDS_G_LAT_LNG_URL_VALUE = '0.1,0.1,5.2,5.2'

  class << self
    def load_models(*args)
      options = args.extract_options!

      args.each do |model|
        model = model.to_s
        klass = model.classify

        ActiveSupport::Dependencies.load_file(BASE_PATH.join("models/#{model}.rb"), [ klass ])

        ActiveRecord::Base.silence do
          fixtures model.pluralize
        end
      end
    end

    def load_default_models
      load_models(:foo, :bar)

      Foo.class_eval do
        has_many_spatially :foos
        has_many_spatially :bars
      end

      Bar.class_eval do
        has_many_spatially :foos
        has_many_spatially :bars
      end
    end

    def after_suite
      ActiveSupport::Dependencies.clear
    end
  end

  def setup
    if ActiveRecord::Base.logger
      ActiveRecord::Base.logger.debug("Beginning tests for #{self.class.name}##{self.method_name}")
    end
  end

  def assert_saneness_of_point(point)
    assert_kind_of(Geos::Point, point)
    assert_equal(10.01, point.lat)
    assert_equal(10, point.lng)
  end

  def assert_saneness_of_polygon(polygon)
    assert_kind_of(Geos::Polygon, polygon)
    cs = polygon.exterior_ring.coord_seq
    assert_equal([
      [ 0, 0 ],
      [ 1, 1 ],
      [ 2.5, 2.5 ],
      [ 5, 5 ],
      [ 0, 0 ]
    ], cs.to_a)
  end
end

module ActiveRecord
  class SQLCounter
    cattr_accessor :ignored_sql
    self.ignored_sql = [
      /^PRAGMA (?!(table_info))/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/,
      /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/,
      /^SHOW max_identifier_length/, /^BEGIN/, /^COMMIT/, /^ROLLBACK/, /\WFROM pg_/
    ]

    cattr_accessor :log
    self.log = []

    attr_reader :ignore

    def initialize(ignore = self.class.ignored_sql)
      @ignore   = ignore
    end

    def call(name, start, finish, message_id, values)
      sql = values[:sql]

      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      return if 'CACHE' == values[:name] || ignore.any? { |x| x =~ sql }
      self.class.log << sql
    end
  end

  ActiveSupport::Notifications.subscribe('sql.active_record', SQLCounter.new)
end

class SpatialTestRunner < MiniTest::Reporters::SpecReporter
  def _run_suite(*args)
    suite = args.first

    begin
      suite.before_suite if suite.respond_to?(:before_suite)
      super(*args)
    ensure
      suite.after_suite if suite.respond_to?(:after_suite)
    end
  end
end

class SpatialTestRunner < MiniTest::Reporters::SpecReporter
  def before_suite(suite)
    super(suite)
    suite.before_suite if suite.respond_to?(:before_suite)
  end

  def after_suite(suite)
    super(suite)
    suite.after_suite if suite.respond_to?(:after_suite)
  end
end

if RUBY_VERSION >= '1.9'
  MiniTest::Reporters.use!(SpatialTestRunner.new)
end

