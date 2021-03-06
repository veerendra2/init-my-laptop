#!/bin/bash
# Author: Veerendra Kakumanu
# Description: A fancy script to install necessary packages in Ubuntu

pro_packages=(
  "systemtap" "iotop"
  "blktrace" "sysdig"
  "sysstat" "linux-tools-common"
  "bcc" "bpftrace"
  "ethtool" "nmap"
  "socat" "schroot"
  "debootstrap" "binwalk"
  "binutils"
)

dev_packages=(
  "bridge-utils" "conntrack"
  "python-dev" "python-scapy"
)

general_packages=(
  "filezilla" "ipcalc"
  "wipe" "htop"
  "vlc" "screen"
  "traceroute" "ssh"
  "secure-delete" "makepasswd"
  "pwgen" "tree"
  "macchanger" "unzip"
)

python2_packages=(
  "requests" "frida-tools"
  "beautifulsoup4"
)

python3_packages=(
  "requests" "thefuck"
  "frida-tools" "beautifulsoup4"
  "ansible" "youtube_dl"
  "funmotd"
)

dependency_packages=(
  "apt-transport-https" "ca-certificates"
  "curl" "gnupg-agent"
  "software-properties-common"
  "git" "python-pip"
  "debconf-utils" "python3-pip"
  "python3-setuptools" "python3-dev"
)

declare -A ppa_pkgs=(
  ['atom']="ppa:webupd8team/atom"
  ['wireshark']="ppa:wireshark-dev/stable"
  ['anoise']="ppa:costales/anoise"
)

declare -A custom_scripts_urls=(
  ['httpserver']="https://raw.githubusercontent.com/veerendra2/useless-scripts/master/tools/httpserver.py"
  ['nettools']="https://raw.githubusercontent.com/veerendra2/useless-scripts/master/tools/netTools.py"
  ['ssid_list']="https://raw.githubusercontent.com/veerendra2/useless-scripts/master/tools/ssid_list.py"
  ['pastebin']="https://raw.githubusercontent.com/veerendra2/useless-scripts/master/tools/pastebin.py"
  ['deauth']="https://raw.githubusercontent.com/veerendra2/wifi-deauth-attack/master/deauth.py"
)

