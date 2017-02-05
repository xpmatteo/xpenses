#!/usr/bin/env ruby

require_relative 'lib/env-scripts-preamble'

# table names must be unique within region and can't be tagged
# use the convention [component]-[tablename]-[environment]
table_name = "xpenses-movements-#{@env}"
attribute_defs = [
  { attribute_name: 'month',        attribute_type: 'S' },
  { attribute_name: 'id',      attribute_type: 'S' },
]
key_schema = [
  { attribute_name: 'month', key_type: 'HASH' },
  { attribute_name: 'id', key_type: 'RANGE' },
]
request = {
  attribute_definitions:    attribute_defs,
  table_name:               table_name,
  key_schema:               key_schema,
  provisioned_throughput:   { read_capacity_units: 5, write_capacity_units: 5 }
}
create_table table_name, request
