# encoding: UTF-8
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

::LOG_LEVEL = :fatal
::REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.3',
  log_level: ::LOG_LEVEL
}
::UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: ::LOG_LEVEL
}

# TODO(chrislaco): Factor this into proper RSpec shared_contexts
def image_stubs # rubocop:disable MethodLength
  ::Chef::Recipe.any_instance.stub(:address_for)
    .with('lo')
    .and_return('127.0.1.1')
  ::Chef::Recipe.any_instance.stub(:config_by_role)
    .with('rabbitmq-server', 'queue')
    .and_return(
      'host' => 'rabbit-host', 'port' => 'rabbit-port'
    )
  ::Chef::Recipe.any_instance.stub(:get_password).and_return('')
  ::Chef::Recipe.any_instance.stub(:secret)
    .with('secrets', 'openstack_identity_bootstrap_token')
    .and_return('bootstrap-token')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with("service", 'openstack-image')
    .and_return('glance-pass')
  ::Chef::Application.stub(:fatal!)
end

def expect_runs_openstack_common_logging_recipe
  it 'runs logging recipe if node attributes say to' do
    expect(@chef_run).to include_recipe 'openstack-common::logging'
  end
end

# TODO(chrislaco): Factor this into proper RSpec shared_contexts
def expect_creates_cache_dir # rubocop:disable MethodLength
  describe '/var/cache/glance' do
    before do
      @dir = @chef_run.directory '/var/cache/glance'
    end

    it 'has proper owner' do
      expect(@dir.owner).to eq('glance')
      expect(@dir.group).to eq('glance')
    end

    it 'has proper modes' do
      expect(sprintf('%o', @dir.mode)).to eq '700'
    end
  end
end

def expect_installs_python_keystone
  it 'installs python-keystone package' do
    expect(@chef_run).to install_package 'python-keystone'
  end
end

def expect_installs_curl
  it 'installs curl package' do
    expect(@chef_run).to install_package 'curl'
  end
end

def expect_installs_ubuntu_glance_packages
  it 'installs glance packages' do
    expect(@chef_run).to upgrade_package 'glance'
  end
end

# TODO(chrislaco): Factor this into proper RSpec shared_contexts
def expect_creates_glance_dir # rubocop:disable MethodLength
  describe '/etc/glance' do
    before do
      @dir = @chef_run.directory '/etc/glance'
    end

    it 'has proper owner' do
      expect(@dir.owner).to eq('glance')
      expect(@dir.group).to eq('glance')
    end

    it 'has proper modes' do
      expect(sprintf('%o', @dir.mode)).to eq '700'
    end
  end
end
