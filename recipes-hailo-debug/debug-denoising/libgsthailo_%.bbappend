FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI += " file://so/libgsthailo.so \
           file://so/libhailo_gst_metadata_singleton.so.3"


do_install:append() {
    install -m 0755 ${WORKDIR}/so/libhailo_gst_metadata_singleton.so.3 ${D}/${libdir}/
    install -m 0755 ${WORKDIR}/so/libgsthailo.so ${D}/${libdir}/gstreamer-1.0/
}
    
INSANE_SKIP:${PN} = "already-stripped"
