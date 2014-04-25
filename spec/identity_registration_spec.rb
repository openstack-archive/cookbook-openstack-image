# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::identity_registration' do
  let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
  let(:node) { runner.node }
  let(:chef_run) do
    runner.converge(described_recipe)
  end

  include_context 'image-stubs'

  it 'registers image service' do
    resource = chef_run.find_resource(
      'openstack-identity_register',
      'Register Image Service'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      service_type: 'image',
      service_description: 'Glance Image Service',
      action: [:create_service]
    )
  end

  context 'registers compute endpoint' do
    it 'with default values' do
      resource = chef_run.find_resource(
        'openstack-identity_register',
        'Register Image Endpoint'
      ).to_hash

      expect(resource).to include(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_type: 'image',
        endpoint_region: 'RegionOne',
        endpoint_adminurl: 'http://127.0.0.1:9292',
        endpoint_internalurl: 'http://127.0.0.1:9292',
        endpoint_publicurl: 'http://127.0.0.1:9292',
        action: [:create_endpoint]
      )
    end

    it 'with custom region override' do
      node.set['openstack']['image']['region'] = 'imageRegion'

      resource = chef_run.find_resource(
        'openstack-identity_register',
        'Register Image Endpoint'
      ).to_hash

      expect(resource).to include(
        endpoint_region: 'imageRegion',
        action: [:create_endpoint]
      )
    end
  end

  it 'registers service tenant' do
    resource = chef_run.find_resource(
      'openstack-identity_register',
      'Register Service Tenant'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      tenant_name: 'service',
      tenant_description: 'Service Tenant',
      tenant_enabled: true,
      action: [:create_tenant]
    )
  end

  it 'registers service user' do
    resource = chef_run.find_resource(
      'openstack-identity_register',
      'Register glance User'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      tenant_name: 'service',
      user_name: 'glance',
      user_pass: 'glance-pass',
      user_enabled: true,
      action: [:create_user]
    )
  end

  it 'grants admin role to service user for service tenant' do
    resource = chef_run.find_resource(
      'openstack-identity_register',
      "Grant 'admin' Role to glance User for service Tenant"
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      tenant_name: 'service',
      role_name: 'admin',
      user_name: 'glance',
      action: [:grant_role]
    )
  end
end
