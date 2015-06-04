# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::registry' do
  describe 'ubuntu' do
    before do
      # Lame we must still stub this, since the recipe contains shell
      # guards.  Need to work on a way to resolve this.
      stub_command('glance-manage db_version').and_return(true)
    end

    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    include Helpers
    include_context 'image-stubs'
    include_examples 'common-logging-recipe'
    include_examples 'common-packages'
    include_examples 'cache-directory'
    include_examples 'glance-directory'

    it 'converges when configured to use sqlite' do
      node.set['openstack']['db']['image']['service_type'] = 'sqlite'

      expect { chef_run }.to_not raise_error
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('python-mysqldb')
    end

    it 'honors package name and option overrides for mysql python packages' do
      node.set['openstack']['image']['platform']['package_overrides'] = '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes'
      node.set['openstack']['db']['python_packages']['mysql'] = ['my-mysql-py']

      expect(chef_run).to upgrade_package('my-mysql-py').with(options: '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes')
    end

    %w(db2 postgresql).each do |service_type|
      it "upgrades #{service_type} python packages if chosen" do
        node.set['openstack']['db']['image']['service_type'] = service_type
        node.set['openstack']['db']['python_packages'][service_type] = ["my-#{service_type}-py"]

        expect(chef_run).to upgrade_package("my-#{service_type}-py")
      end
    end

    it 'starts glance registry on boot' do
      expect(chef_run).to enable_service('glance-registry')
    end

    describe 'version_control' do
      let(:cmd) { 'glance-manage version_control 0' }

      it 'versions the database' do
        stub_command('glance-manage db_version').and_return(false)

        expect(chef_run).to run_execute(cmd).with(user: 'glance', group: 'glance')
      end

      it 'does not version when glance-manage db_version false' do
        stub_command('glance-manage db_version').and_return(true)

        expect(chef_run).not_to run_execute(cmd)
      end
    end

    it 'deletes glance.sqlite' do
      expect(chef_run).to delete_file('/var/lib/glance/glance.sqlite')
    end

    it 'does not delete glance.sqlite when configured to use sqlite' do
      node.set['openstack']['db']['image']['service_type'] = 'sqlite'

      expect(chef_run).not_to delete_file('/var/lib/glance/glance.sqlite')
    end

    describe 'glance-registry.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-registry.conf') }

      it 'creates glance-registry.conf' do
        expect(chef_run).to create_template(file.name).with(
          user: 'glance',
          group: 'glance',
          mode: 00640
        )
      end

      context 'template contents' do
        include_context 'endpoint-stubs'
        include_context 'sql-stubs'

        it_behaves_like 'custom template banner displayer' do
          let(:file_name) { file.name }
        end

        %w(verbose debug data_api).each do |attr|
          it "sets the #{attr} attribute" do
            node.set['openstack']['image'][attr] = "#{attr}_value"
            expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{attr}_value$/)
          end
        end

        it 'sets port and host attributes' do
          [
            /^bind_port = 9191$/,
            /^bind_host = 127.0.0.1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('DEFAULT', line)
          end
        end
        it 'sets the workers attribute' do
          node.set['openstack']['image']['registry']['workers'] = 123
          expect(chef_run).to render_file(file.name).with_content(/^workers = 123$/)
        end

        it 'sets the connection attribute' do
          expect(chef_run).to render_file(file.name).with_content(/^connection = sql_connection_value$/)
        end

        it_behaves_like 'syslog use' do
          let(:log_file_name) { 'registry.log' }
        end

        it_behaves_like 'messaging' do
          let(:file_name) { file.name }
        end
        it_behaves_like 'keystone attribute setter', 'registry'

        context 'keystone authtoken attributes with default values' do
          it 'sets memcached server(s)' do
            expect(chef_run).not_to render_file(file.name).with_content(/^memcached_servers = $/)
          end

          it 'sets memcache security strategy' do
            expect(chef_run).not_to render_file(file.name).with_content(/^memcache_security_strategy = $/)
          end

          it 'sets memcache secret key' do
            expect(chef_run).not_to render_file(file.name).with_content(/^memcache_secret_key = $/)
          end

          it 'sets cafile' do
            expect(chef_run).not_to render_file(file.name).with_content(/^cafile = $/)
          end

          it 'sets insecure' do
            expect(chef_run).to render_file(file.name).with_content(/^insecure = false$/)
          end

          it 'sets registry auth version to the default v2.0' do
            expect(chef_run).to render_file(file.name).with_content(/^auth_version = v2.0$/)
          end

          it 'sets token hash algorithms' do
            expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = md5$/)
          end
        end

        context 'keystone authtoken attributes with new values' do
          it 'sets memcached server(s)' do
            node.set['openstack']['image']['registry']['auth']['memcached_servers'] = 'localhost:11211'
            expect(chef_run).to render_file(file.name).with_content(/^memcached_servers = localhost:11211$/)
          end

          it 'sets memcache security strategy' do
            node.set['openstack']['image']['registry']['auth']['memcache_security_strategy'] = 'MAC'
            expect(chef_run).to render_file(file.name).with_content(/^memcache_security_strategy = MAC$/)
          end

          it 'sets memcache secret key' do
            node.set['openstack']['image']['registry']['auth']['memcache_secret_key'] = '0123456789ABCDEF'
            expect(chef_run).to render_file(file.name).with_content(/^memcache_secret_key = 0123456789ABCDEF$/)
          end

          it 'sets cafile' do
            node.set['openstack']['image']['registry']['auth']['cafile'] = 'dir/to/path'
            expect(chef_run).to render_file(file.name).with_content(%r{^cafile = dir/to/path$})
          end

          it 'sets registry auth version' do
            node.set['openstack']['image']['registry']['auth']['version'] = 'v3.0'
            expect(chef_run).to render_file(file.name).with_content(/^auth_version = v3.0$/)
          end

          it 'sets insecure' do
            node.set['openstack']['image']['registry']['auth']['insecure'] = true
            expect(chef_run).to render_file(file.name).with_content(/^insecure = true$/)
          end

          it 'sets token hash algorithms' do
            node.set['openstack']['image']['registry']['auth']['hash_algorithms'] = 'sha2'
            expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = sha2$/)
          end
        end

        context 'glance-registry configuration with ssl disabled' do
          default_opts = {
            cert_file: '/etc/glance/ssl/certs/sslcert.pem',
            key_file: '/etc/glance/ssl/private/sslkey.pem'
          }
          it 'does not set cert or key file' do
            default_opts.each do |key, val|
              r = line_regexp("#{key} = #{val}")
              expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', r)
            end
          end
        end

        context 'glance-registry configuration with ssl enabled' do
          default_opts = {
            cert_file: '/etc/glance/ssl/certs/sslcert.pem',
            key_file: '/etc/glance/ssl/private/sslkey.pem'
          }
          cert = { 'ca_file' => '/etc/glance/ssl/certs/sslca.pem' }

          it 'configures SSL cert and key file when api is enabled for ssl' do
            node.set['openstack']['image']['ssl']['registry']['enabled'] = true
            default_opts.each do |key, val|
              r = line_regexp("#{key} = #{val}")
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', r)
            end
          end

          it 'configures SSL cert and key file when glance is enabled ssl' do
            node.set['openstack']['image']['ssl']['enabled'] = true
            default_opts.each do |key, val|
              r = line_regexp("#{key} = #{val}")
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', r)
            end
          end

          context 'with cert required' do
            it 'configures CA cert ' do
              node.set['openstack']['image']['ssl']['registry']['enabled'] = true
              node.set['openstack']['image']['ssl']['cert_required'] = true
              r = line_regexp("ca_file = #{cert['ca_file']}")
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', r)
            end
          end

          context 'with cert not required' do
            it 'configures CA cert ' do
              node.set['openstack']['image']['ssl']['registry']['enabled'] = true
              node.set['openstack']['image']['ssl']['cert_required'] = false
              r = line_regexp("ca_file = #{cert['ca_file']}")
              expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', r)
            end
          end
        end
      end

      it 'notifies glance-registry restart' do
        expect(file).to notify('service[glance-registry]').to(:restart)
      end
    end

    describe 'db_sync' do
      let(:cmd)  { 'glance-manage db_sync' }

      it 'runs migrations' do
        expect(chef_run).to run_execute(cmd).with(user: 'glance', group: 'glance')
      end

      it 'does not run migrations when openstack/image/db/migrate is false' do
        node.set['openstack']['db']['image']['migrate'] = false
        stub_command('glance-manage db_version').and_return(false)

        expect(chef_run).not_to run_execute(cmd)
      end
    end
  end
end
