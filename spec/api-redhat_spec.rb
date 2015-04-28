# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::api' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'image-stubs'

    it 'does upgrade keystoneclient package' do
      expect(chef_run).to upgrade_package('python-keystoneclient')
    end

    it 'does not upgrade swift packages by default' do
      expect(chef_run).not_to upgrade_package('openstack-swift')
    end

    it 'upgrades swift package if openstack/image/api/default_store is swift' do
      node.set['openstack']['image']['api']['default_store'] = 'swift'

      expect(chef_run).to upgrade_package('openstack-swift')
    end

    it 'starts glance api on boot' do
      expect(chef_run).to enable_service('openstack-glance-api')
    end
  end
end
