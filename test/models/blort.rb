# frozen_string_literal: true

unless ActiveRecordSpatialTestCase.table_exists?('blorts')
  ActiveRecord::Migration.create_table(:blorts) do |t|
    t.text :name
    t.integer :foo_id
  end
end

class Blort < ActiveRecord::Base
  belongs_to :foo
end
