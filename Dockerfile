FROM ubuntu:14.04

# Install dev environment
RUN apt-get update && apt-get install -y \
  ack-grep \
  autoconf \
  bash-completion \
  bindfs \
  build-essential \
  cmake \
  cmake \
  curl \
  diffstat \
  g++ \
  gcovr \
  git \
  lcov \
  libboost-date-time-dev \
  libboost-dev \
  libboost-filesystem-dev \
  libboost-regex-dev \
  libboost-signals-dev \
  libboost-test-dev \
  libboost-thread-dev \
  libevent-dev \
  libprotobuf-dev \
  libssl-dev \
  libtool \
  libyaml-cpp-dev \
  libzmq3-dev \
  pkg-config \
  pkg-config \
  protobuf-compiler \
  python \
  python-pip \
  screen \
  strace \
  tcpdump \
  unzip \
  vim \
  wget

# Install the julia and the julia protobuf plugin
RUN wget -O - "https://julialang.s3.amazonaws.com/bin/linux/x64/0.5/julia-0.5.0-linux-x86_64.tar.gz" | tar zxvf - -C /opt
RUN ln -s /opt/julia-3c9d75391c/bin/julia /usr/bin/julia
RUN julia -e 'Pkg.update(); Pkg.add("ProtoBuf")'

# Setup home environment
RUN useradd brad
RUN gpasswd -a brad fuse
RUN mkdir /home/brad && chown -R brad: /home/brad

# Copy the .julia from /root to /home/brad
RUN cp -R /root/.julia /home/brad/.julia

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /var/shared/
RUN touch /var/shared/placeholder
RUN chown -R brad:brad /var/shared
VOLUME /var/shared

ENV PATH $PATH:/home/brad/.julia/v0.5/ProtoBuf/plugin

WORKDIR /home/brad
ENV HOME /home/brad

# Add the git bash prompt
RUN git clone https://github.com/arialdomartini/oh-my-git.git /home/brad/.oh-my-git
RUN echo '\
source /home/brad/.oh-my-git/prompt.sh\n\
' >> /home/brad/.bashrc

# Add python virtualenvwrapper
RUN pip install virtualenvwrapper
RUN ln -s /usr/local/bin/virtualenvwrapper.sh /usr/bin/virtualenvwrapper.sh
RUN bash -c "source /usr/local/bin/virtualenvwrapper.sh"

RUN echo '\
export WORKON_HOME=$HOME/.virtualenvs\n\
export PROJECT_HOME=$HOME/devel\n\
export ARE_TOP=$HOME/devel\n\
source /usr/local/bin/virtualenvwrapper.sh\n\
' >> /home/brad/.bashrc

# Link in shared parts of the home directory
RUN ln -s /var/shared/.vimrc /home/brad/.vimrc
RUN ln -s /var/shared/.vim /home/brad/.vim
RUN ln -s /var/shared/.gitconfig /home/brad/.gitconfig
RUN ln -s /var/shared/.ssh /home/brad/.ssh
RUN ln -s /var/shared/.bash_history /home/brad/.bash_history
RUN ln -s /var/shared/devel /home/brad/devel

# Pretty bash prompt
RUN echo 'export PS1="\[\033[36m\][\[\033[m\]\[\033[33m\]\u@\h\[\033[m\] \[\033[32m\]\W\[\033[m\]\[\033[36m\]]\[\033[m\] $ "' >> /home/brad/.bashrc

# Add in bash completion
RUN echo '\
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then\n\
    . /etc/bash_completion\n\
fi\n\
' >> /home/brad/.bashrc

RUN echo user_allow_other >> /etc/fuse.conf

RUN chown -R brad: /home/brad
USER brad

ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
