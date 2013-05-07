require "spec_helper"

describe "glance::api" do
  describe "redhat" do
    before do
      glance_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "glance::api"
    end

    it "starts glance api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-glance-api"
    end
  end
end
