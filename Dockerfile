FROM ubuntu:18.04
LABEL maintainer "Josh Sunnex <jsunnex@gmail.com>"


###############################################################
#
# Configure
#
###############################################################

# Version of Tizonia to be installed
ARG TIZONIA_VERSION=0.21.0-1

# Configure username for executing process
ENV UNAME tizonia
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# A list of dependencies installed with
ARG PYTHON_DEPENDENCIES=" \
        eventlet>=0.25.1 \
        fuzzywuzzy>=0.17.0 \
        gmusicapi>=12.1.1 \
        joblib>=0.14.1\
        pafy>=0.5.4 \
        plexapi>=3.0.0 \
        pychromecast>=4.1.1 \
        pycountry>=19.8.18 \
        python-levenshtein>=0.12.0 \
        soundcloud>=0.5.0 \
        spotipy>=2.4.4 \
        titlecase>=0.12.0 \
        youtube-dl>=2020.05.29 \
    "

# Build Dependencies (not required in final image)
ARG BUILD_DEPENDENCIES=" \
        build-essential \
        curl \
        gnupg \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        python3-dev \
        python3-pip \
        python3-pkg-resources \
        python3-setuptools \
        python3-wheel \
    "

###############################################################



# Exec build step
RUN \
    echo "**** Update sources ****" \
       && apt-get update \
    && \
    echo "**** Install package build tools ****" \
        && apt-get install -y --no-install-recommends \
            ${BUILD_DEPENDENCIES} \
            locales \
    && \
    echo "**** Generate necessary locales ****" \
        && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
            locale-gen \
    && \
    echo "**** Add additional apt repos ****" \
        && curl -ksSL 'http://apt.mopidy.com/mopidy.gpg' | apt-key add - \
        && echo "deb http://apt.mopidy.com/ stretch main contrib non-free" > /etc/apt/sources.list.d/libspotify.list \
        && curl -ksSL 'https://bintray.com/user/downloadSubjectPublicKey?username=tizonia' | apt-key add - \
        && echo "deb https://dl.bintray.com/tizonia/ubuntu bionic main" > /etc/apt/sources.list.d/tizonia.list \
        && apt-get update \
    && \
    echo "**** Install python dependencies ****" \
        && python3 -m pip install --no-cache-dir --upgrade ${PYTHON_DEPENDENCIES} \
    && \
    echo "**** Install tizonia ****" \
        && apt-get install -y \
            python3-distutils \
            pulseaudio-utils \
            libspotify12 \
            tizonia-all=${TIZONIA_VERSION} \
    && \
    echo "**** create ${UNAME} user and make our folders ****" \
        && mkdir -p \
            /home/${UNAME} \
        && groupmod -g 1000 users \
        && useradd -u 1000 -U -d /home/${UNAME} -s /bin/false ${UNAME} \
        && usermod -G users ${UNAME} \
    && \
    echo "**** Cleanup ****" \
        && apt-get purge -y --auto-remove \
	        ${BUILD_DEPENDENCIES} \
        && apt-get clean \
        && rm -rf \
            /tmp/* \
            /var/tmp/* \
            /var/lib/apt/lists/* \
            /etc/apt/sources.list.d/* \
    && \
    echo


# Copy run script
COPY run.sh /run.sh


# Run Tizonia as non privileged user
USER ${UNAME}
ENV HOME=/home/${UNAME}
WORKDIR ${HOME}


ENTRYPOINT [ "/run.sh" ]
