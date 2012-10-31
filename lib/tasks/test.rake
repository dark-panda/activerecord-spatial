
namespace :test do
  desc "Dumps data from the geometry_columns and spatial_ref_sys tables."
  task :postgis_dump => :environment do
    abcs = ActiveRecord::Base.configurations
    ENV['PGHOST']     = abcs[Rails.env]["host"] if abcs[Rails.env]["host"]
    ENV['PGPORT']     = abcs[Rails.env]["port"].to_s if abcs[Rails.env]["port"]
    ENV['PGPASSWORD'] = abcs[Rails.env]["password"].to_s if abcs[Rails.env]["password"]
    search_path = abcs[Rails.env]["schema_search_path"]
    unless search_path.blank?
      search_path = search_path.split(",").map{|search_path| "--schema=#{search_path.strip}" }.join(" ")
    end

    tables = %w{ geometry_columns spatial_ref_sys }.select do |table|
      ActiveRecord::Base.connection.table_exists?(table) &&
        !ActiveRecord::Base.connection.view_exists?(table)
    end

    pp tables

    unless tables.empty?
      `pg_dump -i -U "#{abcs[Rails.env]["username"]}" --data-only -t #{tables.join(' -t ')} -x -O -f db/#{Rails.env}_postgis_tables.sql #{search_path} #{abcs[Rails.env]["database"]}`
    else
      File.open("db/#{Rails.env}_postgis_tables.sql", 'w') do |fp|
        fp.puts "-- empty, do geometry_columns and spatial_ref_sys tables exist?"
      end
    end
  end

  desc "Loads the geometry_columns and spatial_ref_sys tables."
  task :postgis_load => :environment do
    abcs = ActiveRecord::Base.configurations
    ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
    ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
    ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]

    `psql -U "#{abcs["test"]["username"]}" -f #{Rails.root}/db/#{Rails.env}_postgis_tables.sql #{abcs["test"]["database"]}`
  end

  desc "Dumps and loads the geometry_columns and spatial_ref_sys tables."
  task :postgis_clone => [ :postgis_dump, :postgis_load ]
end

Rake::Task['test:prepare'].enhance(['test:postgis_clone'])

