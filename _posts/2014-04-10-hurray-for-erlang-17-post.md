---
layout: post
title: "Hurray for Erlang 17.0!"
description: "Erlang 17.0 is out, and this is a pretty big deal."
modified: 2014-04-10
tags: [erlang]
---

Pretty _excited_ about yesterday’s release of Erlang/OTP 17.0.
You can read more about why this release is important from Joe Armstrong’s
February 1 post: “[Big Changes to Erlang](http://joearms.github.io/2014/02/01/big-changes-to-erlang.html)“.
The release of Erlang/OTP 17 is important to the v1.0 release of [Elixir](http://elixir-lang.org/)
as well: “[Milestones for 1.0](https://groups.google.com/forum/#!topic/elixir-lang-core/ko1_6zpP5O4)“.

##### Getting it:
The good folks at [Erlang Solutions](https://twitter.com/ErlangSolutions)
publish and maintain a library of [prebuilt Erlang packages for many platforms here](https://www.erlang-solutions.com/downloads/download-erlang-otp).

If you are on Linux or Mac many folks use a handy tool named Kerl to build and switch
between multiple releases of Erlang. Get started here:
[https://github.com/spawngrid/kerl](https://github.com/spawngrid/kerl).

If you are on Windows you’ve got it easy. Go to the Erlang.org’s download page
([here](http://www.erlang.org/download.html)) and download the
[32-bit](http://www.erlang.org/download/otp_win32_17.0.exe) or 
[64-bit](http://www.erlang.org/download/otp_win64_17.0.exe) OTP 17.0
Windows Binary File. It runs as a standard Windows installer, and it works great.
All dependencies are pulled in for you including wxWidgets which is used with the
graphical tools [Debugger](http://www.erlang.org/doc/apps/debugger/debugger_chapter.html)
and [Observer](http://www.erlang.org/doc/man/observer.html#start-0).

<img width="600" src="/images/erlang17-windows81.png"/>

Finally, if you are on Ubuntu and want to see how to build from source (and get
the required dependencies) I have a Gist that will help you
“[Build Erlang 17.0 on a fresh Ubuntu box (tested on 12.04)](https://gist.github.com/bryanhunter/10380945)”

{% highlight bash %}
#!/bin/bash
# Pull this file down, make it executable and run it with sudo
# wget https://gist.githubusercontent.com/bryanhunter/10380945/raw/build-erlang-17.0.sh
# chmod u+x build-erlang-17.0.sh
# sudo ./build-erlang-17.0.sh

if [ $(id -u) != "0" ]; then
echo "You must be the superuser to run this script" >&2
exit 1
fi
apt-get update

# Install the build tools (dpkg-dev g++ gcc libc6-dev make)
apt-get -y install build-essential

# automatic configure script builder (debianutils m4 perl)
apt-get -y install autoconf

# Needed for HiPE (native code) support, but already installed by autoconf
# apt-get -y install m4

# Needed for terminal handling (libc-dev libncurses5 libtinfo-dev libtinfo5 ncurses-bin)
apt-get -y install libncurses5-dev

# For building with wxWidgets
apt-get -y install libwxgtk2.8-dev libgl1-mesa-dev libglu1-mesa-dev libpng3

# For building ssl (libssh-4 libssl-dev zlib1g-dev)
apt-get -y install libssh-dev

# ODBC support (libltdl3-dev odbcinst1debian2 unixodbc)
apt-get -y install unixodbc-dev
mkdir -p ~/code/erlang
cd ~/code/erlang

if [ -e otp_src_17.0.tar.gz ]; then
echo "Good! 'otp_src_17.0.tar.gz' already exists. Skipping download."
else
wget http://www.erlang.org/download/otp_src_17.0.tar.gz
fi
tar -xvzf otp_src_17.0.tar.gz
chmod -R 777 otp_src_17.0
cd otp_src_17.0
./configure
make
make install
exit 0
{% endhighlight %}
