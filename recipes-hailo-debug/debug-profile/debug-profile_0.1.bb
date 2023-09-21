DESCRIPTION = "Hailo Debug Root Profile. \
              #  This recipe installs the .profile with its aliases and splash screen in the root home folder"

LICENSE = "CLOSED"
PROF = ".profile"
SRC_URI = "file://${PROF}"

PROF_PATH = "${S}/${PROF}"
FIRMWARE_INSTALL_DIR = "${ROOT_HOME}"
ROOTFS_FIRMWARE_DIR = "${D}${FIRMWARE_INSTALL_DIR}"

S = "${WORKDIR}"
do_install() {
  install -d ${ROOTFS_FIRMWARE_DIR}
  install -m 0644 ${PROF_PATH} ${ROOTFS_FIRMWARE_DIR}
}

FILES:${PN} += "${FIRMWARE_INSTALL_DIR}/${PROF}"

