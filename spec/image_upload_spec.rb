# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::image_upload' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS.merge(step_into: ['openstack_image_image'])) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'image-stubs'

    include_examples 'common-logging-recipe'

    it 'upgrades the client packages' do
      expect(chef_run).to upgrade_package('python-glanceclient')
    end

    it 'uploads the cirros image' do
      expect(chef_run).to upload_openstack_image_image('Image setup for cirros').with(
      image_url: 'http://download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img',
      image_name: 'cirros'
      )
    end

    it 'raises error for unsupported image extension type' do
      node.set['openstack']['image']['upload_images'] = ['image1']
      node.set['openstack']['image']['upload_image']['image1'] = 'http://download.net/image.xxx'
      expect { chef_run }.to raise_error(ArgumentError)
    end
  end
end
