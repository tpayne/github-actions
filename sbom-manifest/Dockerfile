FROM python:3.13.0-alpine3.19

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main git
RUN apk -U upgrade

RUN apk add --no-cache git docker curl

RUN pip install PyYAML
ARG account=git
RUN addgroup -S ${account} \
    && adduser -S ${account} -G ${account}


# Copy local files...
RUN mkdir -p /opt/tools/
RUN chmod a+rx /opt/tools/

COPY sbom-manifest.sh /opt/tools/sbom-manifest.sh
COPY updateCompVers.py /opt/tools/updateCompVers.py
#RUN ln -s /opt/tools/sbom-manifest.sh /sbom-manifest.sh

USER ${account}:${account}

# Does not substitute file in quotes...
ENTRYPOINT ["/opt/tools/sbom-manifest.sh"]


