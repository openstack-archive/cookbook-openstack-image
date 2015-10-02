# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Provider:: image
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include ::Openstack

action :upload do
  @user = new_resource.identity_user
  @pass = new_resource.identity_pass
  @tenant = new_resource.identity_tenant
  @ks_uri = new_resource.identity_uri

  name = new_resource.image_name
  url = new_resource.image_url
  public = new_resource.image_public

  ep = endpoint 'image-api'
  api = ep.to_s.gsub(ep.path, '') # remove trailing /v2

  type = new_resource.image_type
  type = _determine_type(url) if type == 'unknown'
  _upload_image(type, name, api, url, public ? 'public' : 'private')
  new_resource.updated_by_last_action(true)
end

private

def _determine_type(url)
  # Lets do our best to determine the type from the file extension
  case ::File.extname(url)
  when '.gz', '.tgz'
    return 'ami'
  when '.qcow2', '.img'
    return 'qcow'
  else
    fail ArgumentError, "File extension not supported for #{url}, supported extensions are: .gz, .tgz for ami and .qcow2 and .img for qcow"
  end
end

def _upload_image(type, name, api, url, public)
  case type
  when 'ami'
    _upload_ami(name, api, url, public)
  when 'qcow'
    _upload_image_bare(name, api, url, public, 'qcow2')
  else
    _upload_image_bare(name, api, url, public, type)
  end
end

def _upload_image_bare(name, api, url, public, type)
  glance_cmd = "glance --insecure --os-username #{@user} --os-password #{@pass} --os-tenant-name #{@tenant} --os-image-url #{api} --os-auth-url #{@ks_uri}"
  c_fmt = '--container-format bare'
  d_fmt = "--disk-format #{type}"

  execute "Uploading #{type} image #{name}" do # :pragma-foodcritic: ~FC041
    cwd '/tmp'

    command "curl -L #{url} | #{glance_cmd} image-create --name #{name} --visibility #{public} #{c_fmt} #{d_fmt}"
    not_if "#{glance_cmd} image-list | grep #{name}"
  end
end

# TODO(chrislaco) This refactor is in the works via Craig Tracey
def _upload_ami(name, api, url, public) # rubocop:disable MethodLength
  glance_cmd = "glance --insecure --os-username #{@user} --os-password #{@pass} --os-tenant-name #{@tenant} --os-image-url #{api} --os-auth-url #{@ks_uri}"
  aki_fmt = '--container-format aki --disk-format aki'
  ari_fmt = '--container-format ari --disk-format ari'
  ami_fmt = '--container-format ami --disk-format ami'

  bash "Uploading AMI image #{name}" do
    cwd '/tmp'
    user 'root'
    code <<-EOH
        set -x
        mkdir -p images/#{name}
        cd images/#{name}

        curl -L #{url} | tar -zx
        image_name=$(basename #{url} .tar.gz)

        image_name=${image_name%-multinic}

        kernel_file=$(ls *vmlinuz-virtual | head -n1)
        if [ ${#kernel_file} -eq 0 ]; then
            kernel_file=$(ls *vmlinuz | head -n1)
        fi

        ramdisk=$(ls *-initrd | head -n1)
        if [ ${#ramdisk} -eq 0 ]; then
            ramdisk=$(ls *-loader | head -n1)
        fi

        kernel=$(ls *.img | head -n1)

        kid=$(#{glance_cmd} image-create --name "${image_name}-kernel" --visibility #{public} #{aki_fmt} < ${kernel_file} | grep -m 1 '^|[ ]*id[ ]*|' | cut -d'|' -f3 | sed 's/ //')
        rid=$(#{glance_cmd} image-create --name "${image_name}-initrd" --visibility #{public} #{ari_fmt} < ${ramdisk} | grep -m 1 '^|[ ]*id[ ]*|' | cut -d'|' -f3 | sed 's/ //')
        #{glance_cmd} image-create --name "#{name}" --visibility #{public} #{ami_fmt} --property "kernel_id=$kid" --property "ramdisk_id=$rid" < ${kernel}
    EOH
    not_if "#{glance_cmd} image-list | grep #{name}"
  end
end
