require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :warn
end

REDHAT_7 = {
  platform: 'redhat',
  version: '7',
}.freeze

REDHAT_8 = {
  platform: 'redhat',
  version: '8',
}.freeze

ALL_RHEL = [
  REDHAT_7,
  REDHAT_8,
].freeze

UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '18.04',
}.freeze

# Helper methods
module Helpers
  # Create an anchored regex to exactly match the entire line
  # (name borrowed from grep --line-regexp)
  #
  # @param [String] str The whole line to match
  # @return [Regexp] The anchored/escaped regular expression
  def line_regexp(str)
    /^#{Regexp.quote(str)}$/
  end
end

shared_context 'image-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:address_for)
      .with('lo')
      .and_return('127.0.1.1')
    allow_any_instance_of(Chef::Recipe).to receive(:config_by_role)
      .with('rabbitmq-server', 'queue')
      .and_return(
        'host' => 'rabbit-host', 'port' => 'rabbit-port'
      )
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return '1.1.1.1:5672,2.2.2.2:5672'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'glance')
      .and_return('db-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-image')
      .and_return('glance-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('image')
      .and_return('rabbit://guest:mypass@127.0.0.1:5672')
    allow(Chef::Application).to receive(:fatal!)
    stub_command('glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list --id e1847f1a-01d2-4957-a067-b56085bf3781 | grep cirros').and_return('')
  end
end

shared_examples 'common-logging-recipe' do
  it 'does not include logging recipe by default' do
    expect(chef_run).not_to include_recipe('openstack-common::logging')
  end

  it 'includes logging recipe if openstack/image/syslog/use attribute is true' do
    node.override['openstack']['image']['syslog']['use'] = true

    expect(chef_run).to include_recipe('openstack-common::logging')
  end
end

shared_examples 'common-packages' do
  it 'upgrades curl package' do
    expect(chef_run).to upgrade_package 'curl'
  end

  it 'upgrades glance package' do
    expect(chef_run).to upgrade_package 'glance'
  end

  it 'honors the platform name and option package overrides' do
    node.override['openstack']['image']['platform']['package_overrides'] = '-o Dpkg::Options:: = \'--force-confold\' -o Dpkg::Options:: = \'--force-confdef\' --force-yes'
    node.override['openstack']['image']['platform']['image_packages'] = ['my-glance']

    expect(chef_run).to upgrade_package('my-glance').with(options: '-o Dpkg::Options:: = \'--force-confold\' -o Dpkg::Options:: = \'--force-confdef\' --force-yes')
  end
end

shared_examples 'image-lib-cache-directory' do
  describe '/var/lib/glance/image-cache/' do
    let(:dir) { chef_run.directory('/var/lib/glance/image-cache/') }

    it 'creates directory /var/lib/glance/image-cache' do
      expect(chef_run).to create_directory(dir.name).with(
        user: 'glance',
        group: 'glance',
        mode: 0o0755,
        recursive: true
      )
    end
  end
end

shared_examples 'glance-directory' do
  describe '/etc/glance' do
    let(:dir) { chef_run.directory('/etc/glance') }

    it 'creates directory /etc/glance' do
      expect(chef_run).to create_directory(dir.name).with(
        user: 'glance',
        group: 'glance',
        mode: 0o0700
      )
    end
  end
end

shared_examples 'custom template banner displayer' do
  it 'shows the custom banner' do
    node.override['openstack']['image']['custom_template_banner'] = 'custom_template_banner_value'
    expect(chef_run).to render_file(file_name).with_content(/^custom_template_banner_value$/)
  end
end

shared_context 'endpoint-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-image')
      .and_return('admin_password_value')
  end
end

shared_context 'sql-stubs' do
  before do
    node.override['openstack']['db']['image']['username'] = 'db_username_value'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'glance')
      .and_return('db_password_value')
    allow_any_instance_of(Chef::Recipe).to receive(:db_uri)
      .with('image', 'db_username_value', 'db_password_value')
      .and_return('sql_connection_value')
  end
