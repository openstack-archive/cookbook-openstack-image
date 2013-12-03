require_relative "spec_helper"

describe "openstack-image::image_upload" do
  before { image_stubs }
  describe "ubuntu" do
    it "uploads qcow image when one does not exist" do
      opts = {
        :step_into => ["openstack_image_image"]
      }
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS.merge(opts) do |n|
        n.set["openstack"]["image"] = {
          "upload_images" => [
            "image1"
          ],
          "upload_image" => {
            "image1" => "http://example.com/image.qcow2"
          }
        }
      end
      list_cmd = "glance --insecure " \
                 "--os-username glance " \
                 "--os-password glance-pass " \
                 "--os-tenant-name service "\
                 "--os-image-url http://127.0.0.1:9292 " \
                 "--os-auth-url http://127.0.0.1:5000/v2.0 " \
                 "image-list | grep image1"
      stub_command(list_cmd).and_return(false)
      chef_run.converge("openstack-image::image_upload")

      expect(chef_run).to run_execute("Uploading QCOW2 image image1")
    end

    it "does not upload qcow image if it already exists" do
      opts = {
        :step_into => ["openstack_image_image"]
      }
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS.merge(opts) do |n|
        n.set["openstack"]["image"] = {
          "upload_images" => [
            "image1"
          ],
          "upload_image" => {
            "image1" => "http://example.com/image.qcow2"
          }
        }
      end
      list_cmd = "glance --insecure " \
                 "--os-username glance " \
                 "--os-password glance-pass " \
                 "--os-tenant-name service "\
                 "--os-image-url http://127.0.0.1:9292 " \
                 "--os-auth-url http://127.0.0.1:5000/v2.0 " \
                 "image-list | grep image1"
      stub_command(list_cmd).and_return(true)
      chef_run.converge("openstack-image::image_upload")

      expect(chef_run).to_not run_execute("Uploading QCOW2 image image1")
    end
  end
end
