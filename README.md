*** TODO ***

1. core data background context
2. Add related drafts: "https://datatracker.ietf.org/api/v1/doc/document/?name__regex=draft-%%5bA-Za-z0-9%%5d%%2a-%@-%%2a&type=draft&states__slug__contains=active", wg_abbr
3. Add RFCs: "https://datatracker.ietf.org/api/v1/doc/docalias/?name__startswith=rfc&document__name__contains=%@&document__type=draft", wg_abbr
4. enable @SceneStorage to keep track of where you last were
5. keep track of all sessions per group
6. Find a way to select session favorites from detail view
7. print pdf version of drafts
8. add local time
9. detail view moving from open slides to try and open drafts gives error
10. Add favorites to Rooms?
11. More details for rooms (maybe room schedule)
12. add spinning circle when loading the sessions for a meeting?
13. In group list view, select, then filter, then select crashes
14. Show sessions at each location
15. have main app handle background downloads (error when app moves to bg)
16. pdf previews
17. fix recording menu item to show both recordings if there are two sessions
18. group.documents isn't reset when re-read drafts


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
