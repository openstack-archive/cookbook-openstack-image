require_relative 'spec_helper'

describe 'openstack-image::image_upload' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS.merge(step_into: ['openstack_image_image'])) }
    let(:node) { runner.node }
    cached(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'image-stubs'

    it do
      stub_command('glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list | grep cirros').and_return(false)
      expect(chef_run).to upgrade_package('curl')
    end

    it 'uploads the cirros image' do
      stub_command('glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list | grep cirros').and_return(false)
      expect(chef_run).to upload_openstack_image_image('Image setup for cirros').with(
        image_url: 'http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img',
        image_name: 'cirros',
        image_type: 'qcow',
        image_public: true,
        image_id: 'e1847f1a-01d2-4957-a067-b56085bf3781',
        identity_user: 'admin',
        identity_pass: 'admin-pass',
        identity_tenant: 'admin',
        identity_uri: 'http://127.0.0.1:5000/v3'
      )
    end

    context 'raises error for unsupported image extension type' do
      cached(:chef_run) do
        node.override['openstack']['image']['upload_images'] = ['image1']
        node.override['openstack']['image']['upload_image']['image1'] = 'http://download.net/image.xxx'
        runner.converge(described_recipe)
      end
      it do
        expect { chef_run }.to raise_error(ArgumentError)
      end
    end

    context 'uploads the tar image' do
      cached(:chef_run) do
        node.override['openstack']['image']['upload_images'] = ['imageName']
        node.override['openstack']['image']['upload_image']['imageName'] = 'http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-uec.tar.gz'
        runner.converge(described_recipe)
      end
      it do
        stub_command('glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list | grep imageName').and_return(false)
        expect(chef_run).to upload_openstack_image_image('Image setup for imageName').with(
          image_url: 'http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-uec.tar.gz',
          image_name: 'imageName',
          image_type: 'unknown',
          image_public: true
        )
        expect(chef_run).to run_bash('Uploading AMI image imageName')
      end
    end

    %w(vhd vmdk vdi iso raw).each do |image_type|
      context "uploads the #{image_type} image" do
        cached(:chef_run) do
          node.override['openstack']['image']['upload_images'] = ["#{image_type}_imageName"]
          node.override['openstack']['image']['upload_image']["#{image_type}_imageName"] = "image_file.#{image_type}"
          node.override['openstack']['image']['upload_image_type']["#{image_type}_imageName"] = image_type.to_s
          runner.converge(described_recipe)
        end
        it do
          stub_command("glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list | grep #{image_type}_imageName").and_return(false)
          expect(chef_run).to upload_openstack_image_image("Image setup for #{image_type}_imageName").with(
            image_url: "image_file.#{image_type}",
            image_name: "#{image_type}_imageName",
            image_type: image_type.to_s,
            image_public: true
          )
        end
      end
    end

    context 'uploads the raw and vdi images' do
      cached(:chef_run) do
        node.override['openstack']['image']['upload_images'] = %w(raw_imageName vdi_imageName)
        node.override['openstack']['image']['upload_image']['raw_imageName'] = 'image_file.raw'
        node.override['openstack']['image']['upload_image_type']['raw_imageName'] = 'raw'
        node.override['openstack']['image']['upload_image']['vdi_imageName'] = 'image_file.vdi'
        node.override['openstack']['image']['upload_image_type']['vdi_imageName'] = 'vdi'
        runner.converge(described_recipe)
      end
      it do
        stub_command('glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list | grep raw_imageName').and_return(false)
        stub_command('glance --insecure --os-username admin --os-password admin-pass --os-project-name admin --os-image-url http://127.0.0.1:9292 --os-auth-url http://127.0.0.1:5000/v3 --os-user-domain-name Default --os-project-domain-name Default image-list | grep vdi_imageName').and_return(false)
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
    end
    # TODO(MRV) Need to add provider method testers in here.
  end
end
