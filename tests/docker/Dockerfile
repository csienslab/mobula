FROM centos/systemd

RUN yum install -y https://resources.ovirt.org/pub/yum-repo/ovirt-release43.rpm && yum update -y
RUN yum install -y openssh-server iproute iptables && systemctl enable sshd.service
COPY ssh_key.pub /root/.ssh/authorized_keys
RUN chmod 644 /root/.ssh/authorized_keys

CMD ["/usr/sbin/init"]
