Gem::Specification.new do |s|
  s.name	= "virtuoso-prototype"
  s.version	= "0.0.1"
  s.platform	= Gem::Platform::RUBY
  s.authors	= ["Justin Lynn"]
  s.email	= ["eng@3crowd.com"]
  s.homepage	= "http://github.com/3Crowd/Virtuoso-prototype"
  s.summary	= "A protoype for managing virtualbox VMs, scripts VBoxManage"
  s.description = "A quick and dirty prototype for managing virtualbox virtual machines, only scripts VBoxManage to eliminate bringup of a raw VM"

  s.required_rubygems_version	= ">= 1.3.6"

  s.files	= Dir.glob("{bin,lib}/**/*") + %w(LICENSE README)
  s.executables	= ['virtuoso-prototype']
  s.require_path = 'lib'
end
