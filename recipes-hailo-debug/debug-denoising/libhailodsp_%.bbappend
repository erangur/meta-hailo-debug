do_install:append() {
    install -m 0755 ${D}/${libdir}/libhailodsp.so.1.1 ${D}/${libdir}/libhailodsp.so.0.1
}

INSANE_SKIP:${PN} = "already-stripped"
