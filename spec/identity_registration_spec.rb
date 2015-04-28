# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-image::identity_registration' do
  let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
  let(:node) { runner.node }
  let(:chef_run) do
    runner.converge(described_recipe)
  end

  include_context 'image-stubs'

  it 'registers image service' do
    expect(chef_run).to create_service_openstack_identity_register('Register Image Service')
      .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
            bootstrap_token: 'bootstrap-token',
            service_type: 'image',
            service_description: 'Glance Image Service'
           )
  end

  context 'registers compute endpoint' do
    it 'with default values' do
      expect(chef_run).to create_endpoint_openstack_identity_register('Register Image Endpoint')
        .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
              bootstrap_token: 'bootstrap-token',
              service_type: 'image',
              endpoint_region: 'RegionOne',
              endpoint_adminurl: 'http://127.0.0.1:9292',
              endpoint_internalurl: 'http://127.0.0.1:9292',
              endpoint_publicurl: 'http://127.0.0.1:9292'
             )
    end

    it 'with custom region override' do
      node.set['openstack']['image']['region'] = 'imageRegion'
      expect(chef_run).to create_endpoint_openstack_identity_register('Register Image Endpoint')
        .with(endpoint_region: 'imageRegion')
    end

    it 'with different public url' do
      public_url = 'https://public.host:123/public_path'
      node.set['openstack']['endpoints']['public']['image-api']['uri'] = public_url

      expect(chef_run).to create_endpoint_openstack_identity_register('Register Image Endpoint')
        .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
              bootstrap_token: 'bootstrap-token',
              service_type: 'image',
              endpoint_region: 'RegionOne',
              endpoint_adminurl: 'http://127.0.0.1:9292',
              endpoint_internalurl: 'http://127.0.0.1:9292',
              endpoint_publicurl: public_url
             )
    end

    it 'with different admin url' do
      admin_url = 'http://admin.host:456/admin_path'
      node.set['openstack']['endpoints']['admin']['image-api']['uri'] = admin_url
      node.set['openstack']['endpoints']['identity-admin']['uri'] = 'http://127.0.0.1:35357/v2.0'

      expect(chef_run).to create_endpoint_openstack_identity_register('Register Image Endpoint')
        .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
              bootstrap_token: 'bootstrap-token',
              service_type: 'image',
              endpoint_region: 'RegionOne',
              endpoint_adminurl: admin_url,
              endpoint_internalurl: 'http://127.0.0.1:9292',
              endpoint_publicurl: 'http://127.0.0.1:9292'
             )
    end

    it 'with different internal url' do
      internal_url = 'http://internal.host:789/internal_path'
      node.set['openstack']['endpoints']['internal']['image-api']['uri'] = internal_url

      expect(chef_run).to create_endpoint_openstack_identity_register('Register Image Endpoint')
        .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
              bootstrap_token: 'bootstrap-token',
              service_type: 'image',
              endpoint_region: 'RegionOne',
              endpoint_adminurl: 'http://127.0.0.1:9292',
              endpoint_internalurl: internal_url,
              endpoint_publicurl: 'http://127.0.0.1:9292'
      )
    end

    it 'with different admin,internal,public urls' do
      internal_url = 'http://internal.host:789/internal_path'
      admin_url = 'http://admin.host:456/admin_path'
      public_url = 'https://public.host:123/public_path'
      node.set['openstack']['endpoints']['internal']['image-api']['uri'] = internal_url
      node.set['openstack']['endpoints']['admin']['image-api']['uri'] = admin_url
      node.set['openstack']['endpoints']['identity-admin']['uri'] = 'http://127.0.0.1:35357/v2.0'
      node.set['openstack']['endpoints']['public']['image-api']['uri'] = public_url

      expect(chef_run).to create_endpoint_openstack_identity_register('Register Image Endpoint')
        .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
              bootstrap_token: 'bootstrap-token',
              service_type: 'image',
              endpoint_region: 'RegionOne',
              endpoint_adminurl: admin_url,
              endpoint_internalurl: internal_url,
              endpoint_publicurl: public_url
             )
    end
  end

  it 'registers service tenant' do
    expect(chef_run).to create_tenant_openstack_identity_register('Register Service Tenant')
      .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
            bootstrap_token: 'bootstrap-token',
            tenant_name: 'service',
            tenant_description: 'Service Tenant',
            tenant_enabled: true
           )
  end

  it 'registers service user' do
    expect(chef_run).to create_user_openstack_identity_register('Register glance User')
      .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
            bootstrap_token: 'bootstrap-token',
            tenant_name: 'service',
            user_name: 'glance',
            user_pass: 'glance-pass',
            user_enabled: true
           )
  end

  it 'grants service role to service user for service tenant' do
    expect(chef_run).to grant_role_openstack_identity_register("Grant 'service' Role to glance User for service Tenant")
      .with(auth_uri: 'http://127.0.0.1:35357/v2.0',
            bootstrap_token: 'bootstrap-token',
            tenant_name: 'service',
            role_name: 'service',
            user_name: 'glance'
           )
  end
end
