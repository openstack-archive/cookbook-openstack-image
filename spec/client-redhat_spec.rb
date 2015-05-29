# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::client' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    it 'upgrades python glance client package' do
      expect(chef_run).to upgrade_package('python-glanceclient')
    end
  end
end
