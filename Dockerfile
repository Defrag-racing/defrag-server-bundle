FROM debian:bookworm-slim

# 1) Since Q3DF's GameDLL uses x86, we need to enable support for i386. 
RUN dpkg --add-architecture i386

# 2) Update the list & install most required packages
RUN apt-get update && apt-get install -y wget gnupg unionfs-fuse lsb-release inetutils-tools
RUN apt-get install -y libxml2:i386 

# 3) Create user for the folder /server that'll be used later
RUN groupadd -r q3user
RUN useradd --no-log-init --system --create-home --home-dir /server --gid q3user q3user

# 4) Install libmysqlclient20 (important for modules)
COPY .install/libmysqlclient20_5.7.21-1ubuntu1_i386.deb /server
RUN dpkg --unpack /server/libmysqlclient20_5.7.21-1ubuntu1_i386.deb
RUN rm /server/libmysqlclient20_5.7.21-1ubuntu1_i386.deb

# 5) Now work on the folder...
USER q3user
WORKDIR /server

# 6) Get latest oDFe build from defrag racing. The standalone oDFe.ded is no
#    longer refreshed; the engine now ships inside dfsv-core.tar, so pull the
#    core bundle and keep just the binary.
RUN wget https://dl.defrag.racing/downloads/dfsv-core.tar \
    && tar -xf dfsv-core.tar oDFe.ded \
    && rm dfsv-core.tar
RUN chmod +x /server/oDFe.ded

# 9) Copy the start script and the initial maps for DF
COPY game/start.sh /server/start.sh

ENV TERM xterm
ENTRYPOINT ["./start.sh"]