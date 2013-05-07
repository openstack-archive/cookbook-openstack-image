require "spec_helper"

describe "glance::registry" do
  describe "ubuntu" do
    before do
      glance_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @node = @chef_run.node
      @node.set["glance"]["syslog"]["use"] = true
      @chef_run.converge "glance::registry"
    end

    expect_runs_openstack_common_logging_recipe

    expect_installs_python_keystone

    expect_installs_curl

    it "installs mysql python packages" do
      expect(@chef_run).to install_package "python-mysqldb"
    end

    expect_installs_ubuntu_glance_packages

    expect_creates_cache_dir

    it "starts glance registry on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "glance-registry"
    end

    it "versions the database" do
      cmd = "glance-manage version_control 0"
      expect(@chef_run).to execute_command cmd
    end

    it "deletes glance.sqlite" do
      expect(@chef_run).to delete_file "/var/lib/glance/glance.sqlite"
    end

    expect_creates_glance_dir

    describe "glance-registry.conf" do
      before do
        @file = @chef_run.template "/etc/glance/glance-registry.conf"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end

      it "notifies nova-api-ec2 restart" do
        expect(@file).to notify "service[glance-registry]", :restart
      end
    end

    it "runs db migrations" do
      cmd = "glance-manage db_sync"
      expect(@chef_run).to execute_command cmd
    end

    describe "glance-registry-paste.ini" do
      before do
        @file = @chef_run.template "/etc/glance/glance-registry-paste.ini"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end

      it "notifies nova-api-ec2 restart" do
        expect(@file).to notify "service[glance-registry]", :restart
      end
    end
  end
end
