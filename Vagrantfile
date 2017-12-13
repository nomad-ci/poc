# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.box_check_update = false

  config.vm.network "forwarded_port", guest: 4646, host: 4646 ## nomad
  config.vm.network "forwarded_port", guest: 9992, host: 9992 ## fabio

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", path: "vagrant-provision.sh"
end
