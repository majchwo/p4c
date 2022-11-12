#include <core.p4>
#define V1MODEL_VERSION 20180101
#include <v1model.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

struct Headers {
    ethernet_t eth_hdr;
}

struct Meta {
}

parser p(packet_in pkt, out Headers hdr, inout Meta m, inout standard_metadata_t sm) {
    state start {
        transition parse_hdrs;
    }
    state parse_hdrs {
        pkt.extract<ethernet_t>(hdr.eth_hdr);
        transition accept;
    }
}

void dummy2(inout Headers val1) {
    val1.eth_hdr.dst_addr = val1.eth_hdr.dst_addr + 48w3;
}
void dummy(inout Headers val) {
    dummy2(val);
    val.eth_hdr.eth_type = 16w2;
    dummy2(val);
}
control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    action simple_action() {
        if (h.eth_hdr.eth_type == 16w1) {
            return;
        }
        h.eth_hdr.src_addr = 48w1;
        dummy(h);
        h.eth_hdr.dst_addr = h.eth_hdr.dst_addr + 48w4;
    }
    apply {
        h.eth_hdr.src_addr = 48w2;
        h.eth_hdr.dst_addr = 48w2;
        h.eth_hdr.eth_type = 16w2;
        simple_action();
    }
}

control vrfy(inout Headers h, inout Meta m) {
    apply {
    }
}

control update(inout Headers h, inout Meta m) {
    apply {
    }
}

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    apply {
    }
}

control deparser(packet_out b, in Headers h) {
    apply {
        b.emit<Headers>(h);
    }
}

V1Switch<Headers, Meta>(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
