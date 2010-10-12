$:.unshift(File.expand_path(File.dirname(__FILE__))) unless $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'virtuoso/errors'
require 'virtuoso/virtualbox'

#Choice, a command line option parser
require 'choice'
require 'logger'

module Virtuoso

class CLI

  def initialize
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @vm_interface = VirtualBox::Interface.new
  end

  def run(arguments=[])
    setup_cli_arguments!
    options = parse_arguments(arguments)
    ensure_virtualbox_installed
    perform_action!(options[:operation], options[:vm_name], options[:bond_interface], options[:disk_size])
  end

  private

  def perform_action!(operation, vm_name, bond_interface, disk_size)
    case operation
      when 'create' then
        @vm_interface.create!(vm_name, bond_interface, disk_size)
      when 'destroy' then
        @vm_interface.destroy!(vm_name, :delete)
      else
        raise RuntimeError.new("Got operation option that should not be valid: #{operation}")
    end
  end

  def ensure_virtualbox_installed
    unless @vm_interface.installed?
      raise Error::VirtualBoxNotInstalledError
    end
  end

  def setup_cli_arguments!
    Choice.options do
      header 'Virtuoso Virtual Manager'
      header 'Specific options:'

      option :operation do
        short '-o'
        long '--operation=OPERATION'
        desc 'The operation you wish to perform (create, or destroy) (default: create)'
        valid %w[create destroy]
        default 'create'
      end

      option :vm_name, :required => true do
        short '-n'
        long '--vmname=VMNAME'
        desc 'The virtual machine you wish to operate on (required)'
      end

      option :bond_interface, :required => true do
        short '-i'
        long '--bond_interface=INTERFACE0'
        desc 'The network interface on the host machine to which the virtual network interface should bond'
      end

      option :disk_size do
        short '-d'
        long '--disk_size=MEGABYTES'
        desc 'The size of the virtual disk allocated to the virtualmachine in megabytes'
        cast Integer
        default 8000
      end

    end
  end

  def parse_arguments(arguments)
    @log.debug("Got choices: #{ Choice.choices.inspect }")
    Choice.choices
  end

end

end
