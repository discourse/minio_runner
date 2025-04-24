# MinioRunner

Manages the installed [minio](https://min.io/) binary and handles setup and
teardown of the minio server.

## Description

This is a simple way of managing the locally installed minio server using an
installed binary. This can be used to start/stop the server when running
automated tests or developing locally against an S3 alternative. It also
installs the [`mc` (minio client)](https://min.io/docs/minio/linux/reference/minio-mc.html) CLI
tool to make interacting with the server easier.

This an extremely focused gem and will not focus on all possible different
configurations and binaries of minio. Only Linux and macOS platforms are
supported at this time.

This gem was inspired by the [webdrivers](https://github.com/titusfortner/webdrivers)
project.

## Usage

In your Gemfile:

```ruby
gem 'minio_runner', require: false
```

In your project:

```ruby
require 'minio_runner'
```

The minio runner will not automatically locate, download, and start minio. You
will need to use the following calls; for example in your before/after suite
setup and teardown for rspec.

```ruby
# Locate and download the minio binary if it does not exist, and start the server with provided configuration.
# The binary will be updated if the new version (which is checked every time `MinioRunner.cache_time` expires)
# is greater than the installed version.
MinioRunner.start

# Start the server without attempting to locate or download the minio binary
MinioRunner.start(install: false)

# Stop the currently running server.
MinioRunner.stop
```

### Download Location

The default download location is `~/.minio_runner` directory, and this is configurable:

 ```ruby
MinioRunner.config.install_dir = '/minio_runner/install/dir'
```

Alternatively, you can define the path via the `MINIO_RUNNER_INSTALL_DIR` environment variable.
The environment variable will take precedence.

### Caching minio version

You can set Minio Runner to only look for updates if the previous check
was longer ago than a specified number of seconds.

```ruby
MinioRunner.config.cache_time = 86_400 # Default: 86,400 Seconds (24 hours)
```

Alternatively, you can define the time via the `MINIO_RUNNER_CACHE_TIME` environment variable.
The environment variable will take precedence.

### Rake tasks

You can run `bundle exec rake -T -a` to see all the rake tasks. The ones specifically related to
minio runner will be namespaced into minio_runner. 

### Logging

The logging level can be configured for debugging purpose via the `MINIO_RUNNER_LOG_LEVEL` environment variable.

The available values are found in https://ruby-doc.org/stdlib-2.4.0/libdoc/logger/rdoc/Logger/Severity.html.

The minio server will log to the `install_dir` in a `minio.log` file.

## Minio configuration

Only a small subset of minio configuration (defined at https://min.io/docs/minio/linux/reference/minio-server/minio-server.html#environment-variables)
is supported. The subset of configuration options can be found from running the `list_configurable_env`
rake task.

All minio configuration can also be specified via `MinioRunner.config`, and anything
set in this way will override environment variables. Environment variables should
be in the format `MINIO_RUNNER_MINIO_X`:

```ruby
MinioRunner.config do |config|
  config.minio_port = 9000 # MINIO_RUNNER_MINIO_PORT
  config.minio_console_address = 9001 # MINIO_RUNNER_MINO_CONSOLE_ADDRESS
  config.minio_domain = 'minio.local' # MINIO_RUNNER_MINIO_DOMAIN
end
```

The configuration in ruby will use the exact same names as the environment
variables for minio.

### Aliases

By default a `local` alias is automatically created via the `mc` tool, which will point
to `localhost` at the configured `MINIO_RUNNER_MINIO_PORT`. No other aliases are supported
at this time.

### Buckets

You can specify the buckets that will be created (if they do not exist) when the minio server
starts using the `MinioRunner.config` call above or using the `MINIO_RUNNER_BUCKETS` environment
variable with a comma-separated list. Only S3-compatible buckets will be made.

```ruby
MinioRunner.config.buckets = ["testbucket", "media"]

# MINIO_RUNNER_BUCKETS="testbucket,media"
```

Buckets will be made public to anonymous users if they are specified in the `public_buckets` configuration,
which can also be set with the `MINIO_RUNNER_PUBLIC_BUCKETS` environment variable.

### Hosts file

**An important step** that you must manually do yourself is to modify your `/etc/hosts` file to add an
entry for your minio server defined by `MINIO_RUNNER_MINIO_DOMAIN` and also for any bucket defined
via `MINIO_RUNNER_BUCKETS`, since they will be used as virtual-host style buckets.

For example:

```
127.0.0.1 minio.local
127.0.0.1 testbucket.minio.local
```

For macOS, there are some issues which cause large delays for .local domain names. See
https://superuser.com/a/1297335/245469 and https://stackoverflow.com/a/17982964/875941. To
resolve this, you need to add IPV6 lookup addresses to the hosts file, and it helps to put
all the entries on one line.

```
::1 minio.local testbucket.minio.local
fe80::1%lo0 minio.local testbucket.minio.local
127.0.0.1 minio.local testbucket.minio.local
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/discourse/minio_runner.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
