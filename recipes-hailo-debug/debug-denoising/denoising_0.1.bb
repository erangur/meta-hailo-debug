LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://denoising_detection.sh \
           file://resources/"

# /home/root/apps/denoising/resources
DENOISING_RES_DIR = "${ROOT_HOME}/apps/denoising/resources"
ROOTFS_APPS_DIR = "${D}/home/root/apps"

S = "${WORKDIR}"

do_install:append() {
    install -d ${D}${ROOT_HOME}/apps/denoising
    install -d ${D}${ROOT_HOME}/apps/denoising/resources
    install -m 0755 ${WORKDIR}/denoising_detection.sh ${D}${ROOT_HOME}/apps/denoising/
    cp -r ${WORKDIR}/resources/* ${D}${ROOT_HOME}/apps/denoising/resources/
}

LAYERDEPENDS_meta-hailo-debug = "core meta-hailo-libhailort meta-hailo-tappas"

IMAGE_INSTALL += " denoising "

FILES:${PN} += " /home/root/apps/* /home/root/apps/${LPR_APP_NAME}/ /home/root/apps/${LPR_APP_NAME}/resources/*"
FILES:${PN} += " /home/root/apps/denoising/* /home/root/apps/denoising/resources/* "
FILES:${PN} += " /home/${USER}/apps/denoising/resources "
FILES:${PN} += " /home/${USER}/apps/denoising/denoising_detection.sh "
FILES:${PN} += " /home/${USER}/apps/denoising/resources/* "
FILES:${PN} += " ${DENOISING_RES_DIR}/* "

PACKAGES = "${PN}"
do_package_qa[noexec] = "1"
                                                                                                                                                                                                                  

