FROM python:3.13.0a4-alpine3.19

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main git
RUN apk -U upgrade

RUN apk add --no-cache git docker curl

ARG account=git
RUN addgroup -S ${account} \
    && adduser -S ${account} -G ${account}

USER ${account}:${account}

# Copy local files...
COPY sbom-manifest.sh ./sbom-manifest.sh
COPY updateCompVers.py ./updateCompVers.py

# Does not substitute file in quotes...
CMD ["/sbom-manifest.sh"]
