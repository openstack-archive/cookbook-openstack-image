require_relative 'spec_helper'

describe 'openstack-image::api' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) do
        runner.converge(described_recipe)
      end

      include_context 'image-stubs'

      case p
      when REDHAT_7
        it 'does not upgrade keystoneclient package' do
          expect(chef_run).not_to upgrade_package('python-keystoneclient')
        end
      when REDHAT_8
        it 'does not upgrade keystoneclient package' do
          expect(chef_run).not_to upgrade_package('python3-keystoneclient')
        end
      end

      it 'does not upgrade swift packages by default' do
        expect(chef_run).not_to upgrade_package('openstack-swift')
      end

      it do
        expect(chef_run).to enable_service('openstack-glance-api')
      end
    end
  end
end
