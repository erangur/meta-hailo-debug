#!/bin/bash
set -e

CURRENT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

function init_variables() {
    readonly RESOURCES_DIR="${CURRENT_DIR}/resources"
    readonly POSTPROCESS_DIR="/usr/lib/hailo-post-processes"
    readonly DEFAULT_POSTPROCESS_SO="$POSTPROCESS_DIR/libyolo_post.so"
    readonly CONCAT_SO="$RESOURCES_DIR/libdenoising_concat.so"
    readonly JOIN_SO="$RESOURCES_DIR/libdenoising_join.so"
    readonly DEFAULT_VIDEO_SOURCE="/dev/video0"
    readonly DEFAULT_HEF_PATH="${RESOURCES_DIR}/VD1_output_clip_270623.hef"
    readonly DEFAULT_DETECTION_HEF_PATH="${RESOURCES_DIR}/yolov5m_wo_spp_60p_nv12_small.hef"
    readonly DEFAULT_JSON_CONFIG_PATH="$RESOURCES_DIR/configs/yolov5.json" 
    readonly DEFAULT_UDP_PORT=5000
    readonly DEFAULT_UDP_HOST_IP="10.0.0.2"
    readonly DEFAULT_FRAMERATE="30/1"
    readonly DEFAULT_IMAGE_PATH="${RESOURCES_DIR}/denoising_test_img.png"
    readonly DEFAULT_DETECTION_NETWORK_NAME="yolov5"
    readonly CROPING_ALGORITHMS_DIR="$POSTPROCESS_DIR/cropping_algorithms"
    readonly WHOLE_BUFFER_CROP_SO="$CROPING_ALGORITHMS_DIR/libwhole_buffer.so"
    readonly OSD_CONFIG_PATH="/home/root/apps/detection/resources/configs/osd.json"

    network_name=$DEFAULT_DETECTION_NETWORK_NAME
    postprocess_so=$DEFAULT_POSTPROCESS_SO
    input_source=$DEFAULT_VIDEO_SOURCE
    hef_path=$DEFAULT_HEF_PATH
    json_config_path=$DEFAULT_JSON_CONFIG_PATH
    detection_hef_path=$DEFAULT_DETECTION_HEF_PATH
    udp_port=$DEFAULT_UDP_PORT
    udp_host_ip=$DEFAULT_UDP_HOST_IP
    sync_pipeline=true
    framerate=$DEFAULT_FRAMERATE

    print_gst_launch_only=false
    additional_parameters=""
    max_buffers_size=5
}

function print_usage() {
    echo "Hailo15 Detection pipeline usage:"
    echo ""
    echo "Options:"
    echo "  --help                  Show this help"
    echo "  -i INPUT --input INPUT  Set the camera source (default $input_source)"
    echo "  --show-fps              Print fps"
    echo "  --print-gst-launch      Print the ready gst-launch command without running it"
    exit 0
}

function parse_args() {
    while test $# -gt 0; do
        if [ "$1" = "--help" ] || [ "$1" == "-h" ]; then
            print_usage
            exit 0
        elif [ "$1" = "--print-gst-launch" ]; then
            print_gst_launch_only=true
        elif [ "$1" = "--show-fps" ]; then
            echo "Printing fps"
            additional_parameters="-v | grep hailo_display"
        elif [ "$1" = "--input" ] || [ "$1" = "-i" ]; then
            input_source="$2"
            shift
        else
            echo "Received invalid argument: $1. See expected arguments below:"
            print_usage
            exit 1
        fi

        shift
    done
}

init_variables $@

parse_args $@

UDP_SINK="udpsink host=$udp_host_ip port=$udp_port"

# # v4l2src device=$input_source io-mode=mmap num-buffers=8 ! video/x-raw,format=NV12,width=1920,height=1080, framerate=$framerate ! \

FHD_BRANCH="tee name=fhd_tee \
            fhd_tee. ! \
            queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailocropper so-path=$WHOLE_BUFFER_CROP_SO function-name=create_crops name=cropper2 \
    hailoaggregator name=agg2 \
    cropper2. ! \
        queue leaky=no max-size-buffers=50 max-size-bytes=0 max-size-time=0 ! \
    agg2. \
    cropper2. ! \
        queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
        hailonet hef-path=$detection_hef_path vdevice-key=1 ! \
        queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
        hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! \
        queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    agg2. \
    agg2. ! \
    identity sleep-time=30000 ! \
    hailooverlay qos=false ! \
            queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
            hailoosd wait-for-writable-buffer=true config-path=$OSD_CONFIG_PATH ! \
            queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
            hailoh265enc ! \
            video/x-h265,framerate=$framerate ! \
            queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
            rtph265pay ! 'application/x-rtp, media=(string)video, encoding-name=(string)H265' ! \
            udpsink host=10.0.0.2 port=5002 sync=true \
            fhd_tee."

PIPELINE="gst-launch-1.0 \
    v4l2src device=$input_source io-mode=mmap ! video/x-raw,format=NV12,width=1920,height=1080, framerate=$framerate ! \
    queue leaky=downstream max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    $FHD_BRANCH ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailovideoscale ! video/x-raw,width=1920, height=1080, format=NV12 ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailofilter use-gst-buffer=true remove-tensors=false so-path=$CONCAT_SO qos=false ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailonet input-from-meta=true hef-path=$hef_path vdevice-key=1 ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailofilter use-gst-buffer=true remove-tensors=true so-path=$JOIN_SO loopback-tensors=true qos=false ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailocropper so-path=$WHOLE_BUFFER_CROP_SO function-name=create_crops name=cropper1 \
    hailoaggregator name=agg1 \
    cropper1. ! \
        queue leaky=no max-size-buffers=50 max-size-bytes=0 max-size-time=0 ! \
    agg1. \
    cropper1. ! \
        queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
        hailonet hef-path=$detection_hef_path vdevice-key=1 ! \
        queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
        hailofilter function-name=$network_name config-path=$json_config_path so-path=$postprocess_so qos=false ! \
        queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    agg1. \
    agg1. ! \
    identity sleep-time=20000 ! \
    hailooverlay qos=false ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    hailoh265enc ! h265parse config-interval=-1 ! \
    video/x-h265,framerate=$framerate ! \
    tee name=udp_tee \
    udp_tee. ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    rtph265pay ! 'application/x-rtp, media=(string)video, encoding-name=(string)H265' ! \
    $UDP_SINK name=udp_sink sync=$sync_pipeline \
    udp_tee. ! \
    queue leaky=no max-size-buffers=$max_buffers_size max-size-bytes=0 max-size-time=0 ! \
    fpsdisplaysink video-sink=fakesink name=hailo_display sync=$sync_pipeline text-overlay=false \
    ${additional_parameters}"

echo "Running $network_name"
echo ${PIPELINE}

if [ "$print_gst_launch_only" = true ]; then
    exit 0
fi

eval ${PIPELINE}
