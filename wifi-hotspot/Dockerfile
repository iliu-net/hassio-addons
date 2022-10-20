ARG BUILD_FROM
FROM $BUILD_FROM

MAINTAINER Alejandro Liu <alejandro_liu@hotmail.com>

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG C.UTF-8
RUN apk update && \
	apk add --no-cache bash jq iw hostapd net-tools dhcp iptables && \
	rm -rf /var/cache/apk/*

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
