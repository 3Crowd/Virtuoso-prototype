require 'rubygems'
require 'virtualbox'
require 'systemu'
require 'logger'
require 'uuid'

module Virtuoso
module VirtualBox         

  class Interface

    def initialize
      @log = Logger.new(STDOUT)
      @virtualbox = Hash.new
      @virtualbox[:version] = ::VirtualBox.version
    end

    def create!(vm_name, bond_interface, disk_size)
      vm = create_vm!(vm_name)
      vm = setup_vm!(vm)
      vm.reload
      storage_controller = add_storage_controller!(vm)
      disk = create_disk!(vm_name, disk_size)
      attach_disk!(vm, storage_controller, disk)
      add_bridged_network_interface!(vm, 1, bond_interface)
    end

    def destroy!(vm_name, physically_delete_media=true)
      vm = ::VirtualBox::VM.find(vm_name)
      raise Errors::VMNotFoundError if vm.nil?
      vm.destroy(:destroy_medium => physically_delete_media )
    end

    def installed?
      @virtualbox[:version].nil? ? false : true
    end

    private

    def add_bridged_network_interface!(vm, interface_number, bridge_interface)
      status, stdout, stderr = systemu "VBoxManage modifyvm --nic#{interface_number} bridged --bridgeadapter#{interface_number} #{bridge_interface}"
      @log.debug("Ran VBoxManage add network interface: output (#{status}):")
      @log.debug("Standard out: " + stdout)
      @log.debug("Standard err: " + stderr)
      @ Reload the vm config, to pick up command line changes
      vm.reload
      vm.network_interfaces[interface_number-1]
    end

    def add_storage_controller!(vm)
      uuid = UUID.new.generate
      #FIXME: we have to shell out here since the virtualbox gem does not provide an easy method for creating storage controllers from scratch
      status, stdout, stderr = systemu "VBoxManage storagectl #{vm.uuid} --name #{uuid} --add sata"
      @log.debug("Ran VBoxManage add storage controller: output (#{status}):")
      @log.debug("Standard out: " + stdout)
      @log.debug("Standard err: " + stderr)
      # Reload the vm config, to pick up the command line changes
      vm.reload
      vm.storage_controllers.select{|controller| controller.name == uuid }.first
    end

    def attach_disk!(vm, storage_controller, disk)
      @log.debug("Got storage_controller #{storage_controller.inspect}, Got Disk #{disk.inspect}")
      #FIXME: we have to shell out here since the virtualbox gem does not provide an easy to find method for attaching disk images to VMs
      command = "VBoxManage storageattach #{vm.uuid} --storagectl #{storage_controller.name} --port 0 --device 0 --type hdd --medium #{disk.uuid} "
      @log.debug("Running: #{command}")
      status, disk_attach_stdout, disk_attach_stderr = systemu(command)
      @log.debug("Ran VBoxManage storageattach output (#{status}):")
      @log.debug("Standard out: " + disk_attach_stdout)
      @log.debug("Standard err: " + disk_attach_stderr)
    end

    def setup_vm!(vm)
      vm.vram_size = 24 #megabytes
      vm.memory_size = 512 #megabytes
      vm.save
      return vm
    end

    def create_vm!(vm_name)
      #FIXME: we have to shell out here since the virtualbox gem does not provide a method for creating new VMs directly through the library
      status, vm_create_output_stdout, vm_create_output_stderr = systemu "VBoxManage createvm --name #{vm_name} --register"
      @log.debug("Ran VBoxManage createvm output (#{status}):")
      @log.debug("Standard out: " + vm_create_output_stdout)
      @log.debug("Standard err: " + vm_create_output_stderr)
      unless status != 0
        return ::VirtualBox::VM.find(vm_name)
      else
        raise Errors::VMNotCreatedError
      end
    end

    def create_disk!(disk_name, disk_size)
      disk = ::VirtualBox::HardDrive.new
      disk.format = "VDI"
      disk.location = "#{disk_name}.vdi"
      disk.logical_size = disk_size # in megabytes
      if disk.save
        return disk
      else
        raise Errors::DiskNotCreatedError.new(disk.inspect)
      end
    end

  end

end
end

