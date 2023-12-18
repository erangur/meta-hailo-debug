FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI += " file://so/libgsthailotools.so "


do_install:append() {
    install -m 0755 ${WORKDIR}/so/libgsthailotools.so ${D}/${libdir}/gstreamer-1.0/
}

INSANE_SKIP:${PN} = "already-stripped"
#FILES:${PN} += " /usr/bin/ "
#FILES:${PN} += " /usr/lib/ "
#FILES:${PN} += " /usr/lib/gstreamer-1.0/ "
do_package_qa[noexec] = "1"


