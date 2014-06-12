# encoding: UTF-8
if defined?(ChefSpec)
  def upload_openstack_image_image(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:openstack_image_image, :upload, resource_name)
  end
end
