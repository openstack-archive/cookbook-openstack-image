require_relative "spec_helper"

describe "openstack-image::api" do
  before { image_stubs }
  describe "redhat" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-image::api"
    end

    it "does not install swift packages" do
      expect(@chef_run).not_to upgrade_package "openstack-swift"
    end

    it "has configurable default_store setting for swift" do
      chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS do |n|
        n.set["openstack"]["image"]["api"]["default_store"] = "swift"
      end
      chef_run.converge "openstack-image::api"

      expect(chef_run).to upgrade_package "openstack-swift"
    end

    it "starts glance api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-glance-api"
    end
  end
end
