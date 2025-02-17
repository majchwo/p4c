p4c_add_xfail_reason("dpdk"
  "not implemented"
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_4.p4
  )

p4c_add_xfail_reason("dpdk"
  "cannot be the target of an assignment"
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_2.p4
  )

p4c_add_xfail_reason("dpdk"
  "Not implemented"
  testdata/p4_16_samples/psa-random.p4
  )

p4c_add_xfail_reason("dpdk"
  "Error compiling"
  testdata/p4_16_samples/pna-dpdk-wrong-warning.p4
  testdata/p4_16_samples/pna-dpdk-invalid-hdr-warnings5.p4
  testdata/p4_16_samples/pna-dpdk-invalid-hdr-warnings6.p4
  )

p4c_add_xfail_reason("dpdk"
  "declaration not found"
  testdata/p4_16_samples/psa-dpdk-header-union-typedef.p4
  )

p4c_add_xfail_reason("dpdk"
  "Unknown extern function"
  testdata/p4_16_samples/psa-example-digest-bmv2.p4
  )

p4c_add_xfail_reason("dpdk"
  "Unhandled declaration type"
  testdata/p4_16_samples/psa-test.p4
  )

p4c_add_xfail_reason("dpdk"
  "Direct counters and direct meters are unsupported for wildcard match"
  testdata/p4_16_samples/psa-example-counters-bmv2.p4
  )

p4c_add_xfail_reason("dpdk"
  "Expected atleast 2 arguments"
  testdata/p4_16_samples/psa-meter3.p4
  testdata/p4_16_samples/psa-meter7-bmv2.p4
  )