declare -A repos=(
  ['my-utils']="https://github.com/veerendra2/my-utils.git"
  ['veerendra2.github.io']="https://github.com/veerendra2/veerendra2.github.io.git"
  ['prometheus-k8s-monitoring']="prometheus-k8s-monitoring"
  ['my-k8s-applications']="https://github.com/veerendra2/my-k8s-applications.git"
  ['dotfiles']="https://github.com/veerendra2/dotfiles"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'
LINE='───────────────────────────────────────────────────────────────────────────'
DOTS='.........................................................'

trap ctrl_c INT
ctrl_c() {
  tput cnorm
  if [[ -z $(jobs -p) ]]; then
    kill $(jobs -p)
    rm pidfile exitcode
  fi
  exit
}

spinner() {
  spin="\\|/-"
  i=0
  tput civis
  while sudo kill -0 $1 2>/dev/null; do
    i=$(((i + 1) % 4))
    printf "\b${spin:$i:1}"
    sleep 0.09
  done
  tput cnorm
}

run_cmd() {
  echo -e "[$(date)] RUNNING $1\n" >> init_my_laptop.log
  { sh -c "$1 >> init_my_laptop.log 2>&1 &"'
    echo $! > pidfile
    wait $!
    echo $? > exitcode
    ' &}
  printf "%s %s " $2 "${DOTS:${#2}}"
  spinner "$(cat pidfile)"
  if [ "$(cat exitcode)" != "0" ]; then
    printf "${RED}\b[FAILED]\n${PLAIN}"
  else
    printf "${GREEN}\b[DONE]\n${PLAIN}"
  fi
}

install_pkgs(){
  echo "Install Packages"
  echo $LINE
  echo "${dependency_packages[*]} ${dev_packages[*]} ${general_packages[*]} ${!ppa_pkgs[@]}" | fmt
  echo $LINE
  # debconfig edits
  echo 'macchanger macchanger/automatically_run boolean false' | sudo debconf-set-selections
  run_cmd "sudo apt-get update" "[*] Updating"
  run_cmd "sudo apt-get upgrade -y" "[*] Running Upgrade"
  run_cmd "sudo apt-get --ignore-missing install ${dependency_packages[*]} -y" "[*] Installing Dependency Packages"
  run_cmd "sudo apt-get --ignore-missing install ${dev_packages[*]} -y" "[*] Installing Dev Packages"
  run_cmd "sudo apt-get --ignore-missing install ${general_packages[*]} -y" "[*] Installing General Packages"
  for i in "${!ppa_pkgs[@]}";
  do
    run_cmd "sudo add-apt-repository ${ppa_pkgs[$i]}" "[*] Adding ${i} PPA"
  done
  run_cmd "sudo apt-get --ignore-missing install ${!ppa_pkgs[@]}" "[*] Installing PPA Packages"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
  run_cmd 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"' "[*] Adding Docker PPA"
  run_cmd "sudo apt-get update" "[*] Updating"
  run_cmd "sudo apt-get install docker-ce docker-ce-cli -y" "[*] Installing Docker"
  echo "** Configuring Wireshark **"
  sudo groupadd wireshark
  sudo usermod -a -G wireshark $USER
  sudo newgrp wireshark &
  sudo chgrp wireshark /usr/bin/dumpcap
  sudo chmod 750 /usr/bin/dumpcap
  sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
  sudo getcap /usr/bin/dumpcap
}

install_graphic_drivers(){
  lspci | grep -i --color 'NVIDIA' > /dev/null 2>&1
  if [ "$?" == "0" ];
  then
    echo "[*] Found NVIDIA Card. Downloading 'graphic_drivers_install.sh' script"
    curl -qO https://raw.githubusercontent.com/veerendra2/my-utils/master/scripts/graphic_drivers_install.sh > /dev/null 2>&1
    run_cmd "bash ./graphic_drivers_install.sh" "Installing Nvidia drivers, CUDA, hashcat and aircrack-ng"
  fi
}

clone_repos() {
  echo "${YELLOW}Clone Repos${PLAIN}"
  echo $LINE
  echo "${!repos[@]}"
  echo $LINE
  mkdir $HOME/projects
  pushd $HOME/projects
  for i in "${!repos[@]}"; do
    run_cmd "git clone ${repos[$i]}" "[*] Cloning $i"
  done
  popd
}

install_scripts() {
  echo "${YELLOW}Download Custom Scripts${PLAIN}"
  echo $LINE
  echo "${!custom_scripts_urls[@]}" | fmt
  echo $LINE
  for i in "${!custom_scripts_urls[@]}"; do
    run_cmd "curl -qO ${custom_scripts_urls[$i]}" "[*] Cloning $i"
  done
}

pip_packages() {
  echo "${YELLOW}Installing Python PIP Packages${PLAIN}"
  for i in "${!python2_packages[@]}";
  do
    run_cmd "sudo pip install ${python2_packages[$i]}" "[*] Installing $i (Python2)"
  done
  for i in "${!python3_packages[@]}";
  do
    run_cmd "sudo pip3 install ${python2_packages[$i]}" "[*] Installing $i (Python3)"
  done

}

extra() {
  echo "${YELLOW}Install Extra Packages${PLAIN}"
  echo $LINE
  echo "${pro_packages[*]} radare2 OnionShare" | fmt
  echo $LINE
  TEMP_DIR=$(mktemp -d)
  pushd $TEMP_DIR
  run_cmd "git clone git clone https://github.com/radareorg/radare2" "[*] Cloning radare2"
  pushd ./radare2
  run_cmd "sys/install.sh" "[*] Build and install radare2"
  popd
  popd

  TEMP_DIR=$(mktemp -d)
  pushd "${TEMP_DIR}"
  run_cmd "git clone https://github.com/micahflee/onionshare.git" "[*] Cloning OnionShare"
  run_cmd "git checkout tags/v2.2" "[*] Checkout tags/v2.2"
  pushd ./onionshare
  run_cmd "pip3 install -r install/requirements.txt" "[*] Installing Dependencies"
  run_cmd "./dev_scripts/onionshare-gui" "[*] Installing OnionShare"
  popd
  popd

  run_cmd "sudo apt-get --ignore-missing install ${pro_packages[*]} -y" "[*] Installing Pro Packages"

# Dns-crypt https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Installation-linux
  pushd /opt
  run_cmd "curl -O https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.36/dnscrypt-proxy-linux_x86_64-2.0.36.tar.gz" "Downloading dnscrypt-proxy 2.0.36"
  sudo tar -xf dnscrypt-proxy-linux_x86_64-2.0.36.tar.gz
  pushd ./linux-x86_64


# Add Bettercap https://www.bettercap.org/installation/

}

# Call functions according to your requirement
install_pkgs
clone_repos
install_scripts
pip_packages
extra
install_graphic_drivers