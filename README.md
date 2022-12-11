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
13. fixed? crash sometimes when filter by favorites and then select Session
14. webview background loading
15. detail view moving from open slides to try and open drafts gives error

IETF colors:
	gray: 0xc0c0c0
	dark blue: 0x434254, slightly lighter: 1A329D
	gold: 
	bof background: Color(hex: 0xbaffff, alpha: 0.2)

Screenshots:
	1284x2778
	1242x2208
share symbol: square.and.arrow.up

two crashes, I think fixed with context.performAndWait {}:
1. "The left hand side for an ALL or ANY operator must be either an NSArray or an NSSet." - happened with idr
2. context.save() - happened with QUIC
