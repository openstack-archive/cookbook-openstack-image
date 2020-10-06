require_relative 'spec_helper'

describe 'openstack-image::identity_registration' do
  let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
  let(:node) { runner.node }
  cached(:chef_run) do
    runner.converge(described_recipe)
  end

  include_context 'image-stubs'

  connection_params = {
    openstack_auth_url: 'http://127.0.0.1:5000/v3',
    openstack_username: 'admin',
    openstack_api_key: 'admin-pass',
    openstack_project_name: 'admin',
    openstack_domain_name: 'default',
    # openstack_endpoint_type: 'internalURL',
  }
  service_name = 'glance'
  service_type = 'image'
  service_user = 'glance'
  url = 'http://127.0.0.1:9292'
  region = 'RegionOne'
  project_name = 'admin'
  role_name = 'admin'
  password = 'glance-pass'
  domain_name = 'Default'

  it "registers #{project_name} Project" do
    expect(chef_run).to create_openstack_project(
      project_name
    ).with(
      connection_params: connection_params
    )
  end

  it "registers #{service_name} service" do
    expect(chef_run).to create_openstack_service(
      service_name
    ).with(
      connection_params: connection_params,
      type: service_type
    )
  end

  context "registers #{service_name} endpoint" do
    %w(internal public).each do |interface|
      it "#{interface} endpoint with default values" do
        expect(chef_run).to create_openstack_endpoint(
          service_type
        ).with(
          service_name: service_name,
          # interface: interface,
          url: url,
          region: region,
          connection_params: connection_params
        )
      end
    end
  end

  it 'registers service user' do
    expect(chef_run).to create_openstack_user(
      service_user
    ).with(
      domain_name: domain_name,
      project_name: project_name,
      password: password,
      connection_params: connection_params
    )
  end

  it do
    expect(chef_run).to grant_role_openstack_user(
      service_user
    ).with(
      project_name: project_name,
      role_name: role_name,
      password: password,
      domain_name: domain_name,
      connection_params: connection_params
    )
  end
end
