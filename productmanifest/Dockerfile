FROM alpine:latest

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main git
RUN apk -U upgrade

RUN apk add --no-cache git docker curl

RUN (curl -SL https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_amd64 -o /usr/bin/yq && \
		chmod +x /usr/bin/yq)
RUN (curl -SL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/bin/jq && \
		chmod +x /usr/bin/jq)

ARG account=git
RUN addgroup -S ${account} \
    && adduser -S ${account} -G ${account}

USER ${account}:${account}

ARG file=productmanifest.sh
COPY ${file} ./${file}

# Does not substitute file in quotes...
ENTRYPOINT ["/productmanifest.sh"]
