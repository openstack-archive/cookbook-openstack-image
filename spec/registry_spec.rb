# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::registry' do
  describe 'ubuntu' do
    before do
      # Lame we must still stub this, since the recipe contains shell
      # guards.  Need to work on a way to resolve this.
      stub_command('glance-manage db_version').and_return(true)
    end

    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'image-stubs'
    include_examples 'common-logging-recipe'
    include_examples 'common-packages'
    include_examples 'cache-directory'
    include_examples 'glance-directory'

    it 'converges when configured to use sqlite' do
      node.set['openstack']['db']['image']['service_type'] = 'sqlite'

      expect { chef_run }.to_not raise_error
    end

    it 'installs mysql python packages' do
      expect(chef_run).to install_package('python-mysqldb')
    end

    it 'starts glance registry on boot' do
      expect(chef_run).to enable_service('glance-registry')
    end

    describe 'version_control' do
      let(:cmd) { 'glance-manage version_control 0' }

      it 'versions the database' do
        stub_command('glance-manage db_version').and_return(false)

        expect(chef_run).to run_execute(cmd)
      end

      it 'does not version when glance-manage db_version false' do
        stub_command('glance-manage db_version').and_return(true)

        expect(chef_run).not_to run_execute(cmd)
      end
    end

    it 'deletes glance.sqlite' do
      expect(chef_run).to delete_file('/var/lib/glance/glance.sqlite')
    end

    it 'does not delete glance.sqlite when configured to use sqlite' do
      node.set['openstack']['db']['image']['service_type'] = 'sqlite'

      expect(chef_run).not_to delete_file('/var/lib/glance/glance.sqlite')
    end

    describe 'glance-registry.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-registry.conf') }

      it 'has proper owner' do
        expect(file.owner).to eq('root')
        expect(file.group).to eq('root')
      end

      it 'has proper modes' do
        expect(sprintf('%o', file.mode)).to eq '644'
      end

      it 'has bind host when bind_interface not specified' do
        match = 'bind_host = 127.0.0.1'
        expect(chef_run).to render_file(file.name).with_content(match)
      end

      it 'has bind host when bind_interface specified' do
        node.set['openstack']['image']['registry']['bind_interface'] = 'lo'

        match = 'bind_host = 127.0.1.1'
        expect(chef_run).to render_file(file.name).with_content(match)
      end

      it 'notifies glance-registry restart' do
        expect(file).to notify('service[glance-registry]').to(:restart)
      end
    end

    describe 'db_sync' do
      let(:cmd)  { 'glance-manage db_sync' }

      it 'runs migrations' do
        expect(chef_run).to run_execute(cmd)
      end

      it 'does not run migrations when openstack/image/db/migrate is false' do
        node.set['openstack']['db']['image']['migrate'] = false
        stub_command('glance-manage db_version').and_return(false)

        expect(chef_run).not_to run_execute(cmd)
      end
    end

    describe 'glance-registry-paste.ini' do
      let(:file) { chef_run.template('/etc/glance/glance-registry-paste.ini') }

      it 'has proper owner' do
        expect(file.owner).to eq('root')
        expect(file.group).to eq('root')
      end

      it 'has proper modes' do
        expect(sprintf('%o', file.mode)).to eq '644'
      end

      it 'template contents' do
        pending 'TODO: implement'
      end

      it 'notifies glance-registry restart' do
        expect(file).to notify('service[glance-registry]').to(:restart)
      end
    end
  end
end
