#include <core.p4>
#include <dpdk/psa.p4>

struct EMPTY { };

typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct headers_t {
    ethernet_t       ethernet;
}

struct metadata_t {
    bit<32> port_in;
    bit<32> port_out;
    bit<32> data;
}


parser MyIP(
    packet_in buffer,
    out headers_t hdr,
    inout metadata_t b,
    in psa_ingress_parser_input_metadata_t c,
    in EMPTY d,
    in EMPTY e) {

    state start {
        buffer.extract(hdr.ethernet);
        transition accept;
    }
}

parser MyEP(
    packet_in buffer,
    out EMPTY a,
    inout metadata_t b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY d,
    in EMPTY e,
    in EMPTY f) {
    state start {
        transition accept;
    }
}

control MyIC(
    inout headers_t hdr,
    inout metadata_t b,
    in psa_ingress_input_metadata_t c,
    inout psa_ingress_output_metadata_t d) {
    ActionSelector(PSA_HashAlgorithm_t.CRC32, 32w1024, 32w16) as;
    PSA_MeterColor_t color_out;
    PSA_MeterColor_t color_in = PSA_MeterColor_t.RED;

    DirectMeter(PSA_MeterType_t.BYTES) meter0;
    action execute_meter () {
        color_out = meter0.execute(color_in, 32w1024);
        b.port_out = (color_out == PSA_MeterColor_t.GREEN ? 32w1 : 32w0);
    }
    table tbl {
        key = {
            hdr.ethernet.srcAddr : exact;
            b.data : selector;
        }
        actions = { NoAction; execute_meter;}
        psa_direct_meter = meter0;
        psa_implementation = as;
    }

    apply {
        tbl.apply();
    }
}

control MyEC(
    inout EMPTY a,
    inout metadata_t b,
    in psa_egress_input_metadata_t c,
    inout psa_egress_output_metadata_t d) {
    apply { }
}

control MyID(
    packet_out buffer,
    out EMPTY a,
    out EMPTY b,
    out EMPTY c,
    inout headers_t hdr,
    in metadata_t e,
    in psa_ingress_output_metadata_t f) {
    apply { }
}

control MyED(
    packet_out buffer,
    out EMPTY a,
    out EMPTY b,
    inout EMPTY c,
    in metadata_t d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}

IngressPipeline(MyIP(), MyIC(), MyID()) ip;
EgressPipeline(MyEP(), MyEC(), MyED()) ep;

PSA_Switch(
    ip,
    PacketReplicationEngine(),
    ep,
    BufferingQueueingEngine()) main;
