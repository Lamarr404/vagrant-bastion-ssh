#!/bin/bash

function BASTION {

cat <<EOF > "$BASTION_VAGRANTFILE"
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.hostname = "$host_bastion"
  config.vm.provider "vmware_workstation" do |vmware|

  config.vm.network "public_network", ip: "$ip_wan"
  config.vm.network "private_network", ip: "$ip"

  config.vm.provision "shell" do |s|
  ssh_prv_key = ""
  ssh_pub_key = ""
  if File.file?("/home/lucas/.ssh/id_rsa")
    ssh_prv_key = File.read("/home/lucas/.ssh/id_rsa")
    ssh_pub_key = File.readlines("/home/lucas/.ssh/id_rsa.pub").first.strip
  else
    puts "No SSH key found. You will need to remedy this before pushing to the repository."
  end
  s.inline = <<-SHELL
    if grep -sq "/home/lucas/.ssh/id_rsa.pub" /home/vagrant/.ssh/authorized_keys; then
      echo "SSH keys already provisioned."
      exit 0;
    fi
    echo "SSH key provisioning."
    mkdir -p /home/vagrant/.ssh/
    touch /home/vagrant/.ssh/authorized_keys
    echo /home/lucas/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
    echo /home/lucas/.ssh/id_rsa.pub > /home/vagrant/.ssh/id_rsa.pub
    chmod 644 /home/vagrant/.ssh/id_rsa.pub
    echo "/home/lucas/.ssh/id_rsa" > /home/vagrant/.ssh/id_rsa
    chmod 600 /home/vagrant/.ssh/id_rsa
    chown -R vagrant:vagrant /home/vagrant
    sed -i "3i\ "$ip_wan"   "$host_bastion"\n" /etc/hosts
    sed -i "4i\ "$ip"     "$host_bastion"\n" /etc/hosts
    sed -i "5i\ "$ip_client1"     "$host_client1"\n" /etc/hosts
    sed -i "6i\ "$ip_client2"     "$host_client2"\n" /etc/hosts
    exit 0
  SHELL
end

end
end
EOF

}

function CLIENT1 {
cat <<EOF > "$CLIENT1_VAGRANTFILE"
Vagrant.configure("2") do |config|
config.vm.box = "hashicorp/bionic64"
config.vm.hostname = "$host_client1"
config.vm.provider "vmware_workstation" do |vmware|

config.vm.network "private_network", ip: "$ip_client1"

end
end
EOF

}

function CLIENT2 {
cat <<EOF > "$CLIENT2_VAGRANTFILE"
Vagrant.configure("2") do |config|
config.vm.box = "hashicorp/bionic64"
config.vm.hostname = "$host_client2"
config.vm.provider "vmware_workstation" do |vmware|

config.vm.network "private_network", ip: "$ip_client2"

end
end
EOF
}

function first_ssh {
  expect <<-END
  spawn ssh-copy-id vagrant@$ip_wan
  expect {
      "continue" { send "yes\n"; exp_continue }
      "password" { send "vagrant\n"; exp_continue }
   }
END
}

function scd_ssh {
  expect <<-END
  spawn ssh -J vagrant@$ip_wan vagrant@$ip_client1 echo $HOME/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 700 .ssh && chmod 600 ~/.ssh/authorized_keys
  expect {
      "continue" { send "yes\n"; exp_continue }
      "password" { send "vagrant\n"; exp_continue }
}
END
}

function trd_ssh {
  expect <<-END
  spawn ssh -J vagrant@$ip_wan vagrant@$ip_client2 echo $HOME/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 700 .ssh && chmod 600 ~/.ssh/authorized_keys
  expect {
      "continue" { send "yes\n"; exp_continue }
      "password" { send "vagrant\n"; exp_continue }
}
END
}

#       "continue" { send "yes\n"; exp_continue }

BASTION_PATH=$HOME/Documents/Bastion

MACHINE_BASTION_PATH=$HOME/Documents/Bastion/bastion

MACHINE_CLIENT1_PATH=$HOME/Documents/Bastion/client1

MACHINE_CLIENT2_PATH=$HOME/Documents/Bastion/client2

BASTION_VAGRANTFILE=$HOME/Documents/Bastion/bastion/Vagrantfile

CLIENT1_VAGRANTFILE=$HOME/Documents/Bastion/client1/Vagrantfile

CLIENT2_VAGRANTFILE=$HOME/Documents/Bastion/client2/Vagrantfile

bastp_ob="dmFncmFudA=="
bastp_obdef=`echo "$bastp_ob" | base64 -d`
MYKEYVAR="echo `cat ~/.ssh/id_rsa.pub`"


mkdir -p "$BASTION_PATH"
mkdir -p "$MACHINE_BASTION_PATH"
mkdir -p "$MACHINE_CLIENT1_PATH"
mkdir -p "$MACHINE_CLIENT2_PATH"

touch "$BASTION_VAGRANTFILE"
touch "$CLIENT1_VAGRANTFILE"
touch "$CLIENT2_VAGRANTFILE"

  echo "Config Bastion:\n"
  echo ""
  echo ""
  read -p "Entrez l'IP de votre interface privé bastion: " ip
  read -p "Entrez l'IP du WAN: " ip_wan
  read -p "Entrez le hostname du bastion: " host_bastion

  BASTION &&


  echo "Config Client 1"
  echo ""
  echo ""
  read -p "Entrez le hostname du client1: " host_client1
  read -p "Entrez l'IP de votre interface privé bastion: " ip_client1
  CLIENT1 &&


  echo "Config Client 2"
  echo ""
  echo ""
  read -p "Entrez le hostname du client2: " host_client2
  read -p "Entrez l'IP de votre interface privé bastion: " ip_client2
  CLIENT2 &&


  cd "$MACHINE_BASTION_PATH" && vagrant up && cd "$MACHINE_CLIENT1_PATH" && vagrant up && cd "$MACHINE_CLIENT2_PATH" && vagrant up

  first_ssh &&

  scd_ssh &&

  trd_ssh
