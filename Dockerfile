FROM alpine:latest

# Install packages
RUN apk update && apk add --update --no-cache \
    git \
    bash \
    curl \
    openssh \
    python3 \
    py3-pip \
    py-cryptography \
    wget \
    jq \
    aws-cli
 
RUN apk --no-cache add --virtual builds-deps build-base python3

# Install Akamai CLI
RUN wget https://github.com/akamai/cli/releases/download/v1.5.3/akamai-v1.5.3-linuxamd64
RUN chmod +x akamai-v1.5.3-linuxamd64
RUN mv akamai-v1.5.3-linuxamd64 /usr/local/bin/akamai
RUN akamai install firewall

COPY ./.edgerc /root/.edgerc
COPY ./credentials /root/.aws/credentials
COPY ./config /root/.akamai-cli/config
COPY ./script.sh /root/script.sh
RUN chmod 755 /root/script.sh
ENTRYPOINT ["/root/script.sh"]

WORKDIR /root
