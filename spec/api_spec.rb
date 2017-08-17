# encoding: UTF-8
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
          mode: 0o0700
        )
    end

    it do
      expect(chef_run).to create_directory('/var/lib/glance/images')
        .with(
          user: 'glance',
          group: 'glance',
          mode: 0o0750,
          recursive: true
        )
    end

    it do
      expect(chef_run).to create_directory('/var/cache/glance/api')
        .with(
          user: 'glance',
          group: 'glance',
          mode: 0o0700,
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
            mode: 0o0640
          )
      end

      it do
        [
          %r{^log_file = /var/log/glance/api.log$},
          %r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$},
          /^bind_host = 127.0.0.1$/,
          /^bind_port = 9292$/,
          /^registry_host = 127.0.0.1$/,
          /^registry_port = 9191$/,
          /^registry_client_protocol = http$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('DEFAULT', line)
        end
      end

      it do
        [
          %r{^filesystem_store_datadir = /var/lib/glance/images$},
          /^default_store = file$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('glance_store', line)
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
          /^auth_type = v3password$/,
          /^region_name = RegionOne$/,
          /^username = glance$/,
          /^project_name = admin$/,
          %r{^signing_dir = /var/cache/glance/api$},
          %r{^auth_url = http://127.0.0.1:5000/v3$},
          /^password = glance-pass$/,
          /^user_domain_name = Default$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', line)
        end
      end

      it do
        [
          %r{^connection = mysql\+pymysql://glance:db-pass@127\.0\.0\.1:3306/glance\?charset=utf8$}
        ].each do |line|
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
            mode: 0o0640
          )
      end

      context 'template contents' do
        it do
          [
            /^registry_port = 9191$/,
            /^registry_host = 127.0.0.1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('DEFAULT', line)
          end
        end
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
            mode: 0o0640
          )
      end

      context 'template contents' do
        it do
          [
            /^registry_port = 9191$/,
            /^registry_host = 127.0.0.1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('DEFAULT', line)
          end
        end
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
          mode: 0o0755,
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
