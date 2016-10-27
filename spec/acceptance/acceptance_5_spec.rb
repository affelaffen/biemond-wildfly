require 'spec_helper_acceptance'
require 'json'

describe 'Acceptance case five. Deployment on standalone mode with Wildfly 9' do
  context 'Initial install Wildfly 9, deployment and verification' do
    it 'Should apply the manifest without error' do
      pp = <<-EOS
          case $::osfamily {
            'RedHat': {
              java::oracle { 'jdk8' :
                ensure  => 'present',
                version => '8',
                java_se => 'jdk',
                before  => Class['wildfly']
              }


              $java_home = '/usr/java/default'
             }
            'Debian': {
              class { 'java':
                before => Class['wildfly']
              }

              $java_home = "/usr/lib/jvm/java-7-openjdk-${::architecture}"
           }
          }

          class { 'wildfly':
            java_home      => $java_home,
          } ->

          wildfly::deployment { 'hawtio.war':
            source => 'http://central.maven.org/maven2/io/hawt/hawtio-web/1.4.66/hawtio-web-1.4.66.war'
          }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true, :acceptable_exit_codes => [0, 2])
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
      shell('sleep 15')
    end

    it 'service wildfly' do
      expect(service('wildfly')).to be_enabled
      expect(service('wildfly')).to be_running
    end

    it 'runs on port 8080' do
      expect(port(8080)).to be_listening
    end

    it 'welcome page' do
      shell('curl localhost:8080', :acceptable_exit_codes => 0) do |r|
        expect(r.stdout).to include 'Welcome'
      end
    end

    it 'downloaded WAR file' do
      shell('ls -la /tmp/hawtio-web-1.4.66.war', :acceptable_exit_codes => 0) do |r|
        expect(r.stdout).to include '/tmp/hawtio-web-1.4.66.war'
      end
    end

    it 'deployed application' do
      shell('/opt/wildfly/bin/jboss-cli.sh --connect "/deployment=hawtio.war:read-resource(recursive=true)"',
            :acceptable_exit_codes => 0) do |r|
        expect(r.stdout).to include '"outcome" => "success"'
      end
      shell('curl localhost:8080/'.concat('hawtio/'), :acceptable_exit_codes => 0) do |r|
        expect(r.stdout).to include 'hawtio'
      end
    end
  end
end
