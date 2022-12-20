*** TODO ***

1. Add schedule filter options for day of week or area
2. core data background context
3. Add related drafts: "https://datatracker.ietf.org/api/v1/doc/document/?name__regex=draft-%%5bA-Za-z0-9%%5d%%2a-%@-%%2a&type=draft&states__slug__contains=active", wg_abbr
4. Add RFCs: "https://datatracker.ietf.org/api/v1/doc/docalias/?name__startswith=rfc&document__name__contains=%@&document__type=draft", wg_abbr
5. enable @SceneStorage to keep track of where you last were
6. keep track of all sessions per group
7. Find a way to select session favorites from detail view
8. print pdf version of drafts
9. add local time
10. detail view moving from open slides to try and open drafts gives error
11. Add favorites to Rooms?
12. More details for rooms (maybe room schedule)
13. add spinning circle when loading the sessions for a meeting?
14. In group list view, select, then filter, then select crashes
15. Show sessions at each location
16. have main app handle background downloads (error when app moves to bg)
17. pdf previews
18. change meeting from 115 to 114 and then 115 slides show up under 114.


IETF colors:
	gray: 0xc0c0c0
	dark blue: 0x434254, slightly lighter: 1A329D
	gold: 
	bof background: Color(hex: 0xbaffff, alpha: 0.2)
	dark mode links: 3A82F6

Screenshots:
	1284x2778
	1242x2208
share symbol: square.and.arrow.up

look at: .navigationSplitViewStyle(.balanced)

alternate markdown kit:
https://github.com/bmoliveira/MarkdownKit

JSON error:
Context(codingPath: [], debugDescription: "The given data was not valid JSON.", underlyingError: Optional(Error Domain=NSCocoaErrorDomain Code=3840 "Unable to parse empty data." UserInfo={NSDebugDescription=Unable to parse empty data.}))


crash: PlatformListViewBase has no ViewGraph, version 977faaa doesn't crash on iPad but version eb8343f does crash on iPad 12.9 6th gen simulator but fine on my iPad pro 11 

how to filter out duplicate entries in an array:

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
