FROM lacledeslan/steamcmd AS downloader

ARG contentServer=content.lacledeslan.net

RUN echo 'Downloading LL custom content' && \
        mkdir --parents /tmp/out/ && \
        wget -rkp -nH --no-verbose --cut-dirs=2 -R "index.*,*.md" -e robots=off "http://"$contentServer"/fastDownloads/goldsrc-hldm/" -P "/tmp/out/" && \
    echo 'deleting any web assets that were downloaded' && \
        [ -f /tmp/out/lacledeslan.ico ] && rm /tmp/out/lacledeslan.ico && \
        [ -d /tmp/out/logos ] && rm -rf /tmp/out/logos && \
    echo 'decompressing any .bz2 files' && \
        find /tmp/out/ -name "*.bz2" -exec sh -c 'bzip2 -d "$1"' _ {} \;


#---------------------------------
FROM lacledeslan/gamesvr-goldsource

ARG BUILD_DATE=unspecified \
    BUILD_NODE=unspecified \
    GIT_REVISION=unspecified

HEALTHCHECK NONE

LABEL architecture="amd64" \
      com.lacledeslan.build-node="$BUILD_NODE" \
      maintainer="Laclede's LAN <contact@lacledeslan.com>" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.description="LL Half-Life Deathmatch Dedicated Freeplay Server" \
      org.opencontainers.image.revision="$GIT_REVISION" \
      org.opencontainers.image.source="https://github.com/LacledesLAN/gamesvr-goldsource-hldm" \
      org.opencontainers.image.vendor="Laclede's LAN"

COPY --chown=GoldSource:root ./amxmodx/metamod/metamod.so /app/valve/addons/metamod/dlls/metamod.so

COPY --chown=GoldSource:root ./amxmodx/amxmodx_base /app/valve/addons/amxmodx

COPY --chown=GoldSource:root ./amxmodx/amxmodx_ll-config /app/valve/addons/amxmodx

RUN echo "precache.amxx" >> /app/valve/addons/amxmodx/configs/plugins.ini

COPY --chown=GoldSource:root ./dist/default.pre /app/valve/addons/amxmodx/configs/precache/default.pre

COPY --chown=GoldSource:root ./dist /app

COPY --chown=GoldSource:root ./dist/linux /app

COPY --chown=GoldSource:root --from=downloader /tmp/out/ /app/valve/

# UPDATE USERNAME & ensure permissions
RUN usermod -l HLDM GoldSource && \
    chmod +x /app/ll-tests/*.sh && \
    mkdir -p /app/valve/logs && \
    chmod 775 /app/valve/logs;

# We use appid '90' to download the dedicated server, but the half-life dm client is appid '70'.
# So we need to create a file with the correct appid, so that it matches the client, otherwise
# we get a "Steam validation rejected" error when trying to connect to the server.
RUN echo 70 > /app/steam_appid.txt;

USER HLDM

WORKDIR /app

CMD ["/bin/bash"]
