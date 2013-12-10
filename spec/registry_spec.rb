require_relative "spec_helper"

describe "openstack-image::registry" do
  before { image_stubs }
  describe "ubuntu" do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set["openstack"]["image"]["syslog"]["use"] = true
      end
      stub_command("glance-manage db_version").and_return(true)
      @chef_run.converge "openstack-image::registry"
    end

    expect_runs_openstack_common_logging_recipe

    it "doesn't run logging recipe" do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      chef_run.converge "openstack-image::registry"

      expect(chef_run).not_to include_recipe "openstack-common::logging"
    end

    expect_installs_python_keystone

    expect_installs_curl

    it "converges when configured to use sqlite" do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set["openstack"]["db"]["image"]["db_type"] = "sqlite"
      chef_run.converge "openstack-image::registry"
    end

    it "installs mysql python packages" do
      expect(@chef_run).to install_package "python-mysqldb"
    end

    expect_installs_ubuntu_glance_packages

    expect_creates_cache_dir

    it "starts glance registry on boot" do
      expect(@chef_run).to enable_service("glance-registry")
    end

    describe "version_control" do
      before { @cmd = "glance-manage version_control 0" }

      it "versions the database" do
        chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS)
        stub_command("glance-manage db_version").and_return(false)
        chef_run.converge "openstack-image::registry"

        expect(chef_run).to run_execute(@cmd)
      end

      it "doesn't version when glance-manage db_version false" do
        chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS)
        stub_command("glance-manage db_version").and_return(true)
        chef_run.converge "openstack-image::registry"

        expect(chef_run).not_to run_execute(@cmd)
      end
    end

    it "deletes glance.sqlite" do
      expect(@chef_run).to delete_file "/var/lib/glance/glance.sqlite"
    end

    it "does not delete glance.sqlite when configured to use sqlite" do
      chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS)
      node = chef_run.node
      node.set["openstack"]["db"]["image"]["db_type"] = "sqlite"
      stub_command("glance-manage db_version").and_return(true)
      chef_run.converge "openstack-image::registry"
      expect(chef_run).not_to delete_file "/var/lib/glance/glance.sqlite"
    end

    expect_creates_glance_dir

    describe "glance-registry.conf" do
      before do
        @file = @chef_run.template "/etc/glance/glance-registry.conf"
      end

      it "has proper owner" do
        expect(@file.owner).to eq("root")
        expect(@file.group).to eq("root")
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "has bind host when bind_interface not specified" do
        match = "bind_host = 127.0.0.1"
        expect(@chef_run).to render_file(@file.name).with_content(match)
      end

      it "has bind host when bind_interface specified" do
        chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
          n.set["openstack"]["image"]["registry"]["bind_interface"] = "lo"
        end
        chef_run.converge "openstack-image::registry"

        match = "bind_host = 127.0.0.1"
        expect(@chef_run).to render_file(@file.name).with_content(match)
      end

      it "notifies image-registry restart" do
        expect(@file).to notify("service[image-registry]").to(:restart)
      end
    end

    describe "db_sync" do
      before do
        @cmd = "glance-manage db_sync"
      end

      it "runs migrations" do
        expect(@chef_run).to run_execute(@cmd)
      end

      it "doesn't run migrations" do
        chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS) do |n|
          n.set["openstack"]["image"]["db"]["migrate"] = false
        end
        # Lame we must still stub this, since the recipe contains shell
        # guards.  Need to work on a way to resolve this.
        stub_command("glance-manage db_version").and_return(false)
        chef_run.converge "openstack-image::registry"

        expect(chef_run).not_to run_execute(@cmd)
      end
    end

    describe "glance-registry-paste.ini" do
      before do
        @file = @chef_run.template "/etc/glance/glance-registry-paste.ini"
      end

      it "has proper owner" do
        expect(@file.owner).to eq("root")
        expect(@file.group).to eq("root")
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end

      it "notifies image-registry restart" do
        expect(@file).to notify("service[image-registry]").to(:restart)
      end
    end
  end
end
