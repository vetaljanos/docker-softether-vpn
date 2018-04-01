FROM debian:9-slim

ENV BUILD_VERSION=5.1 \
    SHA256_SUM=aa799fe53967a639a13ade435a603a73053b19e1ccb4b309c230de9ba554af56

RUN apt-get update \
	&& apt-get -y install curl

RUN curl -OL https://github.com/SoftEtherVPN/SoftEtherVPN/archive/${BUILD_VERSION}.tar.gz \
	&& echo "${SHA256_SUM} ${BUILD_VERSION}.tar.gz" | sha256sum -c --strict --quiet \
	&& tar xf ${BUILD_VERSION}.tar.gz && rm ${BUILD_VERSION}.tar.gz \
	&& apt-get install -y --no-install-recommends \ 
        build-essential \
	libreadline7 libreadline-dev \
	libssl1.1 libssl-dev \
        libncurses5 libncurses5-dev \
        zlib1g zlib1g-dev \
        iptables unzip net-tools \
	\
	&& cd SoftEtherVPN-${BUILD_VERSION} && ./configure && make && make install \
        && cd / && rm -rf /SoftEtherVPN-${BUILD_VERSION} \
        && apt-get purge -y \ 
        build-essential \
        libreadline-dev \ 
        libssl-dev \ 
        lib32ncurses5-dev \
        zlib1g-dev \
        && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

COPY scripts /scripts

RUN chmod +x /scripts/*.sh

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/usr/bin/vpnserver", "execsvc"]

