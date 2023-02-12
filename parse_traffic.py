#!/usr/bin/env python
"""
Read a mitmproxy dump file.
"""
from mitmproxy import io, http
from mitmproxy.exceptions import FlowReadException
import pprint

path = "/usr/share/mitm-data/traffic.log"

with open(path, "rb") as logfile:
    freader = io.FlowReader(logfile)
    pp = pprint.PrettyPrinter(indent=4)
    try:
        for f in freader.stream():
            if isinstance(f, http.HTTPFlow):
                print(f.id, f.request.pretty_url, f.request.host)
            # pp.pprint(f.get_state())
            print("")
    except FlowReadException as e:
        print(f"Flow file corrupted: {e}")
