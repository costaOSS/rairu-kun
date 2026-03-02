FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt install -y \
    openssh-server \
    wget \
    unzip \
    curl \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok v3
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /ngrok.zip \
    && unzip /ngrok.zip -d / \
    && chmod +x /ngrok \
    && rm /ngrok.zip

# Configure SSH
RUN mkdir -p /run/sshd \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config \
    && echo root:craxid | chpasswd

# Create startup script
RUN cat << 'EOF' > /start.sh
#!/bin/bash

if [ -z "$NGROK_TOKEN" ]; then
  echo "ERROR: NGROK_TOKEN not set"
  exit 1
fi

echo "Starting ngrok..."
/ngrok config add-authtoken $NGROK_TOKEN
/ngrok tcp 22 --region=${REGION:-ap} &

sleep 5

echo "Fetching tunnel info..."
curl -s http://localhost:4040/api/tunnels | python3 - <<PY
import sys, json
try:
    data = json.load(sys.stdin)
    url = data["tunnels"][0]["public_url"][6:]
    print("\nSSH INFO:")
    print("ssh root@" + url.replace(":", " -p "))
    print("ROOT PASSWORD: craxid\n")
except Exception:
    print("Could not fetch tunnel info.")
PY

echo "Starting SSH server..."
/usr/sbin/sshd -D
EOF

RUN chmod +x /start.sh

EXPOSE 22

CMD ["/start.sh"]