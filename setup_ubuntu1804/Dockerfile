FROM ubuntu:20.04

# Required for non-interactive installation of gnome-shell
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && \
    apt-get install -y \
    python3-pip software-properties-common sudo openssh-server iptables && \
    pip3 install ansible

#COPY . /root/playbook
WORKDIR /root/playbook

CMD ansible-playbook playbook.yml -i local.inventory -u root