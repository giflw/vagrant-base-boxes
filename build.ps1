#!/usr/bin/env pwsh

$CWD = (Get-Location)
$BUILD = (date --utc +%Y%m%d%H%M)
$PROVIDER = 'virtualbox'
$PROVIDER_NAME = "${PROVIDER}-iso"
$HEADLESS = 'false'

foreach ($DISTRO_PATH in (cat .\distros.build | grep -v '#')) {
    try {
        cd $CWD

        $DISTRO_PARTS = ${DISTRO_PATH}.Split("/")
        $DISTRO = ${DISTRO_PARTS}[0]
        $DISTRO_VERSION = ${DISTRO_PARTS}[1]
        $DISTRO_FILE = "${DISTRO_PATH}"
        $VERSION = ${DISTRO_VERSION}.Split("-")[1]
        $ARCH = ${DISTRO_VERSION}.Split("-")[2]
        if (-not ${VERSION}.Contains('.')) {
            $VERSION = "${VERSION}.0"
        }
        

        echo "==================================="
        echo "==================================="
        echo "${DISTRO} / ${DISTRO_VERSION}"
        echo "distro:      ${DISTRO}"
        echo "version:     ${VERSION}"
        echo "arch:        ${ARCH}"
        echo "build:       ${BUILD}"
        echo "box version: ${VERSION}.${BUILD}"
        echo "==================================="
        echo "==================================="

        packer build "-only=$PROVIDER_NAME" `
            -var box_basename=$DISTRO_VERSION `
            -var headless=$HEADLESS `
            -var build_directory=./builds `
            packer_templates/${DISTRO_FILE}.json

        vagrant cloud publish giflw/$DISTRO "${VERSION}.${BUILD}" ${PROVIDER} `
            ./builds/${DISTRO_VERSION}.${PROVIDER}.box `
            --force `
            --checksum "$(sha512sum ./builds/${DISTRO_VERSION}.${PROVIDER}.box | awk '{print $1}')" `
            --checksum-type sha512 `
            --version-description "${DISTRO} ${VERSION} ${ARCH} ${BUILD}" `
            --release `
            --no-private
    }
    catch {
        exit
    }
    finally {
        cd $CWD
    }
}
