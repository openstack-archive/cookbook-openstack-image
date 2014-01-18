# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::image_upload' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(options) }
    let(:options) { UBUNTU_OPTS.merge(step_into: 'openstack_image_image') }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'image-stubs'

    it 'uploads qcow image when one does not exist' do
      node.set['openstack']['image'] = {
        'upload_images' => ['image1'],
        'upload_image' => {
          'image1' => 'http://example.com/image.qcow2'
        }
      }

      list_cmd = 'glance --insecure ' \
                 '--os-username glance ' \
                 '--os-password glance-pass ' \
                 '--os-tenant-name service '\
                 '--os-image-url http://127.0.0.1:9292 ' \
                 '--os-auth-url http://127.0.0.1:5000/v2.0 ' \
                 'image-list | grep image1'

      stub_command(list_cmd).and_return(false)

      expect(chef_run).to run_execute('Uploading QCOW2 image image1')
    end

    it 'does not upload qcow image if it already exists' do
      node.set['openstack']['image'] = {
        'upload_images' => ['image1'],
        'upload_image' => {
          'image1' => 'http://example.com/image.qcow2'
        }
      }

      list_cmd = "glance --insecure " \
                 "--os-username glance " \
                 "--os-password glance-pass " \
                 "--os-tenant-name service "\
                 "--os-image-url http://127.0.0.1:9292 " \
                 "--os-auth-url http://127.0.0.1:5000/v2.0 " \
                 "image-list | grep image1"

      stub_command(list_cmd).and_return(true)

      expect(chef_run).to_not run_execute('Uploading QCOW2 image image1')
    end
  end
end
