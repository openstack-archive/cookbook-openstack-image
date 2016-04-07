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

    include_context 'image-stubs'

    it 'converges when configured to use sqlite' do
      node.set['openstack']['db']['image']['service_type'] = 'sqlite'
      expect { chef_run }.to_not raise_error
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('python-mysqldb')
    end

    %w(db2 postgresql).each do |service_type|
      it "upgrades #{service_type} python packages if chosen" do
        node.set['openstack']['db']['image']['service_type'] = service_type
        node.set['openstack']['db']['python_packages'][service_type] = ["my-#{service_type}-py"]
        expect(chef_run).to upgrade_package("my-#{service_type}-py")
      end
    end

    it do
      expect(chef_run).to create_directory('/var/cache/glance/registry').with(
        user: 'glance',
        group: 'glance',
        mode: 00700
      )
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
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          user: 'glance',
          group: 'glance',
          mode: 00640
        )
      end

      context 'template contents' do
        it do
          [
            /^rpc_backend = rabbit$/,
            %r{^log_file = /var/log/glance/registry.log$},
            /^bind_port = 9191$/,
            /^bind_host = 127.0.0.1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('DEFAULT', line)
          end
        end

        it do
          [
            /^flavor = keystone$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('paste_deploy', line)
          end
        end

        it do
          [
            /^auth_plugin = v2password$/,
            /^region_name = RegionOne$/,
            /^username = glance$/,
            /^tenant_name = service$/,
            %r{^signing_dir = /var/cache/glance/registry},
            %r{^auth_url = http://127.0.0.1:5000/v2.0},
            /^password = glance-pass$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('keystone_authtoken', line)
          end
        end

        it do
          [
            %r{^connection = mysql://glance:db-pass@127\.0\.0\.1:3306/glance\?charset=utf8$}
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('database', line)
          end
        end

        it do
          [
            /^rabbit_userid = guest$/,
            /^rabbit_password = mq-pass$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('oslo_messaging_rabbit', line)
          end
        end
      end
    end

    it do
      expect(chef_run).to run_ruby_block(
        "delete all attributes in node['openstack']['image_registry']['conf_secrets']"
      )
    end

    describe 'db_sync' do
      let(:cmd) { 'glance-manage db_sync' }

      it 'runs migrations' do
        expect(chef_run).to run_execute(cmd).with(user: 'glance', group: 'glance')
      end

      it 'does not run migrations when openstack/image/db/migrate is false' do
        node.set['openstack']['db']['image']['migrate'] = false
        expect(chef_run).not_to run_execute(cmd)
      end
    end

    it do
      expect(chef_run).to enable_service('glance-registry')
    end

    it do
      expect(chef_run).to start_service('glance-registry')
    end

    it do
      resource = chef_run.service('glance-registry')
      expect(resource).to subscribe_to('template[/etc/glance/glance-registry.conf]').on(:restart).immediately
    end
  end
end
