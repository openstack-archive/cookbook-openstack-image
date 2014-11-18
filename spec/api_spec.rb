# encoding: UTF-8
require_relative 'spec_helper'

shared_context 'vmware settings configurator' do
  before do
    node.set['openstack']['image']['api']['vmware']['vmware_server_host'] = 'vmware_server_host_value'
    node.set['openstack']['image']['api']['vmware']['secret_name'] = 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_secret)
      .with('vmware_secret_name')
      .and_return('vmware_server_password_value')
  end

  %w(server_host server_username server_password datacenter_path datastore_name api_retry_count
     task_poll_interval store_image_dir api_insecure).each do |attr|
    it "sets the vmware #{attr} attribute" do
      node.set['openstack']['image']['api']['vmware']["vmware_#{attr}"] = "vmware_#{attr}_value"
      expect(chef_run).to render_file(file_name).with_content(/^vmware_#{attr} = vmware_#{attr}_value$/)
    end
  end
end

describe 'openstack-image::api' do
  describe 'ubuntu' do
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

    it 'does not upgrade swift package by default' do
      expect(chef_run).not_to upgrade_package('python-swift')
    end

    it 'starts glance api on boot' do
      expect(chef_run).to enable_service('glance-api')
    end

    describe 'using swift for default_store' do
      before do
        node.set['openstack']['image']['api']['default_store'] = 'swift'
      end

      it 'upgrades swift package if openstack/image/api/default_store is swift' do
        expect(chef_run).to upgrade_package('python-swift')
      end

      it 'honors platform package name and option overrides for swift packages' do
        node.set['openstack']['image']['platform']['package_overrides'] = '--override1 --override2'
        node.set['openstack']['image']['platform']['swift_packages'] = ['my-swift']

        expect(chef_run).to upgrade_package('my-swift').with(options: '--override1 --override2')
      end
    end

    describe 'using rbd for default_store' do
      before do
        node.set['openstack']['image']['api']['default_store'] = 'rbd'
      end

      it 'upgrades python-ceph package' do
        expect(chef_run).to upgrade_package('python-ceph')
      end

      it 'honors platform package name and option overrides for ceph packages' do
        node.set['openstack']['image']['platform']['package_overrides'] = '--override1 --override2'
        node.set['openstack']['image']['platform']['ceph_packages'] = ['my-ceph']

        expect(chef_run).to upgrade_package('my-ceph').with(options: '--override1 --override2')
      end

      it 'includes the ceph_client recipe from openstack-common' do
        expect(chef_run).to include_recipe('openstack-common::ceph_client')
      end

      describe 'cephx client keyring file' do
        let(:file) { chef_run.template('/etc/ceph/ceph.client.glance.keyring') }

        it 'creates /etc/ceph/ceph.client.glance.keyring' do
          expect(chef_run).to create_template(file.name).with(
            user: 'glance',
            group: 'glance',
            mode: 00600,
            cookbook: 'openstack-common'
          )
        end

        it 'has the proper content' do
          [/^\[client\.glance\]$/,
           /^  key = rbd-pass$/].each do |content|
            expect(chef_run).to render_file(file.name).with_content(content)
          end
        end
      end
    end

    it 'starts glance api on boot' do
      expect(chef_run).to enable_service('glance-api')
    end

    describe 'glance-api.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-api.conf') }

      it 'creates glance-api.conf' do
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

        context 'commonly named attributes' do
          %w(verbose debug filesystem_store_datadir).each do |attr|
            it "sets the #{attr} attribute" do
              node.set['openstack']['image'][attr] = "#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{attr}_value$/)
            end
          end
        end

        it 'uses default stores attribute' do
          expect(chef_run).to render_file(file.name).with_content(/^stores = file, http$/)
        end

        it 'sets the stores attribute' do
          node.set['openstack']['image']['api']['stores'] = ['swift']
          expect(chef_run).to render_file(file.name).with_content(/^stores = swift$/)
        end

        it 'uses default filesystem_store_metadata_file attribute' do
          expect(chef_run).not_to render_file(file.name).with_content(/^filesystem_store_metadata_file =/)
        end

        it 'sets the filesystem_store_metadata_file attribute' do
          node.set['openstack']['image']['filesystem_store_metadata_file'] = '/etc/glance/images.json'
          expect(chef_run).to render_file(file.name).with_content(%r(^filesystem_store_metadata_file = /etc/glance/images.json$))
        end

        context 'api related attributes' do
          %w(default_store workers show_image_direct_url).each do |attr|
            it "sets the #{attr} attribute" do
              node.set['openstack']['image']['api'][attr] = "#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{attr}_value$/)
            end
          end
        end

        it 'sets container and disk formats attributes' do
          %w(container_formats disk_formats).each do |attr|
            node.set['openstack']['image']['api'][attr] = ["#{attr}_value1", "#{attr}_value2"]
            expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{attr}_value1,#{attr}_value2$/)
          end
        end

        %w(bind registry).each do |type|
          %w(host port).each do |param|
            it "has a #{type}_#{param}" do
              expect(chef_run).to render_file(file.name).with_content(/^#{type}_#{param} = #{type}_#{param}_value$/)
            end
          end
        end

        it 'sets a connection attribute' do
          expect(chef_run).to render_file(file.name).with_content(/^connection = sql_connection_value$/)
        end

        it_behaves_like 'syslog use' do
          let(:log_file_name) { 'api.log' }
        end

        context 'syslog use' do
          it 'shows log_config if syslog use is enabled' do
            node.set['openstack']['image']['syslog']['use'] = true
            expect(chef_run).to render_file(file.name).with_content(%r(^log_config = /etc/openstack/logging.conf$))
          end

          it 'shows log_file if syslog use is disabled' do
            node.set['openstack']['image']['syslog']['use'] = false
            expect(chef_run).to render_file(file.name).with_content(%r(^log_file = /var/log/glance/api.log$))
          end
        end

        it_behaves_like 'messaging' do
          let(:file_name) { file.name }
        end

        context 'cinder storage options' do
          it 'sets default attributes' do
            expect(chef_run).to render_file(file.name).with_content(/^cinder_catalog_info = volumev2:cinderv2:publicURL$/)
            expect(chef_run).to render_file(file.name).with_content(%r{^cinder_endpoint_template = scheme://host:port/path$})
            expect(chef_run).to render_file(file.name).with_content(/^cinder_ca_certificates_file = $/)
            expect(chef_run).to render_file(file.name).with_content(/^cinder_api_insecure = false$/)
          end

          it 'uses insecure mode' do
            node.set['openstack']['image']['api']['block-storage']['cinder_api_insecure'] = true
            expect(chef_run).to render_file(file.name).with_content(/^cinder_api_insecure = true$/)
          end

          it 'uses cafile' do
            node.set['openstack']['image']['api']['block-storage']['cinder_ca_certificates_file'] = 'dir/to/path'
            expect(chef_run).to render_file(file.name).with_content(%r{^cinder_ca_certificates_file = dir/to/path$})
          end

          it 'sets cinder_catalog_info' do
            node.set['openstack']['image']['api']['block-storage']['cinder_catalog_info'] = 'volume:cinder:publicURL'
            expect(chef_run).to render_file(file.name).with_content(/^cinder_catalog_info = volume:cinder:publicURL$/)
          end
        end

        context 'swift options' do
          %w(container large_object_size large_object_chunk_size).each do |attr|
            it "sets swift store #{attr} attribute" do
              node.set['openstack']['image']['api']['swift'][attr] = "swift_store_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^swift_store_#{attr} = swift_store_#{attr}_value$/)
            end
          end

          context 'store auth enabled' do
            before do
              node.set['openstack']['image']['api']['swift_store_auth_address'] = 'swift_store_auth_address_value'
              node.set['openstack']['image']['api']['swift_store_user'] = 'swift_store_user_value'
              allow_any_instance_of(Chef::Recipe).to receive(:get_password)
                .with('service', 'swift_store_user_value')
                .and_return('swift_store_key_value')
            end

            %w(auth_address auth_version key).each do |attr|
              it "sets the swift #{attr} setting to attributes" do
                node.set['openstack']['image']['api']["swift_store_#{attr}"] = "swift_store_#{attr}_value"
                expect(chef_run).to render_file(file.name).with_content(/^swift_store_#{attr} = swift_store_#{attr}_value$/)
              end
            end

            it 'sets the store_user attribute' do
              node.set['openstack']['image']['api']['swift_user_tenant'] = 'swift_user_tenant_value'
              node.set['openstack']['image']['api']['swift_store_user'] = 'swift_store_user_value'
              expect(chef_run).to render_file(file.name).with_content(/^swift_store_user = swift_user_tenant_value:swift_store_user_value$/)
            end

          end

          context 'store auth disabled' do
            before do
              node.set['openstack']['image']['api']['swift_store_auth_address'] = nil
            end

            it 'sets the auth address' do
              expect(chef_run).to render_file(file.name).with_content(/^swift_store_auth_address = auth_uri_value$/)
            end

            it 'sets the auth version' do
              expect(chef_run).to render_file(file.name).with_content(/^swift_store_auth_version = 2$/)
            end

            it 'sets the store user' do
              node.set['openstack']['image']['service_tenant_name'] = 'service-tenant-name-value'
              node.set['openstack']['image']['service_user'] = 'service-user-value'
              expect(chef_run).to render_file(file.name).with_content(/^swift_store_user = :service-tenant-name-value_service-user-value$/)
            end

            it 'sets the store key' do
              expect(chef_run).to render_file(file.name).with_content(/^swift_store_key = admin_password_value$/)
            end
          end

          it 'sets swift enable_snet attribute' do
            node.set['openstack']['image']['api']['swift']['enable_snet'] = 'swift_enable_snet_value'
            expect(chef_run).to render_file(file.name).with_content(/^swift_enable_snet = swift_enable_snet_value$/)
          end

          it 'shows store region attribute if it is enabled' do
            node.set['openstack']['image']['api']['swift']['store_region'] = 'swift_store_region_value'
            expect(chef_run).to render_file(file.name).with_content(/^swift_store_region = swift_store_region_value$/)
          end

          it 'does not show store region attribute if it is disabled' do
            node.set['openstack']['image']['api']['swift']['store_region'] = nil
            expect(chef_run).not_to render_file(file.name).with_content(/^swift_store_region =/)
          end
        end

        %w(store_ceph_conf store_user store_pool store_chunk_size).each do |attr|
          it "sets the rbd #{attr} attribute" do
            node.set['openstack']['image']['api']['rbd']["rbd_#{attr}"] = "rbd_#{attr}_value"
            expect(chef_run).to render_file(file.name).with_content(/^rbd_#{attr} = rbd_#{attr}_value$/)
          end
        end

        it_behaves_like 'vmware settings configurator' do
          let(:file_name) { file.name }
        end

        it_behaves_like 'keystone attribute setter', 'api'

        context 'flavor attribute' do
          it 'sets the flavor to keystone with caching disabled' do
            node.set['openstack']['image']['api']['cache_management'] = nil
            node.set['openstack']['image']['api']['caching'] = nil
            expect(chef_run).to render_file(file.name).with_content(/^flavor = keystone$/)
          end

          it 'sets the flavor to keystone and cachemanagement with cache_management enabled and caching disabled' do
            node.set['openstack']['image']['api']['cache_management'] = true
            node.set['openstack']['image']['api']['caching'] = nil
            expect(chef_run).to render_file(file.name).with_content(/^flavor = keystone\+cachemanagement$/)
          end

          it 'sets the flavor to keystone and caching with cache_management disabled and caching enabled' do
            node.set['openstack']['image']['api']['cache_management'] = nil
            node.set['openstack']['image']['api']['caching'] = true
            expect(chef_run).to render_file(file.name).with_content(/^flavor = keystone\+caching$/)
          end

          it 'sets the flavor to keystone and cachemanagement with cache_management and caching enabled' do
            node.set['openstack']['image']['api']['cache_management'] = true
            node.set['openstack']['image']['api']['caching'] = true
            expect(chef_run).to render_file(file.name).with_content(/^flavor = keystone\+cachemanagement$/)
          end
        end

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

          it 'sets auth version to the default v2.0' do
            expect(chef_run).to render_file(file.name).with_content(/^auth_version = v2.0$/)
          end

          it 'sets insecure' do
            expect(chef_run).to render_file(file.name).with_content(/^insecure = false$/)
          end

          it 'sets token hash algorithms' do
            expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = md5$/)
          end
        end

        context 'keystone authtoken attributes with new values' do
          it 'sets memcached server(s)' do
            node.set['openstack']['image']['api']['auth']['memcached_servers'] = 'localhost:11211'
            expect(chef_run).to render_file(file.name).with_content(/^memcached_servers = localhost:11211$/)
          end

          it 'sets memcache security strategy' do
            node.set['openstack']['image']['api']['auth']['memcache_security_strategy'] = 'MAC'
            expect(chef_run).to render_file(file.name).with_content(/^memcache_security_strategy = MAC$/)
          end

          it 'sets memcache secret key' do
            node.set['openstack']['image']['api']['auth']['memcache_secret_key'] = '0123456789ABCDEF'
            expect(chef_run).to render_file(file.name).with_content(/^memcache_secret_key = 0123456789ABCDEF$/)
          end

          it 'sets cafile' do
            node.set['openstack']['image']['api']['auth']['cafile'] = 'dir/to/path'
            expect(chef_run).to render_file(file.name).with_content(%r{^cafile = dir/to/path$})
          end

          it 'sets auth version' do
            node.set['openstack']['image']['api']['auth']['version'] = 'v3.0'
            expect(chef_run).to render_file(file.name).with_content(/^auth_version = v3.0$/)
          end

          it 'sets insecure' do
            node.set['openstack']['image']['api']['auth']['insecure'] = true
            expect(chef_run).to render_file(file.name).with_content(/^insecure = true$/)
          end

          it 'sets token hash algorithms' do
            node.set['openstack']['image']['api']['auth']['hash_algorithms'] = 'sha2'
            expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = sha2$/)
          end
        end
      end

      it 'notifies glance-api restart' do
        expect(file).to notify('service[glance-api]').to(:restart)
      end
    end

    describe 'glance-api-paste.ini' do
      let(:file) { chef_run.template('/etc/glance/glance-api-paste.ini') }

      it 'creates glance-api-paste.ini' do
        expect(chef_run).to create_template(file.name).with(
          user: 'glance',
          group: 'glance',
          mode: 00644
        )
      end

      context 'template contents' do
        it_behaves_like 'custom template banner displayer' do
          let(:file_name) { file.name }
        end
      end

      it 'notifies glance-api restart' do
        expect(file).to notify('service[glance-api]').to(:restart)
      end
    end

    describe 'glance-cache.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-cache.conf') }

      it 'creates glance-cache.conf' do
        expect(chef_run).to create_template(file.name).with(
          user: 'glance',
          group: 'glance',
          mode: 00640
        )
      end

      context 'template contents' do
        include_context 'endpoint-stubs'

        it_behaves_like 'custom template banner displayer' do
          let(:file_name) { file.name }
        end

        %w(verbose debug).each do |attr|
          it "sets the #{attr} attribute" do
            node.set['openstack']['image'][attr] = "#{attr}_value"
            expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{attr}_value$/)
          end
        end

        context 'cache attributes' do
          %w(dir stall_time).each do |attr|
            it "sets the #{attr} cache attribute" do
              node.set['openstack']['image']['cache'][attr] = "image_cache_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^image_cache_#{attr} = image_cache_#{attr}_value$/)
            end
          end

          it 'sets the image_cache_invalid_entry_grace_period attribute' do
            node.set['openstack']['image']['cache']['grace_period'] = 'grace_period_value'
            expect(chef_run).to render_file(file.name).with_content(/^image_cache_invalid_entry_grace_period = grace_period_value$/)
          end

          it 'sets the image_cache_max_size attribute' do
            node.set['openstack']['image']['api']['cache']['image_cache_max_size'] = 'max_size_value'
            expect(chef_run).to render_file(file.name).with_content(/^image_cache_max_size = max_size_value$/)
          end
        end

        context 'syslog options' do
          it 'sets the log_config attribute if syslog use is enabled' do
            node.set['openstack']['image']['syslog']['use'] = true
            expect(chef_run).to render_file(file.name).with_content(%r(^log_config = /etc/openstack/logging.conf$))
          end

          it 'sets the log_file attribute if syslog use is disabled' do
            node.set['openstack']['image']['syslog']['use'] = false
            expect(chef_run).to render_file(file.name).with_content(%r(^log_file = /var/log/glance/image-cache.log$))
          end
        end

        %w(host port).each do |attr|
          it "sets the registry #{attr} attribute" do
            expect(chef_run).to render_file(file.name).with_content(/^registry_#{attr} = registry_#{attr}_value$/)
          end
        end

        it_behaves_like 'vmware settings configurator' do
          let(:file_name) { file.name }
        end
      end

      it 'notifies glance-api restart' do
        expect(file).to notify('service[glance-api]').to(:restart)
      end
    end

    describe 'glance-cache-paste.ini' do
      let(:file) { chef_run.template('/etc/glance/glance-cache-paste.ini') }

      it 'creates glance-cache-paste.ini' do
        expect(chef_run).to create_template(file.name).with(
          user: 'glance',
          group: 'glance',
          mode: 00644
        )
      end

      it_behaves_like 'custom template banner displayer' do
        let(:file_name) { file.name }
      end

      it 'notifies glance-api restart' do
        expect(file).to notify('service[glance-api]').to(:restart)
      end
    end

    describe 'glance-scrubber.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-scrubber.conf') }

      it 'creates glance-scrubber.conf' do
        expect(chef_run).to create_template(file.name).with(
          user: 'glance',
          group: 'glance',
          mode: 00640
        )
      end

      context 'template contents' do
        include_context 'endpoint-stubs'

        %w(host port).each do |attr|
          it "sets the registry #{attr} attribute" do
            expect(chef_run).to render_file(file.name).with_content(/^registry_#{attr} = registry_#{attr}_value$/)
          end
        end
      end
    end

    it 'has glance-cache-pruner cronjob running every 30 minutes' do
      cron = chef_run.cron('glance-cache-pruner')

      expect(cron.command).to eq '/usr/bin/glance-cache-pruner > /dev/null 2>&1'
      expect(cron.minute).to eq '*/30'
    end

    it 'has glance-cache-cleaner to run at 00:01 each day' do
      cron = chef_run.cron('glance-cache-cleaner')

      expect(cron.command).to eq '/usr/bin/glance-cache-cleaner > /dev/null 2>&1'
      expect(cron.minute).to eq '01'
      expect(cron.hour).to eq '00'
    end

    describe 'glance-scrubber-paste.ini' do
      let(:file) { chef_run.template('/etc/glance/glance-scrubber-paste.ini') }

      it 'creates glance-scrubber-paste.ini' do
        expect(chef_run).to create_template(file.name).with(
          user: 'glance',
          group: 'glance',
          mode: 00644
        )
      end

      it_behaves_like 'custom template banner displayer' do
        let(:file_name) { file.name }
      end
    end
  end
end
