FROM ubuntu:focal AS base
WORKDIR /usr/local/bin
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common curl git build-essential sudo && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y curl git ansible build-essential && \
    apt-get clean autoclean && \
    apt-get autoremove --yes

FROM base AS aleph
ARG TAGS
RUN addgroup --gid 1000 aleph
RUN adduser --gecos aleph --uid 1000 --gid 1000 --disabled-password aleph
RUN echo "aleph ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER aleph
WORKDIR /home/aleph
COPY . .
RUN ansible-playbook $TAGS local.yml

FROM aleph
CMD ["bash"]

