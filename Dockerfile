FROM ubuntu

LABEL org.opencontainers.image.title="Datastore emulator"
LABEL org.opencontainers.image.authors="marcos.jauregui@wizeline.com"
LABEL org.opencontainers.image.source=https://github.com/marcos-wz/datastore-emulator
LABEL org.opencontainers.image.description="GCP Datastore emulator based on ubuntu"

# SETUP ---------------------------------------------------------------------

ARG DS_USER="dsuser"
ARG DS_HOME="/home/${DS_USER}"

RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt --yes -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends -qq \
        curl \
        default-jre \
    # CREATE USER
    && useradd --comment "datastore emulator user" \
        --create-home \
        --home-dir ${DS_HOME} \        
        ${DS_USER} \
    # CLEAN INSTALLATION
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq clean \
    && rm -fr /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \ 
        ~/.cache 

# INSTALL EMULATOR --------------------------------------------------------------------

USER ${DS_USER}

ARG PORT="8081"
ARG GCLOUD_ARCH="x86_64"
ARG GCLOUD_VERSION="458.0.1"
ARG GCLOUD_FILE="google-cloud-cli-${GCLOUD_VERSION}-linux-${GCLOUD_ARCH}.tar.gz"

ENV CLOUDSDK_CORE_PROJECT="test-project"
ENV DS_HOST="0.0.0.0"
ENV DS_PORT=${PORT}
ENV GCLOUD_DIR="${DS_HOME}/google-cloud-sdk"
ENV GCLOUD_STORE_ON_DISK=false

RUN <<EOT bash
    set -eux
    curl -sS -o ${DS_HOME}/${GCLOUD_FILE} https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_FILE} 
    tar -xf ${DS_HOME}/${GCLOUD_FILE} -C ${DS_HOME}/ 
    rm -v ${DS_HOME}/${GCLOUD_FILE}
    ${GCLOUD_DIR}/install.sh \
        --quiet \
        --usage-reporting false \
        --path-update true \
        --command-completion true
    source ${GCLOUD_DIR}/path.bash.inc
    gcloud components install \
        beta \
        cloud-datastore-emulator \
        --quiet
EOT

COPY ./entrypoint.sh /entrypoint.sh

EXPOSE ${PORT}

ENTRYPOINT [ "./entrypoint.sh" ]
