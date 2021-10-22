require_relative 'spec_helper'

describe 'openstack-image::swift_store' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) do
        runner.converge(described_recipe)
      end
      include_context 'image-stubs'
      it do
        expect(chef_run).to upgrade_package('openstack-swift')
      end
    end
  end
end
