require 'i18n'
require 'curator'
require 'paranoia_for_curator'
require 'timecop'

TMP_PATH = File.expand_path(File.dirname(__FILE__) + '/../tmp')

Curator.configure(:memory) do |config|
  config.environment = 'test'
  config.migrations_path = "/tmp/curator_migrations"
end

RSpec.configure do |config|
  config.after(:each) do
    Curator.repositories = Set.new
  end

  config.around(:each) do |test|
    @transient_classes = []
    test.call
    @transient_classes.each do |name|
      begin
        Object.send(:remove_const, name)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end

def def_transient_class(name, &block)
  @transient_classes << name
  raise("Cannot define transient class, constant #{name} is already defined") if Object.const_defined?(name)
  Object.const_set name, Class.new(&block)
end

def with_config(&block)
  around(:each) do |example|
    old_config = Curator.config
    old_data_store = Curator.data_store
    Curator.instance_variable_set('@data_store', nil)
    block.call
    example.run
    Curator.data_store.reset!
    Curator.instance_variable_set('@config', old_config)
    Curator.instance_variable_set('@data_store', old_data_store)
    Curator.repositories = Set.new
  end
end

def write_migration(collection_name, filename, contents)
  collection_migration_directory = File.join(Curator.config.migrations_path, collection_name)
  FileUtils.mkdir_p(collection_migration_directory)

  File.open(File.join(collection_migration_directory, filename), 'w') do |file|
    file.write(contents)
  end
end
