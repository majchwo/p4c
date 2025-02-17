/*
Copyright 2020 Intel Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include "pna.p4"


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct empty_metadata_t {
}

const bit<32> NUM_PORTS = 4;

struct main_metadata_t {
    ExpireTimeProfileId_t timeout;
    bit<32> port_out;
}

// User-defined struct containing all of those headers parsed in the
// main parser.
struct headers_t {
    ethernet_t ethernet;
    ipv4_t ipv4;
}

control PreControlImpl(
    in    headers_t  hdr,
    inout main_metadata_t meta,
    in    pna_pre_input_metadata_t  istd,
    inout pna_pre_output_metadata_t ostd)
{
    apply {
    }
}

parser MainParserImpl(
    packet_in pkt,
    out   headers_t       hdr,
    inout main_metadata_t main_meta,
    in    pna_main_parser_input_metadata_t istd)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

control MainControlImpl(
    inout headers_t       hdr,           // from main parser
    inout main_metadata_t user_meta,     // from main parser, to "next block"
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    PNA_MeterColor_t color_out;
    PNA_MeterColor_t color_in = PNA_MeterColor_t.RED;
    DirectMeter(PNA_MeterType_t.PACKETS) meter0;

    action next_hop(PortId_t vport) {
        send_to_port(vport);
    }

    action add_on_miss_action() {
        bit<32> tmp = 0;
        color_out = meter0.execute(color_in, 32w1024);
        user_meta.port_out = (color_out == PNA_MeterColor_t.GREEN ? 32w1 : 32w0);
        add_entry(action_name="next_hop", action_params = tmp, expire_time_profile_id = user_meta.timeout);
    }
    table ipv4_da {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            @tableonly next_hop;
            @defaultonly add_on_miss_action;
        }
        add_on_miss = true;
        const default_action = add_on_miss_action;
        pna_direct_meter = meter0;
    }
    action next_hop2(PortId_t vport, bit<32> newAddr) {
        send_to_port(vport);
        hdr.ipv4.srcAddr = newAddr;
    }
    action add_on_miss_action2() {
        add_entry(action_name="next_hop2", action_params = {32w0, 32w1234}, expire_time_profile_id = user_meta.timeout);
    }
    table ipv4_da2 {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            @tableonly next_hop2;
            @defaultonly add_on_miss_action2;
        }
        add_on_miss = true;
        const default_action = add_on_miss_action2;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_da.apply();
            ipv4_da2.apply();
        }
    }
}
// END:Counter_Example_Part2

control MainDeparserImpl(
    packet_out pkt,
    in    headers_t hdr,                // from main control
    in    main_metadata_t user_meta,    // from main control
    in    pna_main_output_metadata_t ostd)
{
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
    }
}

// BEGIN:Package_Instantiation_Example
PNA_NIC(
    MainParserImpl(),
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    // Hoping to make this optional parameter later, but not supported
    // by p4c yet.
    //, PreParserImpl()
    ) main;
// END:Package_Instantiation_Example
