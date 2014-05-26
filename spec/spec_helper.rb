# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-image' }

require 'chef/application'

LOG_LEVEL = :fatal
REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.3',
  log_level: LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: LOG_LEVEL
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

shared_examples 'vmware config' do |file_name|
  describe 'vmware settings' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }
    let(:file) { chef_run.template(file_name) }

    it 'has default vmware_* settings' do
      [
        /^vmware_server_host = $/,
        /^vmware_server_username = $/,
        /^vmware_server_password = $/,
        /^vmware_datacenter_path = $/,
        /^vmware_datastore_name = $/,
        /^vmware_api_retry_count = 10/,
        /^vmware_task_poll_interval = 5$/,
        /^vmware_store_image_dir = \/openstack_glance$/,
        /^vmware_api_insecure = false$/
      ].each do |line|
        expect(chef_run).to render_file(file.name).with_content(line)
      end
    end

    it 'looks up the vmware_server_password when vmware_server_host is set' do
      node.set['openstack']['image']['api']['vmware']['vmware_server_host'] = 'my-vmware'
      expect(chef_run).to render_file(file.name).with_content(/^vmware_server_password = vmware_secret_name$/)
    end

    it 'does set vmware settings when overridden' do
      %w(
        vmware_server_host
        vmware_server_username
        vmware_datacenter_path
        vmware_datastore_name
        vmware_api_retry_count
        vmware_task_poll_interval
        vmware_store_image_dir
        vmware_api_insecure
      ).each { |key| node.set['openstack']['image']['api']['vmware'][key] = "my_#{key}" }
       .each do |key|
        expect(chef_run).to render_file(file.name).with_content(/^#{key} = my_#{key}$/)
      end
    end
  end
end
