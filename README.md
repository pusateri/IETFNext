*** TODO ***

1. print pdf version of drafts
2. detail view moving from open slides to try and open drafts gives error
3. pdf thumbnails
4. Add draft / presentation / charter / agenda date to download list
5. Only gets the first 20 drafts right now
6. Jump between session and location and back
7. Load basename document to support useractivity
8. macOS: app icon
9. JSON parse errors
10. search tokens
11. dependency graph display as table
12. share sheet and transferable
13. selecting 2nd session should show second agenda (oauth-115)
14. Add date to drafts list
15. bottom bar on iOS schedule/group lists takes up lots of room
16. RFC selection from dependency graph should open internally

*** Maybe ***

1. Add favorites to Rooms?
2. add spinning circle when loading the sessions for a meeting?
3. Add inactive drafts?
4. Use notes app yellow?
5. Choice of drafts formats
6. Add keyboard shortcuts for iPad


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

BCP 0009 specifically RFC 2026 obsoletes 1871 which updates 1603 which is obsoleted by 2418 which shows on graph but no arrow is attached.

Core Data store: 

# cd ~/Library/Containers/com.bangj.IETFNext/Data/Library/
# rm Application\ Support/IETFNext/IETFNext.sqlite*
# rm -rf Application\ Scripts/com.bangj.IETFNext
# rm -rf HTTPStorages/com.bangj.IETFNext
# rm -rf Caches/com.bangj.IETFNext
# rm Preferences/com.bangj.IETFNext.plist
