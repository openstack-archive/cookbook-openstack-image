# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::registry' do
  describe 'ubuntu' do
    before do
      # Lame we must still stub this, since the recipe contains shell
      # guards.  Need to work on a way to resolve this.
      stub_command('glance-manage db_version').and_return(true)
    end

    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

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
      node.set['openstack']['image']['platform']['mysql_python_packages'] = ['my-mysql-py']

      expect(chef_run).to upgrade_package('my-mysql-py').with(options: '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes')
    end

    %w{db2 postgresql}.each do |service_type|
      it "upgrades #{service_type} python packages if chosen" do
        node.set['openstack']['db']['image']['service_type'] = service_type
        node.set['openstack']['image']['platform']["#{service_type}_python_packages"] = ["my-#{service_type}-py"]

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
          user: 'root',
          group: 'root',
          mode: 00644
        )
      end

      context 'template contents' do
        include_context 'endpoint-stubs'
        include_context 'sql-stubs'

        before do
          Chef::Recipe.any_instance.stub(:endpoint)
            .with('image-registry-bind')
            .and_return(double(host: 'registry_host_value', port: 'registry_port_value'))
        end

        it_behaves_like 'custom template banner displayer' do
          let(:file_name) { file.name }
        end

        %w(verbose debug data_api).each do |attr|
          it "sets the #{attr} attrinbute" do
            node.set['openstack']['image'][attr] = "#{attr}_value"
            expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{attr}_value$/)
          end
        end

        %w(host port).each do |attr|
          it "sets the registry #{attr} attribute" do
            expect(chef_run).to render_file(file.name).with_content(/^bind_#{attr} = registry_#{attr}_value$/)
          end
        end

        it 'sets the sql connection attribute' do
          expect(chef_run).to render_file(file.name).with_content(/^sql_connection = sql_connection_value$/)
        end

        it_behaves_like 'syslog use' do
          let(:log_file_name) { 'registry.log' }
        end

        it_behaves_like 'keystone attribute setter', 'registry'
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

    describe 'glance-registry-paste.ini' do
      let(:file) { chef_run.template('/etc/glance/glance-registry-paste.ini') }

      it 'creates glance-registry-paste.ini' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 00644
        )
      end

      it_behaves_like 'custom template banner displayer' do
        let(:file_name) { file.name }
      end

      it 'notifies glance-registry restart' do
        expect(file).to notify('service[glance-registry]').to(:restart)
      end
    end
  end
end
