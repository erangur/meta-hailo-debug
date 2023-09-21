FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
DEPENDS += " libsdl2 "
EXTRA_OECONF += " --extra-libs='-ldl' --enable-ffplay "

