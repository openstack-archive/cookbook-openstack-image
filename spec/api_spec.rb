require_relative 'spec_helper'

describe 'openstack-image::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'image-stubs'

    it do
      expect(chef_run).to include_recipe('openstack-common::client')
    end

    it do
      expect(chef_run).to upgrade_package('glance')
    end

    it do
      expect(chef_run).to create_directory('/etc/glance')
        .with(
          user: 'glance',
          group: 'glance',
          mode: '700'
        )
    end

    it do
      expect(chef_run).to create_directory('/var/lib/glance/images')
        .with(
          user: 'glance',
          group: 'glance',
          mode: '750',
          recursive: true
        )
    end

    describe 'glance-api.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-api.conf') }
      it do
        expect(chef_run).to create_template(file.name)
          .with(
            source: 'openstack-service.conf.erb',
            cookbook: 'openstack-common',
            user: 'glance',
            group: 'glance',
            mode: '640'
          )
      end

      [
        %r{^log_file = /var/log/glance/api.log$},
        %r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$},
        /^bind_host = 127.0.0.1$/,
        /^bind_port = 9292$/,
        /^enabled_backends = file:file,http:http$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('DEFAULT', line)
        end
      end

      [
        %r{^filesystem_store_datadir = /var/lib/glance/images$},
        /^default_backend = file$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('glance_store', line)
        end
      end

      [
        /^flavor = keystone$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('paste_deploy', line)
        end
      end

      [
        /^auth_type = password$/,
        /^region_name = RegionOne$/,
        /^username = glance$/,
        /^project_name = admin$/,
        %r{^auth_url = http://127.0.0.1:5000/v3$},
        /^password = glance-pass$/,
        /^user_domain_name = Default$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', line)
        end
      end

      [
        %r{^connection = mysql\+pymysql://glance:db-pass@127\.0\.0\.1:3306/glance\?charset=utf8$},
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('database', line)
        end
      end
    end

    describe 'glance-cache.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-cache.conf') }

      it 'creates glance-cache.conf' do
        expect(chef_run).to create_template(file.name)
          .with(
            source: 'openstack-service.conf.erb',
            cookbook: 'openstack-common',
            user: 'glance',
            group: 'glance',
            mode: '640'
          )
      end
    end

    describe 'glance-scrubber.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-scrubber.conf') }

      it 'creates glance-scrubber.conf' do
        expect(chef_run).to create_template(file.name)
          .with(
            source: 'openstack-service.conf.erb',
            cookbook: 'openstack-common',
            user: 'glance',
            group: 'glance',
            mode: '640'
          )
      end
    end

    it do
      expect(chef_run).to create_cron('glance-cache-pruner')
        .with(
          command: '/usr/bin/glance-cache-pruner > /dev/null 2>&1',
          minute: '*/30'
        )
    end

    it do
      expect(chef_run).to create_cron('glance-cache-cleaner')
        .with(
          command: '/usr/bin/glance-cache-cleaner > /dev/null 2>&1',
          minute: '01',
          hour: '00'
        )
    end

    it do
      expect(chef_run).to create_directory('/var/lib/glance/image-cache/')
        .with(
          user: 'glance',
          group: 'glance',
          mode: '755',
          recursive: true
        )
    end

    %w(image_api image_cache image_scrubber).each do |service|
      it do
        expect(chef_run).to run_ruby_block(
          "delete all attributes in node['openstack']['#{service}']['conf_secrets']"
        )
      end
    end

    describe 'db_sync' do
      let(:cmd) { 'glance-manage db_sync' }

      it 'runs migrations' do
        expect(chef_run).to run_execute(cmd).with(user: 'glance', group: 'glance')
      end

      context 'migration set to false' do
        cached(:chef_run) do
          runner.converge(described_recipe)
        end
        it 'does not run migrations when openstack/image/db/migrate is false' do
          node.override['openstack']['db']['image']['migrate'] = false
          expect(chef_run).not_to run_execute(cmd)
        end
      end
    end

    it do
      expect(chef_run).to enable_service('glance-api')
    end

    it do
      expect(chef_run).to start_service('glance-api')
    end

    it do
      resource = chef_run.service('glance-api')
      expect(resource).to subscribe_to('template[/etc/glance/glance-api.conf]').on(:restart).immediately
      expect(resource).to subscribe_to('template[/etc/glance/glance-cache.conf]').on(:restart).immediately
      expect(resource).to subscribe_to('template[/etc/glance/glance-scrubber.conf]').on(:restart).immediately
    end
  end
end
