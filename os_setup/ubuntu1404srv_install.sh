#!/bin/bash

cuser=$(whoami)
if [ ${cuser} == "root" ]; then
    echo "Should not run as root. Exit"
    exit 1
fi
install_tmpdir=/home/$cuser/install

string_replace() {
    echo "${1/$2/$3}"
}


check() {
    [ -e "/usr/bin/lsb_release" ] && [ $(lsb_release -i|awk '{print $3}') == "Ubuntu" ] && return

    echo "wrong os type"
    exit 1
}

check_param() {
    read -r -p "Use 'sudo -E' to replace 'sudo'? [y/N] " response
    case $response in
        [yY][eE][sS]|[yY])
            sudo_cmd='sudo -E'
            ;;
        *)
            sudo_cmd='sudo'
            ;;
    esac
}


basic() {
    ${sudo_cmd} apt-get update > /dev/null
    ${sudo_cmd} apt-get install -y build-essential libncurses5-dev git vim bison > /dev/null
    mkdir -p $install_tmpdir
}

install_docker() {
    [ -e /usr/lib/apt/methods/https ] || {
        apt-get update
        apt-get install -y apt-transport-https > /dev/null
    }
    ${sudo_cmd} apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9

    ${sudo_cmd} sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
    ${sudo_cmd} apt-get update > /dev/null
    ${sudo_cmd} apt-get install -y lxc-docker > /dev/null
}


other_tools() {
    # monitor tools
    # iftop http://www.ex-parrot.com/pdw/iftop/
    ${sudo_cmd} apt-get install -y iftop > /dev/null
    # htop http://hisham.hm/htop/
    ${sudo_cmd} apt-get install -y htop > /dev/null

    # others
    # ack
    ${sudo_cmd} apt-get install -y ack-grep > /dev/null
    ${sudo_cmd} dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
    # tree
    ${sudo_cmd} apt-get install -y tree > /dev/null
    # netcat or socat
    ${sudo_cmd} apt-get install -y socat > /dev/null
    # mercurial
    ${sudo_cmd} apt-get install -y mercurial > /dev/null
    # chkconfig
    ${sudo_cmd} apt-get install -y chkconfig > /dev/null

    # docker
    install_docker

    # install docker enter tools
    cd $install_tmpdir
    wget https://www.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz
    tar xvzf util-linux-2.24.tar.gz > /dev/null
    cd util-linux-2.24
    ./configure --without-ncurses > /dev/null && make nsenter > /dev/null
    ${sudo_cmd} cp nsenter /usr/local/bin

    wget -P ~ https://github.com/yeasy/docker_practice/raw/master/_local/.bashrc_docker;
    echo "[ -f ~/.bashrc_docker ] && . ~/.bashrc_docker" >> ~/.zshrc
}


install_tools() {
    # simple config tmux
    touch ~/.tmux.conf
    echo -e 'setw -g mode-keys vi\n' >> ~/.tmux.conf

    cat >> ~/.tmux.conf <<EOF
bind k selectp -U # 选择上窗格
bind j selectp -D # 选择下窗格
bind h selectp -L # 选择左窗格
bind l selectp -R # 选择右窗格
bind-key J resize-pane -D 10
bind-key K resize-pane -U 10
bind-key H resize-pane -L 10
bind-key L resize-pane -R 10
EOF


    # install zsh & oh-my-zsh
    cd $install_tmpdir
    wget http://softlayer-dal.dl.sourceforge.net/project/zsh/zsh/5.0.7/zsh-5.0.7.tar.gz
    tar xvzf zsh-5.0.7.tar.gz > /dev/null
    cd zsh-5.0.7
    ./configure > /dev/null && make > /dev/null
    ${sudo_cmd} make install

    ${sudo_cmd} ln -s /usr/local/bin/zsh /usr/bin/zsh
    echo "/usr/bin/zsh" | ${sudo_cmd} tee -a /etc/shells
    chsh -s /usr/bin/zsh

    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    wget https://raw.githubusercontent.com/amyangfei/y-config/master/zsh/zmine_from_ys.zsh-theme -P ~/.oh-my-zsh/themes
    sed -i 's/robbyrussell/zmine_from_ys/' ~/.zshrc

    cd $install_tmpdir
    git clone https://github.com/joelthelion/autojump.git
    cd autojump
    ./install.py
    j_cfg='[[ -s home_path/.autojump/etc/profile.d/autojump.sh ]] && source home_path/.autojump/etc/profile.d/autojump.sh'
    j_cfg=$(string_replace "$j_cfg" "home_path" "/home/$cuser")
    j_cfg=$(string_replace "$j_cfg" "home_path" "/home/$cuser")
    echo $j_cfg >> ~/.zshrc

    # mosh
    # ${sudo_cmd} apt-get install -y mosh

    # other_tools
    other_tools $*
}


install_program_lang() {
    # golang
    # use gvm
    zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    source "/home/$cuser/.gvm/scripts/gvm"
    GOVERSION="1.3.3"
    gvm install go${GOVERSION}
    gvm use ${GOVERSION} --default

    # python related
    cd $install_tmpdir
    wget https://bootstrap.pypa.io/get-pip.py
    ${sudo_cmd} python get-pip.py
    ${sudo_cmd} pip install virtualenv

    # TODO: vim config
}


init() {
    echo "starting setup ubuntu environment"
    basic $*
    install_tools $*
    install_program_lang $*
}

check $*
check_param $*
init $*

