#
# Manages Wildfly patches offline
#
define wildfly::patch::offline(
  Stdlib::Unixpath $source,
  Optional[Boolean] $override_all = false,
  Array $override = [],
  Array $preserve = []) {

  require wildfly::install

  $args = patch_args($source, $override_all, $override, $preserve)

  exec { "Patch ${title}":
    command     => "jboss-cli.sh 'patch apply ${args}'",
    unless      => "jboss-cli.sh 'patch history' | grep -q ${title}",
    path        => ['/bin', '/usr/bin', '/sbin', "${wildfly::dirname}/bin"],
    environment => "JAVA_HOME=${wildfly::java_home}",
  }
}
