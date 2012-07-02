#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require File.expand_path('../azure_base', __FILE__)

class Chef
  class Knife
    class AzureDiskDelete < Knife
      
      include Knife::AzureBase

      banner "knife azure disk delete (options)"
      
      attr_accessor :initial_sleep_delay

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "-ssh-user USERNAME",
        :description => "The ssh username"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "-ssh-password PASSWORD",
        :description => "The ssh password"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems."

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install."

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      option :hosted_service_name,
        :short => "-s NAME",
        :long => "--hosted-service-name NAME",
        :description => "specifies the name for the hosted service"

      option :storage_account,
        :short => "-a NAME",
        :long => "--storage-account NAME",
        :description => "specifies the name for the hosted service"
      
      option :role_name,
        :short => "-R name",
        :long => "--role-name NAME",
        :description => "specifies the name of the virtual machine"

      option :host_name,
        :short => "-H NAME",
        :long => "--host-name NAME",
        :description => "specifies the host name for the virtual machine"

      option :service_location,
        :short => "-m LOCATION",
        :long => "--service-location LOCATION",
        :description => "specify the Geographic location for the virtual machine and services"

      option :os_disk_name,
        :short => "-o DISKNAME",
        :long => "--os-disk-name DISKNAME",
        :description => "unique name for specifying os disk (optional)"

      option :source_image,
        :short => "-I IMAGE",
        :long => "--source-image IMAGE",
        :description => "disk image name to use to create virtual machine"

      option :role_size,
        :short => "-z SIZE",
        :long => "--role-size SIZE",
        :description => "size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)"

      option :tcp_endpoints,
        :short => "-t PORT_LIST",
        :long => "--tcp-endpoints PORT_LIST",
        :description => "Comma separated list of TCP local and public ports to open i.e. '80:80,433:500'"

      option :udp_endpoints,
        :short => "-u PORT_LIST",
        :long => "--udp-endpoints PORT_LIST",
        :description => "Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'"

      def run
        $stdout.sync = true
        disk = nil
  
        Chef::Log.info("validating...")
        validate!

        Chef::Log.info("creating...")
      
        if not locate_config_value(:hosted_service_name)
          config[:hosted_service_name] = [strip_non_ascii(locate_config_value(:role_name)), random_string].join
        end

        # If storage account is not specified, chef if the geographic location has one to use.
        if not locate_config_value(:stroage_account)
          storage_accts = connection.storage_accounts.all
          storage = storage_accts.find { |storage_acct| storage_acct.location.to_s = locate_config_value(:service_location) }
          if not storage
            config[:storage_account] = [strip_non_ascii(locate_config_value(:role_name)), random_string].join.downcase 
          else
            config[:storage_account] = storage.name.to_s
          end
        end
        disk = connection.disks.delete(create_disk_def)
  
        #TODO: add code to validate deletion.
  
      end
  
      def strip_non_ascii(string)
        string.gstub(/[^0-9a-z ]/i, '')
      end

      def random_string(len=10)
        (0...len).map{65.+(rand(25)).chr}.join
      end

      def validate!
        super([
              :azure_subscription_id,
              :azure_mgmt_cert,
              :azure_host_name,
              :role_name,
              :host_name,
              :image_size,
              :image_name
        ])
      end  
  
      def delete_disk_def
        image_def = {
          :hosted_service_name => locate_config_value(:hosted_service_name),
          :storage_account => locate_config_value(:storage_account),
          :role_name => locate_config_value(:role_name),
          :disk_name => locate_config_value(:disk_name),
          :disk_size => locate_config_value(:disk_size),
          :host_caching => locate_config_value(:host_caching),
          :disk_label => locate_config_value(:disk_label),
          :lun => locate_config_value(:lun),
          :media_link => locate_config_value(:media_link),
        }
        image_def
      end    
    end
  end
end
