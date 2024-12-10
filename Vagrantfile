Vagrant.configure("2") do |config|
  
  config.vm.define "web1" do |web1|
    web1.vm.box = "ubuntu/focal64"
    web1.vm.network "private_network", type: "static", ip: "192.168.51.121"
    web1.vm.hostname = "web1"
    config.vm.synced_folder "./setup_files/", "/vagrant"

    web1.vm.disk :disk, size: "3GB", name: "sdc"
    web1.vm.disk :disk, size: "3GB", name: "sdd"

    web1.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
    end

    web1.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/*.sh
      bash /vagrant/first.sh
      bash /vagrant/hosts.sh
      bash /vagrant/raid.sh
      bash /vagrant/glusterfs.sh
      bash /vagrant/webserver.sh
      sudo reboot
    SHELL
  end

  config.vm.define "web2" do |web2|
    web2.vm.box = "ubuntu/focal64"
    web2.vm.network "private_network", type: "static", ip: "192.168.51.122"
    web2.vm.hostname = "web2"
    config.vm.synced_folder "setup_files/", "/vagrant"

    web2.vm.disk :disk, size: "3GB", name: "sdc"
    web2.vm.disk :disk, size: "3GB", name: "sdd"

    web2.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
    end

    web2.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/*.sh
      bash /vagrant/first.sh
      bash /vagrant/hosts.sh
      bash /vagrant/raid.sh
      bash /vagrant/glusterfs.sh
      bash /vagrant/webserver.sh
      sudo reboot
    SHELL
  end

  config.vm.define "haproxy1" do |haproxy1|
    haproxy1.vm.box = "ubuntu/focal64"
    haproxy1.vm.network "private_network", type: "static", ip: "172.20.51.200"
    haproxy1.vm.network "private_network", type: "static", ip: "192.168.51.100"
    haproxy1.vm.hostname = "haproxy1"
    config.vm.synced_folder "setup_files/", "/vagrant"

    haproxy1.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    haproxy1.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/*.sh
      bash /vagrant/first.sh
      bash /vagrant/hosts.sh
      bash /vagrant/ha_proxy.sh
      bash /vagrant/cluster_proxy.sh
      sudo reboot
    SHELL
  end

  config.vm.define "haproxy2" do |haproxy2|
    haproxy2.vm.box = "ubuntu/focal64"
    haproxy2.vm.network "private_network", type: "static", ip: "172.20.51.201"
    haproxy2.vm.network "private_network", type: "static", ip: "192.168.51.101"
    haproxy2.vm.hostname = "haproxy2"
    config.vm.synced_folder "setup_files/", "/vagrant"

    haproxy2.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    haproxy2.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/*.sh
      bash /vagrant/first.sh
      bash /vagrant/hosts.sh
      bash /vagrant/ha_proxy.sh
      bash /vagrant/cluster_proxy.sh
      sudo reboot
    SHELL
  end   

  config.vm.define "sql1" do |sql1|
    sql1.vm.box = "ubuntu/focal64"
    sql1.vm.network "private_network", type: "static", ip: "192.168.51.111"
    sql1.vm.hostname = "sql1"
    config.vm.synced_folder "setup_files/", "/vagrant"

    sql1.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    sql1.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/*.sh
      bash /vagrant/first.sh
      bash /vagrant/hosts.sh
      bash /vagrant/glusterfs.sh
      bash /vagrant/database.sh
      bash /vagrant/cluster_database.sh
      sudo reboot
    SHELL
  end

  config.vm.define "sql2" do |sql2|
    sql2.vm.box = "ubuntu/focal64"
    sql2.vm.network "private_network", type: "static", ip: "192.168.51.112"
    sql2.vm.hostname = "sql2"
    config.vm.synced_folder "setup_files/", "/vagrant"

    sql2.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    sql2.vm.provision "shell", inline: <<-SHELL
      chmod +x /vagrant/*.sh
      bash /vagrant/first.sh
      bash /vagrant/hosts.sh
      bash /vagrant/glusterfs.sh
      bash /vagrant/database.sh
      bash /vagrant/cluster_database.sh
      sudo reboot
    SHELL
  end

  config.vm.define "client" do |client|
    client.vm.box = "ubuntu/focal64"
    client.vm.network "private_network", type: "static", ip: "172.20.51.10"
    client.vm.hostname = "client"
    config.vm.synced_folder "setup_files/", "/vagrant"

    client.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/ClusterSC"]
    end

    client.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y ubuntu-desktop
      sudo reboot
    SHELL
  end
  
end
