#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   echo "Best run 'sudo su' and then re-run this script"
   exit 1
fi

clear
cat <<'EOF'
                                                                   .odNMMmy:
                                                                   /MMMMMMMMMy
                                                                  `NMMMMMMMMMM:
                                                                   mMMMMMMMMMM-
                                `::-                               -dMMMMMMMN/
                    `+sys/`    sNMMMm/   /ydho`                      :oyhhs/`
                   :NMMMMMm-  -MMMMMMm  :MMMMMy  .+o/`
                   hMMMMMMMs   sNMMMm:  `dMMMN/ .NMMMm
                   -mMMMMMd.    `-:-`     .:-`  `hMMNs -syo`          .odNNmy/        `.
                    `:oso:`                       `.`  mMMM+         -NMMMMMMMy    :yNNNNh/
                       `--.      :ydmh/    `:/:`       -os+`/s+`     sMMMMMMMMM`  +MMMMMMMMs
                     .hNNNNd/   /MMMMMM+  :mMMMm-   ``     -MMM+     -NMMMMMMMy   hMMMMMMMMN
            ``       mMMMMMMM-  :MMMMMM/  oMMMMM/ .hNNd:    -/:`      .odmmdy/`   :NMMMMMMN+
         -sdmmmh/    dMMMMMMN.   -shhs:   `/yhy/  /MMMMs `--`           ````       .ohddhs-
        :NMMMMMMMy   `odmNmy-                      /ss+``dNNm.         .-.`           ``
        yMMMMMMMMM`    ``.`                             `hNNh.       /dNNNms`      `-:-`
        :NMMMMMMMs          .--.      /yddy:    .::-`    `..`       /MMMMMMMh    `smNNNms`
         .ohdmdy:         -hmNNmh:   +MMMMMM/  /mMMNd.   ``         :MMMMMMMy    oMMMMMMMs   `-::.
            ```  ``      `NMMMMMMN.  +MMMMMN:  yMMMMM- -hmmh-        /hmNNdo`    +MMMMMMM+  +mNMNNh-
              -sdmmdy:   `mMMMMMMN`   :yhhs-   `+hhy:  oMMMMo          ...`       /hmmmh/  :MMMMMMMm
             /NMMMMMMNo   .sdmmmy-                     `+yy/`     -+ss+.            `.`    .NMMMMMMh
             dMMMMMMMMN     `..`                                 /NMMMMm-      :shyo.       -sdmmh+`
     `       /NMMMMMMMo                 .-.                      oMMMMMM/     sMMMMMm.        ```
 `/ydddho-    -sdmmdy:                `hNNms                     `odmmd+      yMMMMMN-   -shhs:
