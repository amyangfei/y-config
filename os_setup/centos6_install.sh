#!/bin/bash

cuser=$(whoami)
insdir=/home/$cuser/install

string_replace() {
    echo "${1/$2/$3}"
}

install_py27() {
    mkdir -p $insdir
    cd $insdir
    wget http://www.python.org/ftp/python/2.7.8/Python-2.7.8.tgz
    tar xvzf Python-2.7.8.tgz
    cd Python-2.7.8 && ./configure --prefix=/usr/local
    sudo make altinstall
}

install_pbf() {
    cd $insdir
    wget https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz
    tar xvzf protobuf-2.5.0.tar.gz
    cd protobuf-2.5.0
    ./configure && make
    sudo make install
}

install_tools() {
    cd $insdir
    wget http://linux.mirrors.es.net/fedora-epel/6/x86_64/epel-release-6-8.noarch.rpm
    sudo rpm -Uvh epel-release-6*.rpm

    # monitor tools
    # iftop http://www.ex-parrot.com/pdw/iftop/
    sudo yum install -y iftop
    # htop http://hisham.hm/htop/
    sudo yum install -y htop

    # others
    # ack
    sudo yum install -y ack
    # tree
    sudo yum install -y tree
    # netcat or socat
    sudo yum install -y nc
    sudo yum install -y socat
    # mtr
    sudo yum install -y mtr
    sudo ln -s /usr/sbin/mtr /usr/local/bin/mtr
    # mercurial
    cd $insdir
    wget http://pkgs.repoforge.org/mercurial/mercurial-2.2.2-1.el6.rfx.x86_64.rpm
    sudo rpm -Uvh mercurial-2.2.2-1.el6.rfx.x86_64.rpm
}

install_program_lang() {
    # golang
    # use gvm
    zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    source "/home/${cuser}/.gvm/scripts/gvm"
    gvm install go1.3.3
    gvm use 1.3.3 --default

}

init() {

    #安装所有更新软件
    sudo yum update


    # basic develop tools
    sudo yum install -y gcc
    sudo yum install -y gcc-c++
    sudo yum install -y openssl-devel ncurses-devel zlib-devel bzip2-devel xz-libs wget bison


    # install python 2.7
    install_py27 $*


    # install easy_install and pip
    cd $insdir
    wget --no-check-certificate https://pypi.python.org/packages/source/s/setuptools/setuptools-1.4.2.tar.gz
    tar xvzf setuptools-1.4.2.tar.gz
    cd setuptools-1.4.2
    sudo /usr/local/bin/python2.7 setup.py install
    curl https://raw.githubusercontent.com/pypa/pip/master/contrib/get-pip.py | sudo /usr/local/bin/python2.7 -


    # install shadowsocks and configure it
    mkdir -p /home/$cuser/work/code/virtualenv
    cd /home/$cuser/work/code/virtualenv
    virtualenv --no-site-packages ss_venv

    mkdir -p /home/$cuser/script
    cd /home/$cuser/script
    touch ss_venv.sh
    cnt='#!/bin/bash\n\nvenv_path=/home/current_user/work/code/virtualenv/ss_venv\ncd $venv_path\n. bin/activate\ncd /home/current_user/script/'
    cnt=$(string_replace "$cnt" "current_user" "$cuser")
    cnt=$(string_replace "$cnt" "current_user" "$cuser")
    echo -e $cnt > ss_venv.sh
    chmod a+x ss_venv.sh
    . ./ss_venv.sh
    pip install shadowsocks

    sudo yum install -y m2crypto
    sudo yum install -y swig
    cd $insdir
    wget http://pypi.python.org/packages/source/M/M2Crypto/M2Crypto-0.21.1.tar.gz --no-check-certificate
    tar -zxvf M2Crypto-0.21.1.tar.gz
    cd M2Crypto-0.21.1
    python setup.py install
    sed -i "s/self.swig_opts.append('-includeall')/self.swig_opts.append('-includeall')\n\tself.swig_opts.append('-cpperraswarn')/" setup.py
    python setup.py install
    cd /home/$cuser/script
    mkdir log
    ifconfig|grep inet\ addr|tail -1|awk -F'[: ]+' '{print $4}'|xargs -I {} echo -e '{\n    "server":"{}",\n    "server_port":xxxx,\n    "local_port":xxxx,\n    "password":"xxxx",\n    "timeout":600,\n    "method":"bf-cfb"\n}' >> config.json

    cd $insdir
    wget http://dailyuse.qiniudn.com/libevent-2.0.21-stable.tar.gz
    tar xvzf libevent-2.0.21-stable.tar.gz
    cd libevent-2.0.21-stable
    ./configure && make
    sudo make install
    pip install gevent

    # TODO: configure shadowsocks service
    cd /home/${cuser}/script
    nohup ssserver >> log/ssserver.log 2>&1 &


    # install tmux and basic configuration
    sudo ln -s /usr/local/lib/libevent.so /usr/lib64/libevent.so
    sudo ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib64/libevent-2.0.so.5
    cd $insdir
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
EOF
)
    echo -e $mov >> ~/.tmux.conf


    # install oh-my-zsh
    cd $insdir
    wget http://softlayer-dal.dl.sourceforge.net/project/zsh/zsh/5.0.4/zsh-5.0.4.tar.gz
    tar xvzf zsh-5.0.4.tar.gz
    cd zsh-5.0.4
    ./configure && make
    sudo make install

    sudo yum install -y git
    cd $insdir
    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

    sudo ln -s /usr/local/bin/zsh /usr/bin/zsh
    echo "/usr/bin/zsh" | sudo tee -a /etc/shells
    chsh -s /usr/bin/zsh


    ###### other ######
    # mosh
    cd $insdir
    #wget http://ftp.gnu.org/gnu/glibc/glibc-2.14.tar.gz
    #tar xvzf glibc-2.14.tar.gz
    #cd glibc-2.14
    #mkdir build
    #cd build
    #../configure --prefix=/opt/glibc-2.14
    #make -j4
    #sudo make install

    # install protocol buf
    install_pbf $*

    cd $insdir
    wget --no-check-certificate http://mosh.mit.edu/mosh-1.2.4.tar.gz
    tar xvzf mosh-1.2.4.tar.gz
    cd mosh-1.2.4
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
    ./configure && make
    sudo make install
    sudo ln -s /usr/local/lib/libprotobuf.so.8 /usr/lib64/libprotobuf.so.8
    mosh-server new -s -c 256 -l LANG=en_US.UTF-8 -l LC_CTYPE= -l LC_ALL=en_US.UTF-8

    install_tools $*
}

init $*
