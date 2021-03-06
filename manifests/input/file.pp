# == Define: logstash::input::file
#
#   Stream events from files.  By default, each event is assumed to be one
#   line. If you want to join lines, you'll want to use the multiline
#   filter.  Files are followed in a manner similar to "tail -0F". File
#   rotation is detected and handled by this input.
#
#
# === Parameters
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*discover_interval*]
#   How often we expand globs to discover new files to watch.
#   Value type is number
#   Default value: 15
#   This variable is optional
#
# [*exclude*]
#   Exclusions (matched against the filename, not full path). Globs are
#   valid here, too. For example, if you have  path =&gt; "/var/log/*"
#   you might want to exclude gzipped files:  exclude =&gt; "*.gz"
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*path*]
#   TODO(sissel): This should switch to use the 'line' codec by default
#   once file following The path to the file to use as an input. You can
#   use globs here, such as /var/log/*.log Paths must be absolute and
#   cannot be relative.
#   Value type is array
#   Default value: None
#   This variable is required
#
# [*sincedb_path*]
#   Where to write the since database (keeps track of the current position
#   of monitored log files). The default will write sincedb files to some
#   path matching "$HOME/.sincedb*"
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*sincedb_write_interval*]
#   How often to write a since database with the current position of
#   monitored log files.
#   Value type is number
#   Default value: 15
#   This variable is optional
#
# [*start_position*]
#   Choose where logstash starts initially reading files - at the
#   beginning or at the end. The default behavior treats files like live
#   streams and thus starts at the end. If you have old data you want to
#   import, set this to 'beginning'  This option only modifieds "first
#   contact" situations where a file is new and not seen before. If a file
#   has already been seen before, this option has no effect.
#   Value can be any of: "beginning", "end"
#   Default value: "end"
#   This variable is optional
#
# [*stat_interval*]
#   How often we stat files to see if they have been modified. Increasing
#   this interval will decrease the number of system calls we make, but
#   increase the time to detect new log lines.
#   Value type is number
#   Default value: 1
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*type*]
#   Add a 'type' field to all events handled by this input.  Types are
#   used mainly for filter activation.  If you create an input with type
#   "foobar", then only filters which also have type "foobar" will act on
#   them.  The type is also stored as part of the event itself, so you can
#   also use the type to search for in the web interface.  If you try to
#   set a type on an event that already has one (for example when you send
#   an event from a shipper to an indexer) then a new input will not
#   override the existing type. A type set at the shipper stays with that
#   event for its life even when sent to another LogStash server.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*instances*]
#   Array of instance names to which this define is.
#   Value type is array
#   Default value: [ 'array' ]
#   This variable is optional
#
# === Extra information
#
#  This define is created based on LogStash version 1.2.2.dev
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.2.2.dev/inputs/file
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::file (
  $path,
  $add_field              = '',
  $codec                  = '',
  $debug                  = '',
  $discover_interval      = '',
  $exclude                = '',
  $sincedb_path           = '',
  $sincedb_write_interval = '',
  $start_position         = '',
  $stat_interval          = '',
  $tags                   = '',
  $type                   = '',
  $instances              = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_file_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/file/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_file_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/file/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($exclude != '') {
    validate_array($exclude)
    $arr_exclude = join($exclude, '\', \'')
    $opt_exclude = "  exclude => ['${arr_exclude}']\n"
  }

  if ($path != '') {
    validate_array($path)
    $arr_path = join($path, '\', \'')
    $opt_path = "  path => ['${arr_path}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($sincedb_write_interval != '') {
    if ! is_numeric($sincedb_write_interval) {
      fail("\"${sincedb_write_interval}\" is not a valid sincedb_write_interval parameter value")
    } else {
      $opt_sincedb_write_interval = "  sincedb_write_interval => ${sincedb_write_interval}\n"
    }
  }

  if ($discover_interval != '') {
    if ! is_numeric($discover_interval) {
      fail("\"${discover_interval}\" is not a valid discover_interval parameter value")
    } else {
      $opt_discover_interval = "  discover_interval => ${discover_interval}\n"
    }
  }

  if ($stat_interval != '') {
    if ! is_numeric($stat_interval) {
      fail("\"${stat_interval}\" is not a valid stat_interval parameter value")
    } else {
      $opt_stat_interval = "  stat_interval => ${stat_interval}\n"
    }
  }

  if ($start_position != '') {
    if ! ($start_position in ['beginning', 'end']) {
      fail("\"${start_position}\" is not a valid start_position parameter value")
    } else {
      $opt_start_position = "  start_position => \"${start_position}\"\n"
    }
  }

  if ($sincedb_path != '') {
    validate_string($sincedb_path)
    $opt_sincedb_path = "  sincedb_path => \"${sincedb_path}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n file {\n${opt_add_field}${opt_codec}${opt_debug}${opt_discover_interval}${opt_exclude}${opt_path}${opt_sincedb_path}${opt_sincedb_write_interval}${opt_start_position}${opt_stat_interval}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
