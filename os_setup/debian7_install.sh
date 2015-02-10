#!/bin/bash

cuser=$(whoami)
install_tmpdir=/home/$cuser/install

string_replace() {
    echo "${1/$2/$3}"
}


check() {
    if [ $cuser == "root" ];then
        echo "should not run as root"
        exit 1
    fi

    [ -e "/usr/bin/lsb_release" ] && [ $(lsb_release -i|awk '{print $3}') == "Debian" ] && return

    echo "wrong os type"
    exit 1
}


update_kernel() {
    echo 'deb http://http.debian.net/debian wheezy-backports main' | sudo tee --append /etc/apt/sources.list > /dev/null
    sudo apt-get update
    sudo apt-get install -t wheezy-backports linux-image-amd64
}


basic() {
    # update kernel if needed (for example if we use docker)
    # update_kernel $*

    sudo apt-get update
    sudo apt-get install -y build-essential libncurses5-dev git vim bison
    mkdir -p $install_tmpdir
}


other_tools() {
    # monitor tools
    # iftop http://www.ex-parrot.com/pdw/iftop/
    sudo apt-get install -y iftop
    # htop http://hisham.hm/htop/
    sudo apt-get install -y htop

    # others
    # ack
    sudo apt-get install -y ack-grep
    sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
    # tree
    sudo apt-get install -y tree
    # netcat or socat
    sudo apt-get install -y socat
    # mercurial
    sudo apt-get install -y mercurial
    # chkconfig
    sudo apt-get install -y chkconfig

    # docker attention: Docker requires Kernel 3.8+
    # https://docs.docker.com/installation/debian/
    curl -sSL https://get.docker.com/ | sh

    # install docker enter tools
    cd $install_tmpdir
    wget https://www.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz
    tar xvzf util-linux-2.24.tar.gz
    cd util-linux-2.24
    ./configure --without-ncurses && make nsenter
    sudo cp nsenter /usr/local/bin

    wget -P ~ https://github.com/yeasy/docker_practice/raw/master/_local/.bashrc_docker;
    echo "[ -f ~/.bashrc_docker ] && . ~/.bashrc_docker" >> ~/.zshrc; source ~/.zshrc
}


install_tools() {
    # tmux
    cd $install_tmpdir
    wget http://dailyuse.qiniudn.com/libevent-2.0.21-stable.tar.gz
    tar xvzf libevent-2.0.21-stable.tar.gz
    cd libevent-2.0.21-stable
    ./configure && make
    sudo make install

    cd $install_tmpdir
    wget http://downloads.sourceforge.net/project/tmux/tmux/tmux-1.8/tmux-1.8.tar.gz
    tar xvzf tmux-1.8.tar.gz
    cd tmux-1.8
    ./configure && make
    sudo make install

    touch ~/.tmux.conf
    echo -e 'setw -g mode-keys vi\n' >> ~/.tmux.conf
    mov=$(cat <<EOF
bind k selectp -U # 选择上窗格\n
bind j selectp -D # 选择下窗格\n
bind h selectp -L # 选择左窗格\n
bind l selectp -R # 选择右窗格\n\n
bind-key J resize-pane -D 10\n
bind-key K resize-pane -U 10\n
bind-key H resize-pane -L 10\n
bind-key L resize-pane -R 10
EOF
)
    echo -e $mov >> ~/.tmux.conf


    # install zsh & oh-my-zsh
    cd $install_tmpdir
    wget http://softlayer-dal.dl.sourceforge.net/project/zsh/zsh/5.0.7/zsh-5.0.7.tar.gz
    tar xvzf zsh-5.0.7.tar.gz
    cd zsh-5.0.7
    ./configure && make
    sudo make install

    sudo ln -s /usr/local/bin/zsh /usr/bin/zsh
    echo "/usr/bin/zsh" | sudo tee -a /etc/shells
    chsh -s /usr/bin/zsh

    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

    cd $install_tmpdir
    git clone https://github.com/joelthelion/autojump.git
    cd autojump
    ./install.py
    j_cfg='[[ -s home_path/.autojump/etc/profile.d/autojump.sh ]] && source home_path/.autojump/etc/profile.d/autojump.sh'
    j_cfg=$(string_replace "$j_cfg" "home_path" "/home/$cuser")
    j_cfg=$(string_replace "$j_cfg" "home_path" "/home/$cuser")
    echo $j_cfg >> ~/.zshrc

    # mosh
    sudo apt-get install -y mosh

    # other_tools
    other_tools $*
}


install_golang() {
    # golang
    # use gvm
    zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    source "/home/$cuser/.gvm/scripts/gvm"
    GOVERSION="1.3.3"
    gvm install go${GOVERSION}
    gvm use ${GOVERSION} --default
}

install_python() {
    sudo apt-get install -y python-dev
    cd $install_tmpdir
    wget https://bootstrap.pypa.io/get-pip.py
    sudo python get-pip.py
    sudo pip install virtualenv
}


install_program_lang() {
    install_golang $*
    install_python $*
}

init() {
    echo "starting setup debian environment"
    basic $*
    install_tools $*
    install_program_lang $*
}

check $*
init $*

