*** TODO ***

1. Add schedule filter options for day of week or area
2. core data background context
3. Add related drafts: "https://datatracker.ietf.org/api/v1/doc/document/?name__regex=draft-%%5bA-Za-z0-9%%5d%%2a-%@-%%2a&type=draft&states__slug__contains=active", wg_abbr
4. Add RFCs: "https://datatracker.ietf.org/api/v1/doc/docalias/?name__startswith=rfc&document__name__contains=%@&document__type=draft", wg_abbr
5. convert Markdown to HTML
6. enable @SceneStorage to keep track of where you last were
7. keep track of all sessions per group
8. Find a way to select session favorites from detail view
9. print pdf version of drafts
10. add local time
11. webview background loading
12. detail view moving from open slides to try and open drafts gives error
13. Add favorites to Rooms?
14. More details for rooms (maybe room schedule)
15. add spinning circle when loading the sessions for a meeting
16. In group list view, select, then filter, then select crashes
17. Show sessions at each location
18. add drafts to downloads
19. have main app handle background downloads (error when app moves to bg)

IETF colors:
	gray: 0xc0c0c0
	dark blue: 0x434254, slightly lighter: 1A329D
	gold: 
	bof background: Color(hex: 0xbaffff, alpha: 0.2)

Screenshots:
	1284x2778
	1242x2208
share symbol: square.and.arrow.up

look at: .navigationSplitViewStyle(.balanced)

crash: PlatformListViewBase has no ViewGraph, version 977faaa doesn't crash on iPad but version eb8343f does crash on iPad 12.9 6th gen simulator but fine on my iPad pro 11 

how to filter out duplicate entries in an array:

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
