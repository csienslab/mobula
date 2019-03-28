FROM centos/systemd

RUN curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo && \
    yum install -y epel-release && \
    yum install -y openssh-server iproute wireguard-tools && \
    systemctl enable sshd.service
COPY ssh_key.pub /root/.ssh/authorized_keys
RUN chmod 644 /root/.ssh/authorized_keys

CMD ["/usr/sbin/init"]
