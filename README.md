*** TODO ***

1. Add RFCs: "https://datatracker.ietf.org/api/v1/doc/docalias/?name__startswith=rfc&document__name__contains=%@&document__type=draft", wg_abbr
2. enable @SceneStorage to keep track of where you last were
3. print pdf version of drafts
4. add local time
5. detail view moving from open slides to try and open drafts gives error
6. More details for rooms (maybe room schedule)
7. In group list view, select, then filter, then select crashes
8. Show sessions at each location
9. pdf previews
10. fallback when no native HTML version of draft
11. recording menu item isn't always active (observed object problem?)
12. Add draft / presentation / charter / agenda date to download list
13. Only gets the first 20 drafts right now
14. Recording tab (2nd) on Oauth doesn't always get activated.
15. fix macOS popups and view sizes.
16. Add keyboard shortcuts for iPad and maybe macOS
17. Got errors: Unable to save Document draft-ietf-netconf-...

*** Maybe ***

1. Add favorites to Rooms?
2. add spinning circle when loading the sessions for a meeting?
3. Find a way to select session favorites from detail view?
4. Add inactive drafts?


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
