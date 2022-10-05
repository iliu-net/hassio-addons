ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk update
RUN apk add --no-cache jq openssh-client sshpass rsync acl libcap

# Copy data for add-on
COPY run.sh /
COPY meta.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
