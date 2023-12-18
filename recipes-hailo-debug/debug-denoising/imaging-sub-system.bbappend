FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI += "file://3aconfig.json"

do_install:append() {
    install -m 0755 ${WORKDIR}/3aconfig.json ${D}${bindir}/
}