end

shared_examples 'syslog use' do
  it 'shows log_config if syslog use is enabled' do
    node.override['openstack']['image']['syslog']['use'] = true
    expect(chef_run).to render_file(file.name).with_content(%r{^log_config = /etc/openstack/logging.conf$})
  end

  it 'shows log_file if syslog use is disabled' do
    node.override['openstack']['image']['syslog']['use'] = false
    expect(chef_run).to render_file(file.name).with_content(%r{^log_file = /var/log/glance/#{log_file_name}$})
  end
end

shared_examples 'keystone attribute setter' do |version|
  it 'sets the identity_uri value' do
    expect(chef_run).to render_file(file.name).with_content(%r{^identity_uri = http://127.0.0.1:5000/$})
  end

  context 'auth version' do
    it 'shows the version attribute if it is different from v3' do
      node.override['openstack']['api']['auth']['version'] = 'v3.0'
      expect(chef_run).to render_file(file.name).with_content(/^auth_version = v3.0$/)
    end
  end

  %w(project user).each do |attr|
    it "sets the auth admin #{attr} attribute" do
      node.override['openstack']["image-#{version}"]['conf']['keystone_authtoken']["admin_#{attr}"] = "service_#{attr}_value"
      expect(chef_run).to render_file(file.name).with_content(/^admin_#{attr} = service_#{attr}_value$/)
    end
  end

  it 'sets the admin password attribute' do
    expect(chef_run).to render_file(file.name).with_content(/^admin_password = admin_password_value$/)
  end
end

shared_examples 'messaging' do |version|
  context 'messaging' do
    before do
      node.override['openstack']['image']['notification_driver'] = 'messaging'
    end

    it 'sets the notifier_strategy attribute' do
      node.override['openstack']["image-#{version}"]['conf']['DEFAULT']['notifier_strategy'] = 'default'
      expect(chef_run).to render_file(file.name).with_content(/^notifier_strategy = default$/)
    end

    context 'commonly named attributes' do
      %w(notification_driver rpc_backend rpc_thread_pool_size
         rpc_conn_pool_size rpc_response_timeout control_exchange).each do |attr|
        it "sets the #{attr} attribute" do
          node.override['openstack']["image-#{version}"]['conf']['DEFAULT'][attr] = "#{attr}_value"
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^#{attr} = #{attr}_value$/)
        end
      end
    end

    context 'rabbitmq' do
      before do
        node.override['openstack']["image-#{version}"]['conf']['DEFAULT']['rpc_backend'] = 'rabbit'
        node.override['openstack']["image-#{version}"]['conf']['oslo_messaging_rabbit']['rabbit_userid'] = 'rabbit_userid_value'
        allow_any_instance_of(Chef::Recipe).to receive(:get_password)
          .with('user', 'rabbit_userid_value')
          .and_return('rabbit_password_value')
      end

      %w(host port userid).each do |attr|
        it "sets the rabbitmq #{attr} attribute" do
          node.override['openstack']["image-#{version}"]['conf']['oslo_messaging_rabbit']["rabbit_#{attr}"] = "rabbit_#{attr}_value"
          expect(chef_run).to render_config_file(file_name).with_section_content('oslo_messaging_rabbit', /^rabbit_#{attr} = rabbit_#{attr}_value$/)
        end
      end

      it 'sets the rabbitmq password' do
        expect(chef_run).to render_config_file(file_name).with_section_content('oslo_messaging_rabbit', /^rabbit_password = mq-pass$/)
      end

      it 'sets the rabbitmq vhost' do
        node.override['openstack']["image-#{version}"]['conf']['oslo_messaging_rabbit']['rabbit_virtual_host'] = 'rabbit_vhost_value'
        expect(chef_run).to render_config_file(file_name).with_section_content('oslo_messaging_rabbit', /^rabbit_virtual_host = rabbit_vhost_value$/)
      end
    end
  end
end
