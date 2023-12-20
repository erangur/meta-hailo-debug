DESCRIPTION = "Hailo Debug Root Profile. \
              #  This recipe installs the .profile with its aliases and splash screen in the root home folder"

LICENSE = "CLOSED"
PROF = ".profile"
SRC_URI = "file://${PROF} \
           file://user_led_blink.sh \
           file://user_led_restore.sh \
           file://sbc_user_led.patch \
"

PROF_PATH = "${S}/${PROF}"
FIRMWARE_INSTALL_DIR = "${ROOT_HOME}"
ROOTFS_FIRMWARE_DIR = "${D}${FIRMWARE_INSTALL_DIR}"
INIT_DIR = "${D}/etc/init.d"

#Patching the LED thing for the SBC
do_patch(){
    if [ "${MACHINE}" = "hailo15-sbc" ]; then
        cd ${S}
        patch -p0 < ${WORKDIR}/sbc_user_led.patch
    fi
}

S = "${WORKDIR}"
do_install() {
  install -d ${ROOTFS_FIRMWARE_DIR}
  install -m 0644 ${PROF_PATH} ${ROOTFS_FIRMWARE_DIR}
}

do_install:append:hailo15-sbc(){
  install -d ${INIT_DIR}
  install -d ${D}/etc/rc5.d
  install -m 0755 "${S}/user_led_blink.sh" ${INIT_DIR}
  install -m 0755 "${S}/user_led_restore.sh" ${INIT_DIR} 
  ln -s -r ${D}/etc/init.d/user_led_blink.sh ${D}/etc/rc5.d/S7user_led_blink.sh
}

FILES:${PN} += "{FIRMWARE_INSTALL_DIR}/{PROF}"
FILES:${PN} += "etc/init.d/user_led_blink.sh"
FILES:${PN} += "etc/init.d/user_led_restore.sh"
FILES:${PN} += "/home"
FILES:${PN} += "/home/root"
FILES:${PN} += "/home/root/.profile"
FILES:${PN} += "${sysconfdir}/rc5.d/S7user_led_blink.sh"

do_package_qa[noexec] = "1"

