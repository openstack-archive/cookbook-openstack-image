require_relative "spec_helper"

describe "openstack-image::registry" do
  describe "redhat" do
    before do
      image_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-image::registry"
    end

    it "installs mysql python packages" do
      expect(@chef_run).to install_package "MySQL-python"
    end

    it "installs glance packages" do
      expect(@chef_run).to upgrade_package "openstack-glance"
      expect(@chef_run).to upgrade_package "openstack-swift"
      expect(@chef_run).to upgrade_package "cronie"
    end

    it "starts glance registry on boot" do
      expected = "openstack-glance-registry"
      expect(@chef_run).to set_service_to_start_on_boot expected
    end

    it "doesn't version the database" do
      pending "TODO: how to test this"
    end
  end
end
