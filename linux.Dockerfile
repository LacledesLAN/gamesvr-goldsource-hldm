# escape=`

FROM lacledeslan/steamcmd as DOWNLOADER

ARG contentServer=content.lacledeslan.net

RUN echo 'Downloading LL custom content' &&`
        mkdir --parents /tmp/out/ &&`
        wget -rkp -nH --no-verbose --cut-dirs=2 -R "index.*,*.md" -e robots=off "http://"$contentServer"/fastDownloads/goldsrc-hldm/" -P "/tmp/out/" &&`
    echo 'deleting any web assets that were downloaded' &&`
        [ -f /tmp/out/lacledeslan.ico ] && rm /tmp/out/lacledeslan.ico &&`
        [ -d /tmp/out/logos ] && rm -rf /tmp/out/logos &&`
    echo 'decompressing any .bz2 files' &&`
        find /tmp/out/ -name "*.bz2" -exec sh -c 'bzip2 -d "$1"' _ {} \;

FROM lacledeslan/gamesvr-goldsource

HEALTHCHECK NONE

ARG BUILDNODE=unspecified
ARG SOURCE_COMMIT=unspecified

LABEL com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="LL Half-Life Deathmatch Dedicated Freeplay Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-goldsource-hldm"

COPY --chown=GoldSource:root ./amxmodx/metamod/metamod.so /app/valve/addons/metamod/dlls/metamod.so

COPY --chown=GoldSource:root ./amxmodx/amxmodx_base /app/valve/addons/amxmodx

COPY --chown=GoldSource:root ./amxmodx/amxmodx_ll-config /app/valve/addons/amxmodx

COPY --chown=GoldSource:root ./dist /app

COPY --chown=GoldSource:root ./dist/linux /app

COPY --chown=GoldSource:root --from=DOWNLOADER /tmp/out/ /app/valve/

# UPDATE USERNAME & ensure permissions
RUN usermod -l HLDM GoldSource &&`
    chmod +x /app/ll-tests/*.sh &&`
    mkdir -p /app/valve/logs &&`
    chmod 775 /app/valve/logs;

# We use appid '90' to download the dedicated server, but the half-life dm client is appid '70'.
# So we need to create a file with the correct appid, so that it matches the client, otherwise
# we get a "Steam validation rejected" error when trying to connect to the server.
RUN echo 70 > /app/steam_appid.txt;

USER HLDM

WORKDIR /app

CMD ["/bin/bash"]

ONBUILD USER root
