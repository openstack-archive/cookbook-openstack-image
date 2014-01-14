# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::registry' do
  before { image_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-image::registry'
    end

    it 'converges when configured to use sqlite' do
      chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      node = chef_run.node
      node.set['openstack']['db']['image']['db_type'] = 'sqlite'
      chef_run.converge 'openstack-image::registry'
    end

    it 'installs mysql python packages' do
      expect(@chef_run).to install_package 'MySQL-python'
    end

    it 'installs db2 python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      node = chef_run.node
      node.set['openstack']['db']['image']['db_type'] = 'db2'
      chef_run.converge 'openstack-image::registry'

      ['db2-odbc', 'python-ibm-db', 'python-ibm-db-sa'].each do |pkg|
        expect(chef_run).to install_package pkg
      end
    end

    it 'installs glance packages' do
      expect(@chef_run).to upgrade_package 'openstack-glance'
      expect(@chef_run).to upgrade_package 'cronie'
    end

    it 'starts glance registry on boot' do
      expected = 'openstack-glance-registry'
      expect(@chef_run).to enable_service(expected)
    end

    it 'does not version the database' do
      chef_run = ::ChefSpec::Runner.new(::REDHAT_OPTS)
      stub_command('glance-manage db_version').and_return(false)
      chef_run.converge 'openstack-image::registry'
      cmd = 'glance-manage version_control 0'

      expect(chef_run).not_to run_execute(cmd)
    end
  end
end
