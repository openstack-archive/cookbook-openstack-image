# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::image_upload' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS.merge(step_into: ['openstack_image_image'])) }
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
        image_name: 'cirros',
        image_type: 'qcow',
        image_public: true
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
      stub_command('glance --insecure --os-username admin --os-password admin-pass --os-tenant-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v2.0 image-list | grep imageName').and_return(false)
      expect(chef_run).to upload_openstack_image_image('Image setup for imageName').with(
        image_url: 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-uec.tar.gz',
        image_name: 'imageName',
        image_type: 'unknown',
        image_public: true
      )
      expect(chef_run).to run_bash('Uploading AMI image imageName')
    end

    %w(vhd vmdk vdi iso raw).each do |image_type|
      it "uploads the #{image_type} image" do
        node.set['openstack']['image']['upload_images'] = ["#{image_type}_imageName"]
        node.set['openstack']['image']['upload_image']["#{image_type}_imageName"] = "image_file.#{image_type}"
        node.set['openstack']['image']['upload_image_type']["#{image_type}_imageName"] = "#{image_type}"
        stub_command("glance --insecure --os-username admin --os-password admin-pass --os-tenant-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v2.0 image-list | grep #{image_type}_imageName").and_return(false)
        expect(chef_run).to upload_openstack_image_image("Image setup for #{image_type}_imageName").with(
          image_url: "image_file.#{image_type}",
          image_name: "#{image_type}_imageName",
          image_type: "#{image_type}",
          image_public: true
        )
      end
    end

    it 'uploads the raw and vdi images' do
      node.set['openstack']['image']['upload_images'] = ['raw_imageName', 'vdi_imageName']
      node.set['openstack']['image']['upload_image']['raw_imageName'] = 'image_file.raw'
      node.set['openstack']['image']['upload_image_type']['raw_imageName'] = 'raw'
      node.set['openstack']['image']['upload_image']['vdi_imageName'] = 'image_file.vdi'
      node.set['openstack']['image']['upload_image_type']['vdi_imageName'] = 'vdi'
      stub_command('glance --insecure --os-username admin --os-password admin-pass --os-tenant-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v2.0 image-list | grep raw_imageName').and_return(false)
      stub_command('glance --insecure --os-username admin --os-password admin-pass --os-tenant-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v2.0 image-list | grep vdi_imageName').and_return(false)
      expect(chef_run).to upload_openstack_image_image('Image setup for raw_imageName').with(
        image_url: 'image_file.raw',
        image_name: 'raw_imageName',
        image_type: 'raw',
        image_public: true
      )
      expect(chef_run).to upload_openstack_image_image('Image setup for vdi_imageName').with(
        image_url: 'image_file.vdi',
        image_name: 'vdi_imageName',
        image_type: 'vdi',
        image_public: true
      )
    end

    # TODO(MRV) Need to add provider method testers in here.
  end
end
