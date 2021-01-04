# This is forked image based on the original project:
# https://github.com/instantlinux/docker-tools/blob/master/images/samba-dc
# License: https://github.com/instantlinux/docker-tools/blob/master/LICENSE.txt
# BUILD COMMAND
# docker build --no-cache --rm -t vpms3.azurecr.io/auth/activedirectory-demo .
# 
# RUN JUST THIS CONTAINER FROM ROOT (folder with .sln file):
# docker build --no-cache --rm -f Demo/Misc/ActiveDirectory/Dockerfile -t vpms3.azurecr.io/auth/activedirectory-demo:latest .
#
# RUN COMMAND
# docker run --name activedirectory_authservice --rm -d -p 389:389 -p 636:636 --cap-add SYS_ADMIN vpms3.azurecr.io/auth/activedirectory-demo:latest

FROM alpine
ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="Rich Braun <docker@instantlinux.net>"
LABEL maintainer="Alex Soh <alex.soh@bertelsmann.de>"
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="Samba DC - Alpine" \
    org.label-schema.description="Provides a Docker image for Samba 4 DC on Alpine Linux." \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=samba-dc \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV ADMIN_PASSWORD="Password!234" \
    ALLOW_DNS_UPDATES=secure \
    BIND_INTERFACES_ONLY=yes \
    DOMAIN_ACTION=provision \
    DOMAIN_LOGONS=yes \
    DOMAIN_MASTER=no \
    INTERFACES="lo eth0" \
    LOG_LEVEL=1 \
    MODEL=standard \
    NETBIOS_NAME= \
    REALM=ad.example.com \
    SERVER_STRING="Samba Domain Controller" \
    TZ=UTC \
    WINBIND_USE_DEFAULT_DOMAIN=yes \
    WORKGROUP=AD

ARG SAMBA_VERSION=4.12.9-r0

COPY *.conf.j2 /root/
COPY entrypoint.sh /
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk --no-cache upgrade && \
    apk add --update --no-cache vim krb5 ldb-tools samba-dc tdb \
    bind bind-libs bind-tools libcrypto1.1 libxml2 tzdata tini
RUN chmod 0755 entrypoint.sh

VOLUME /etc/samba /var/lib/samba
EXPOSE 53 53/udp 88 88/udp 135 137-138/udp 139 389 389/udp 445 464 464/udp 636 953 1024-5000 3268-3269 49152-65535

ENTRYPOINT ["/sbin/tini", "-v", "/entrypoint.sh"]
