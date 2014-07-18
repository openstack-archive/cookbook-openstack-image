# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-image' }

require 'chef/application'

LOG_LEVEL = :fatal
REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.5',
  log_level: LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: LOG_LEVEL
}
SUSE_OPTS = {
  platform: 'suse',
  version: '11.3',
  log_lovel: LOG_LEVEL
}

shared_context 'image-stubs' do
  before do
    Chef::Recipe.any_instance.stub(:address_for)
      .with('lo')
      .and_return('127.0.1.1')

    Chef::Recipe.any_instance.stub(:config_by_role)
      .with('rabbitmq-server', 'queue')
      .and_return(
        'host' => 'rabbit-host', 'port' => 'rabbit-port'
      )

    Chef::Recipe.any_instance.stub(:get_secret)
      .with('openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    Chef::Recipe.any_instance.stub(:get_secret)
      .with('openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'

    Chef::Recipe.any_instance.stub(:get_password)
    .with('db', anything)
    .and_return('')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'openstack-image')
      .and_return('glance-pass')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'rbd-image')
      .and_return('rbd-pass')

    Chef::Application.stub(:fatal!)
    stub_command('glance --insecure --os-username glance --os-password glance-pass --os-tenant-name service --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v2.0 image-list | grep cirros').and_return('')
  end
end

shared_examples 'common-logging-recipe' do
  it 'does not include logging recipe by default' do
    expect(chef_run).not_to include_recipe('openstack-common::logging')
  end

  it 'includes logging recipe if openstack/image/syslog/use attribute is true' do
    node.set['openstack']['image']['syslog']['use'] = true

    expect(chef_run).to include_recipe('openstack-common::logging')
  end
end

shared_examples 'common-packages' do
  it 'upgrades python-keystoneclient package' do
    expect(chef_run).to upgrade_package 'python-keystoneclient'
  end

  it 'upgrades curl package' do
    expect(chef_run).to upgrade_package 'curl'
  end

  it 'upgrades glance package' do
    expect(chef_run).to upgrade_package 'glance'
  end

  it 'honors the platform name and option package overrides' do
    node.set['openstack']['image']['platform']['package_overrides'] = '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes'
    node.set['openstack']['image']['platform']['image_packages'] = ['my-glance']

    expect(chef_run).to upgrade_package('my-glance').with(options: '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes')
  end
end

shared_examples 'cache-directory' do
  describe '/var/cache/glance' do
    let(:dir) { chef_run.directory('/var/cache/glance') }

    it 'has proper owner' do
      expect(dir.owner).to eq('glance')
      expect(dir.group).to eq('glance')
    end

    it 'has proper modes' do
      expect(sprintf('%o', dir.mode)).to eq '700'
    end
  end
end

shared_examples 'glance-directory' do
  describe '/etc/glance' do
    let(:dir) { chef_run.directory('/etc/glance') }

    it 'has proper owner' do
      expect(dir.owner).to eq('glance')
      expect(dir.group).to eq('glance')
    end

    it 'has proper modes' do
      expect(sprintf('%o', dir.mode)).to eq '700'
    end
  end
end

shared_examples 'custom template banner displayer' do
  it 'shows the custom banner' do
    node.set['openstack']['image']['custom_template_banner'] = 'custom_template_banner_value'
    expect(chef_run).to render_file(file_name).with_content(/^custom_template_banner_value$/)
  end
end

shared_context 'endpoint-stubs' do
  before do
    Chef::Recipe.any_instance.stub(:endpoint)
      .with('image-registry')
      .and_return(double(host: 'registry_host_value', port: 'registry_port_value'))
    Chef::Recipe.any_instance.stub(:endpoint)
      .with('identity-api')
      .and_return('identity_endpoint_value')
    identity_admin_endpoint = double(host: 'identity_admin_endpoint_host_value',
                                     port: 'identity_admin_endpoint_port_value',
                                     scheme: 'identity_admin_endpoint_protocol_value')
    Chef::Recipe.any_instance.stub(:endpoint)
      .with('identity-admin')
      .and_return(identity_admin_endpoint)
    Chef::Recipe.any_instance.stub(:endpoint)
      .with('image-api-bind')
      .and_return(double(host: 'bind_host_value', port: 'bind_port_value'))
    Chef::Recipe.any_instance.stub(:auth_uri_transform)
      .with('identity_endpoint_value', 'v3.0')
      .and_return('auth_uri_value')
    Chef::Recipe.any_instance.stub(:auth_uri_transform)
      .with('identity_endpoint_value', 'v2.0')
      .and_return('auth_uri_value')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'openstack-image')
      .and_return('admin_password_value')
  end
end

shared_context 'sql-stubs' do
  before do
    node.set['openstack']['db']['image']['username'] = 'db_username_value'
    Chef::Recipe.any_instance.stub(:get_password)
      .with('db', 'glance')
      .and_return('db_password_value')
    Chef::Recipe.any_instance.stub(:db_uri)
      .with('image', 'db_username_value', 'db_password_value')
      .and_return('sql_connection_value')
  end
end

shared_examples 'syslog use' do
  it 'shows log_config if syslog use is enabled' do
    node.set['openstack']['image']['syslog']['use'] = true
    expect(chef_run).to render_file(file.name).with_content(%r(^log_config = /etc/openstack/logging.conf$))
  end

  it 'shows log_file if syslog use is disabled' do
    node.set['openstack']['image']['syslog']['use'] = false
    expect(chef_run).to render_file(file.name).with_content(%r(^log_file = /var/log/glance/#{log_file_name}$))
  end
end

shared_examples 'keystone attribute setter' do |version|
  it 'sets the auth_uri value' do
    expect(chef_run).to render_file(file.name).with_content(/^auth_uri = auth_uri_value$/)
  end

  %w(host port protocol).each do |attr|
    it "sets the auth #{attr} attribute" do
      expect(chef_run).to render_file(file.name).with_content(/^auth_#{attr} = identity_admin_endpoint_#{attr}_value$/)
    end
  end

  context 'auth version' do
    it 'shows the version attribute if it is different from v2.0' do
      node.set['openstack']['image'][version]['auth']['version'] = 'v3.0'
      expect(chef_run).to render_file(file.name).with_content(/^auth_version = v3.0$/)
    end

    it 'does not show the version attribute if it is v2.0' do
      node.set['openstack']['image'][version]['auth']['version'] = 'v2.0'
      expect(chef_run).not_to render_file(file.name).with_content(/^auth_version = v2.0$/)
    end
  end

  %w(tenant_name user).each do |attr|
    it "sets the auth admin #{attr} attribute" do
      node.set['openstack']['image']["service_#{attr}"] = "service_#{attr}_value"
      expect(chef_run).to render_file(file.name).with_content(/^admin_#{attr} = service_#{attr}_value$/)
    end
  end

  it 'sets the admin password attribute' do
    expect(chef_run).to render_file(file.name).with_content(/^admin_password = admin_password_value$/)
  end

  it 'sets the signing dir attribute' do
    node.set['openstack']['image'][version]['auth']['cache_dir'] = 'cache_dir_value'
    expect(chef_run).to render_file(file.name).with_content(/^signing_dir = cache_dir_value$/)
  end
end
