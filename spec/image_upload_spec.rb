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

    it 'uploads the tar image' do
      node.set['openstack']['image']['upload_images'] = ['imageName']
      node.set['openstack']['image']['upload_image']['imageName'] = 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-uec.tar.gz'
      stub_command('glance --insecure --os-username glance --os-password glance-pass --os-tenant-name service --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v2.0 image-list | grep imageName').and_return(false)
      expect(chef_run).to upload_openstack_image_image('Image setup for imageName').with(
        image_url: 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-uec.tar.gz',
        image_name: 'imageName'
      )
      expect(chef_run).to run_bash('Uploading AMI image imageName')
    end

    # TODO(MRV) Need to add provider method testers in here.
  end
end
