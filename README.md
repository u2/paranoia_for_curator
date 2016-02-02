# ParanoiaForCurator

ParanoiaForCurator is a soft-delete implementation for [Curator](https://github.com/braintree/curator).

When your app is using ParanoiaForCurator, calling `delete` on an Curator::Repository object doesn't actually destroy the database record, but just *hides* it. ParanoiaForCurator does this by setting a `deleted_at` field to the current time when you `delete` a record, and hides it by scoping all queries on your model to only include records which do not have a `deleted_at` field.

If you wish to actually destroy an object you may call `really_delete`.

## Installation & Usage

Firstly:

``` ruby
gem "paranoia_for_curator", "~> 0.0.3"
```

Then run:

``` shell
bundle install
```

Updating is as simple as `bundle update paranoia_for_curator`.

### Usage

#### In your model:

``` ruby
class Client
  include Curator::Model
  attribute :deleted_at, Time, default: nil
  # ...
end
```

#### In your repository:

``` ruby
class ClientRepository
  include Curator::Repository
  acts_as_paranoid
  # ...
end
```

Hey presto, it's there! Calling `delete` will now set the `deleted_at` column:


``` ruby
>> client.deleted_at
# => nil
>> ClientRepository.delete client
# => client
>> client.deleted_at
# => [current timestamp]
```

If you really want it gone *gone*, call `really_delete`:

``` ruby
>> client.deleted_at
# => nil
>> ClientRepository.really_delete(client)
# => client
```

If you want to use a column other than `deleted_at`, you can pass it as an option:

``` ruby
class Client
  include Curator::Model
  attribute :destroyed_at, Time, default: nil
  # ...
end

class ClientRepository
  include Curator::Repository
  acts_as_paranoid column: :destroyed_at

  ...
end
```

If you want to find all records, even those which are deleted:

``` ruby
Client.all_with_deleted
```

If you want to find only the deleted records:

``` ruby
Client.only_deleted
```

If you want to check if a record is soft-deleted:

``` ruby
client.paranoia_deleted?
# or
client.deleted?
```

If you want to restore a record:

``` ruby
ClientRepository.restore(id)
```

If you want to restore a whole bunch of records:

``` ruby
ClientRepository.restore([id1, id2, ..., idN])
```

For more information, please look at the tests.

## License

This gem is released under the MIT license.
