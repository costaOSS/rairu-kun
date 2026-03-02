FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    openssh-server sudo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

# Create user instead of root login
RUN useradd -m vpsuser \
    && echo 'vpsuser:strongpassword' | chpasswd \
    && adduser vpsuser sudo

RUN echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]