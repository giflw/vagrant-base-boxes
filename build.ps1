#!/usr/bin/env pwsh

$CWD = (Get-Location)
$BUILD = (date --utc +%Y%m%d%H%M)
$PROVIDER = 'virtualbox'
$PROVIDER_NAME = "${PROVIDER}-iso.vm"
$HEADLESS = 'false'

packer init -upgrade ./packer_templates

foreach ($DISTRO_PATH in (cat ./distros.build | grep -v '#')) {
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
        echo "arch:        ${ARCH}"
        echo "==================================="
        echo "==================================="

        packer build "-only=$PROVIDER_NAME" `
            -var-file=os_pkrvars/"${DISTRO_FILE}".pkrvars.hcl `
            -var headless=$HEADLESS `
            ./packer_templates

        $BOXFILE = (ls builds/${DISTRO}*${PROVIDER}.box)
        $VERSION = echo $BOXFILE | cut -d - -f 2
        echo $BOXFILE
        echo "==================================="
        echo "==================================="
        echo "version:     ${VERSION}"
        echo "build:       ${BUILD}"
        echo "box version: ${VERSION}.${BUILD}"
        echo "box file:    ${BOXFILE}"
        echo "==================================="
        echo "==================================="

        vagrant cloud publish giflw/$DISTRO "${VERSION}.${BUILD}" ${PROVIDER} `
            ./${BOXFILE} `
            --force `
            --checksum "$(sha512sum ./${BOXFILE} | awk '{print $1}')" `
            --checksum-type sha512 `
            --version-description "${DISTRO} ${VERSION} ${ARCH} ${BUILD}" `
            --release `
            --no-private
    }
    catch {
        echo $Error
        exit
    }
    finally {
        cd $CWD
    }
}
