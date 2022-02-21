FROM neomediatech/dcc AS builder

FROM neomediatech/ubuntu-base:20.04

ENV VERSION=3.4 \
    SERVICE=spamassassin

LABEL maintainer="docker-dario@neomediatech.it" \ 
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-type=Git \
      org.label-schema.vcs-url=https://github.com/Neomediatech/${SERVICE} \
      org.label-schema.maintainer=Neomediatech

ENV CRON_HOUR=1 CRON_MINUTE=30 \
    USERNAME=debian-spamd \
    EXTRA_OPTIONS=--nouser-config \
    PYZOR_SITE=public.pyzor.org:24441 \
    USER_UID=1000 \
    USER_GID=1000

ARG SPAMD_VERSION=3.4.6-1
ARG SPAMD_UID=2022

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates libmail-dkim-perl libnet-ident-perl pyzor razor gpg gpg-agent \
        procps spamassassin libmail-spf-perl && \
    usermod --uid $SPAMD_UID $USERNAME && \
    chsh -s /bin/sh $USERNAME && \
    mv /etc/mail/spamassassin/local.cf /etc/mail/spamassassin/local.cf-dist && \
    sed -i 's/^logfile = .*$/logfile = \/dev\/stderr/g' \
     /etc/razor/razor-agent.conf && \
    sed -i '/^#\s*loadplugin .\+::DCC/s/^#\s*//g' /etc/spamassassin/v310.pre && \
    groupadd -g "$USER_GID" user && \
    useradd -d /home/user -m -g user -u "$USER_UID" user && \
    apt-get clean && rm -rf /var/lib/apt/lists* /tmp/* /var/log/*

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

COPY --from=builder "/usr/local/bin/dcc*" "/usr/local/bin/"
COPY --from=builder "/var/dcc" "/var/dcc"

#EXPOSE 5232/tcp
#VOLUME ["/data"]

#HEALTHCHECK --interval=60s --timeout=30s --start-period=10s --retries=5 CMD curl -I -s -L http://localhost:5232/.web/ || exit 1


VOLUME ["/var/lib/spamassassin", "/var/log"]
EXPOSE 783

ENTRYPOINT ["/entrypoint.sh"]
#CMD ["spamd","-i","-A","0.0.0.0/0","-H","/var/lib/spamassassin","-r","/var/run/spamd.pid","-s","stdout","-u","$USERNAME","$EXTRA_OPTIONS"]
#CMD ["/tini","--","spamd","-i","-A","0.0.0.0/0","-H","/var/lib/spamassassin","-r","/var/run/spamd.pid","-s","stdout","-u","$USERNAME","$EXTRA_OPTIONS"]

#CMD ["/tini","--","radicale","-S","-C","/data/radicale.conf"]