-mMMMMMMMNo     ````           `--.   `mMMMm                 `-//- `..        `odddy:   :NMMMMN/
mMMMMMMMMMM:            .//.   yNMN/   .+o/.                `dMMMNo       ./o+-  ``     /MMMMMM+
mMMMMMMMMMM:            dMMd   ommd:     -+o/.              .NMMMMy      -mMMMN+         /hddh/
:mMMMMMMMNs             -oo-    .:.     +NMMMm-         .//- -shy+`      -NMMMMo    `/oo:`  `
 `+ydmmdo-            `ohy/    smmdo    oMMMMN:        /NMMN+       `:++- -oso:    `dMMMMh
     ``               /MMMm   `NMMMN`    :oso-         :mMMN/       oMMMM/         `mMMMMh
                       :o+-    -oyo-         -+oo:`     .::.   -oo: /mNNm-     -+o/``/ss/`
                      `:oo:      .:/-`      oMMMMMh`          `NMMM- `--`     :MMMMy
                      oMMMM/    :mMMMm-     mMMMMMM.           +hho`     .+s+`.dNNm+
                      :mNNd-    oMMMMM/     -hmNNd/                 -o+. hMMMo  .-`
                       `..``    `/yhy/        `.`  `:oss+.          mMMh -shs.
                        :ydds.       .://.        `hMMMMMN+         -+/.
                       .MMMMMm      +NMMMMy       /MMMMMMMm
                        yNNNN+      mMMMMMM-      `dMMMMMN+    ````
                         .--` ``    :dNNNmo         :oss+.   -ydNNmh/
                            /hmmh+`   .--`  ./++:`          /MMMMMMMMy
                           :MMMMMMs        yMMMMMm/         hMMMMMMMMM      `-::-`
                           -NMMMMM+       /MMMMMMMN         :NMMMMMMMo    -yNMMMMMh:
                            .oyys-   ``   `mMMMMMMs          .ohmmds-    -NMMMMMMMMM+
                                  `+dNNmy- `+yhhs:   `ohmmds-            sMMMMMMMMMMd
                                  hMMMMMMM-         -NMMMMMMMs           :MMMMMMMMMMo
                                  dMMMMMMM:         yMMMMMMMMM`           :dMMMMMMm+
                                  .hMMMMm+          :MMMMMMMMy              .:++/.
                                    `--.             -ymMMNh/
EOF


### IRI VERSION
IRI_VERSION="1.6.0-RC7"

cat <<EOF

Welcome to IOTA Fullnode - Upgrade to Local Snapshots!
1. By pressing 'y' you agree to UPGRADE the IRI fullnode on your system to the new Release Candidate version $IRI_VERSION.
2. By pressing 'y' you aknowledge that this installer requires a working IRI node installed by the iri-playbook.
3. This upgrade script DOES NOT support the "dockerized" iri-playbook version.
EOF

read -p "Do you wish to proceed? [y/N] " yn
if echo "$yn" | grep -v -iq "^y"; then
    echo Cancelled
    exit 1
fi

function finish {
    EXIT_CODE=$?
    cd "$CURRENT_DIR"
    rm -f /tmp/iota.snap.tgz /tmp/iota.snap.tgz.sha256sum "/tmp/iri-${IRI_VERSION}.jar.sha256sum" "/tmp/iri-${IRI_VERSION}.jar"
    /bin/systemctl start iri
    if [ $EXIT_CODE -eq 0 ]
    then
        echo "Done. Please check iri's status with 'journalctl -u iri -e -f'"
    else
        echo "Something went wrong ..."
        exit $EXIT_CODE
    fi
}
trap finish INT TERM EXIT

if ! [ -f "/usr/bin/wget" ]
then
    echo "Missing wget! Please install it with 'apt install wget -y' or 'yum install wget -y' for CentOS"
    exit 1
fi

CURRENT_DIR="$(pwd)"
echo "Downloading iota snapshot meta/state files ..."
wget -O /tmp/iota.snap.tgz https://snap.x-vps.com/iota.snap.tgz
wget -O /tmp/iota.snap.tgz.sha256sum https://snap.x-vps.com/iota.snap.tgz.sha256sum

echo "Downloading the pre-compiled IRI version $IRI_VERSION ..."
wget -O "/tmp/iri-${IRI_VERSION}.jar" "https://snap.x-vps.com/iri-${IRI_VERSION}.jar"
wget -O "/tmp/iri-${IRI_VERSION}.jar.sha256sum" "https://snap.x-vps.com/iri-${IRI_VERSION}.jar.sha256sum"
echo "Verifying checksum ..."
cd /tmp
sha256sum --check iota.snap.tgz.sha256sum
sha256sum --check "iri-${IRI_VERSION}.jar.sha256sum"
echo "Checksums OK!"

echo "Move files to iri's directory location ..."
mv "/tmp/iri-${IRI_VERSION}.jar" "/var/lib/iri/target/iri-${IRI_VERSION}.jar"

echo "Stopping iri ..."
/bin/systemctl stop iri

echo "Cleaning up old database files and extracting new files ..."
rm -rf /var/lib/iri/target/mainnet*
mkdir /var/lib/iri/target/mainnetdb

cd /var/lib/iri/target
tar zxvf /tmp/iota.snap.tgz
chown -R iri.iri /var/lib/iri/target

echo "Configuring files ..."
[ -f "/etc/default/iri" ] && sed -i "s/^IRI_VERSION=.*/IRI_VERSION=$IRI_VERSION/" /etc/default/iri
[ -f "/etc/sysconfig/iri" ] && sed -i "s/^IRI_VERSION=.*/IRI_VERSION=$IRI_VERSION/" /etc/sysconfig/iri
[ -f "$HOME/.nbctl" ] && sed -i "s/^api_version:.*/api_version: $IRI_VERSION/" "$HOME/.nbctl"
