*** TODO ***

1. Add other filter options like days, bofs
2. core data background context
3. Add related drafts: "https://datatracker.ietf.org/api/v1/doc/document/?name__regex=draft-%%5bA-Za-z0-9%%5d%%2a-%@-%%2a&type=draft&states__slug__contains=active", wg_abbr
4. Add RFCs: "https://datatracker.ietf.org/api/v1/doc/docalias/?name__startswith=rfc&document__name__contains=%@&document__type=draft", wg_abbr
5. make charter use darkmode
6. push the schedule controller on iPhone startup?
7. keep track of all sessions per group
8. Find a way to select session favorites from detail view
9. print pdf version of drafts
10. keep downloaded folder of drafts, slides that can be purged
11. add bofs to group list search filter
12. add settings when add local time
13. crash sometimes when filter by favorites and then select Session
14. webview background loading
15. crash: Thread 1: "The left hand side for an ALL or ANY operator must be either an NSArray or an NSSet."
	Unable to save Document draft-ietf-quic-multipath
	Unable to save Document draft-ietf-quic-multipath
	Unable to save Document charter-ietf-quic

IETF colors:
	gray: 0xc0c0c0
	dark blue: 0x434254, slightly lighter: 1A329D
	gold: 
	bof background: Color(hex: 0xbaffff, alpha: 0.2)

Screenshots:
	1284x2778
	1242x2208
share symbol: square.and.arrow.up

(lldb) print document
(IETFNext.JSONDocument) $R0 = {
  abstract = "   QUIC address migration allows clients to change their IP address\n   while maintaining connection state.  To reduce the ability of an\n   observer to link two IP addresses, clients and servers use new\n   connection IDs when they communicate via different client addresses.\n   This poses a problem for traditional \"layer-4\" load balancers that\n   route packets via the IP address and port 4-tuple.  This\n   specification provides a standardized means of securely encoding\n   routing information in the server's connection IDs so that a properly\n   configured load balancer can route packets with migrated addresses\n   correctly.  As it proposes a structured connection ID format, it also\n   provides a means of connection IDs self-encoding their length to aid\n   some hardware offloads.\n"
  ad = nil
  expires = 2023-04-27 10:31:17 UTC
  external_url = ""
  group = "/api/v1/group/group/2161/"
  id = 95139
  intended_std_level = "/api/v1/name/intendedstdlevelname/ps/"
  internal_comments = ""
  name = "draft-ietf-quic-load-balancers"
  note = ""
  notify = ""
  order = 1
  pages = 41
  resource_uri = "/api/v1/doc/document/draft-ietf-quic-load-balancers/"
  rev = "15"
  rfc = nil
  shepherd = nil
  states = 3 values {
    [0] = "/api/v1/doc/state/1/"
    [1] = "/api/v1/doc/state/150/"
    [2] = "/api/v1/doc/state/38/"
  }
  std_level = nil
  stream = "/api/v1/name/streamname/ietf/"
  submissions = 16 values {
    [0] = "/api/v1/submit/submission/109437/"
    [1] = "/api/v1/submit/submission/109461/"
    [2] = "/api/v1/submit/submission/110551/"
    [3] = "/api/v1/submit/submission/113113/"
    [4] = "/api/v1/submit/submission/113944/"
    [5] = "/api/v1/submit/submission/115306/"
    [6] = "/api/v1/submit/submission/117143/"
    [7] = "/api/v1/submit/submission/120129/"
    [8] = "/api/v1/submit/submission/121677/"
    [9] = "/api/v1/submit/submission/122374/"
    [10] = "/api/v1/submit/submission/123376/"
    [11] = "/api/v1/submit/submission/124074/"
    [12] = "/api/v1/submit/submission/124102/"
    [13] = "/api/v1/submit/submission/125448/"
    [14] = "/api/v1/submit/submission/127513/"
    [15] = "/api/v1/submit/submission/129742/"
  }
  tags = 0 values
  time = 2022-10-24 10:31:17 UTC
  title = "QUIC-LB: Generating Routable QUIC Connection IDs"
  type = "/api/v1/name/doctypename/draft/"
  uploaded_filename = ""
  words = nil
}
(IETFNext.JSONDocument) $R1 = {
  abstract = "   QUIC address migration allows clients to change their IP address\n   while maintaining connection state.  To reduce the ability of an\n   observer to link two IP addresses, clients and servers use new\n   connection IDs when they communicate via different client addresses.\n   This poses a problem for traditional \"layer-4\" load balancers that\n   route packets via the IP address and port 4-tuple.  This\n   specification provides a standardized means of securely encoding\n   routing information in the server's connection IDs so that a properly\n   configured load balancer can route packets with migrated addresses\n   correctly.  As it proposes a structured connection ID format, it also\n   provides a means of connection IDs self-encoding their length to aid\n   some hardware offloads.\n"
  ad = nil
  expires = 2023-04-27 10:31:17 UTC
  external_url = ""
  group = "/api/v1/group/group/2161/"
  id = 95139
  intended_std_level = "/api/v1/name/intendedstdlevelname/ps/"
  internal_comments = ""
  name = "draft-ietf-quic-load-balancers"
  note = ""
  notify = ""
  order = 1
  pages = 41
  resource_uri = "/api/v1/doc/document/draft-ietf-quic-load-balancers/"
  rev = "15"
  rfc = nil
  shepherd = nil
  states = 3 values {
    [0] = "/api/v1/doc/state/1/"
    [1] = "/api/v1/doc/state/150/"
    [2] = "/api/v1/doc/state/38/"
  }
  std_level = nil
  stream = "/api/v1/name/streamname/ietf/"
  submissions = 16 values {
    [0] = "/api/v1/submit/submission/109437/"
    [1] = "/api/v1/submit/submission/109461/"
    [2] = "/api/v1/submit/submission/110551/"
    [3] = "/api/v1/submit/submission/113113/"
    [4] = "/api/v1/submit/submission/113944/"
    [5] = "/api/v1/submit/submission/115306/"
    [6] = "/api/v1/submit/submission/117143/"
    [7] = "/api/v1/submit/submission/120129/"
    [8] = "/api/v1/submit/submission/121677/"
    [9] = "/api/v1/submit/submission/122374/"
    [10] = "/api/v1/submit/submission/123376/"
    [11] = "/api/v1/submit/submission/124074/"
    [12] = "/api/v1/submit/submission/124102/"
    [13] = "/api/v1/submit/submission/125448/"
    [14] = "/api/v1/submit/submission/127513/"
    [15] = "/api/v1/submit/submission/129742/"
  }
  tags = 0 values
  time = 2022-10-24 10:31:17 UTC
  title = "QUIC-LB: Generating Routable QUIC Connection IDs"
  type = "/api/v1/name/doctypename/draft/"
  uploaded_filename = ""
  words = nil
}

two crashes:
1. "The left hand side for an ALL or ANY operator must be either an NSArray or an NSSet." - happened with idr
2. context.save() - happened with QUIC
