*** TODO ***

1. print pdf version of drafts
2. Add draft / presentation / charter / agenda date to download list
3. Only gets the first 20 drafts right now
4. Jump between session and location and back 5. Load basename document to support useractivity
6. search tokens
7. dependency graph display as table
8. share sheet and transferable
9. selecting 2nd session should show second agenda (oauth-115)
10. Add date to drafts list
11. bottom bar on iOS schedule/group lists takes up lots of room
12. RFC selection from dependency graph should open internally
13. clicking on rfc links open in Safari
14. macos: search for rfc number, filter select rfc, select rfc again, clear filter and beach ball
15. macos: title in downloads doesn't show up.

*** Maybe ***

1. Add favorites to Rooms?
2. add spinning circle when loading the sessions for a meeting?
3. Add inactive drafts?
4. Use notes app yellow?
5. Choice of drafts formats
6. Add keyboard shortcuts for iPad
7. pdf thumbnails


*** Potential Settings ***

1. session canceled filter

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

error:

2023-02-27 20:53:54.821271-0500 IETFNext[81991:6347467] Metal API Validation Enabled
Load schedule 115: Context(codingPath: [_JSONKey(stringValue: "115", intValue: nil), _JSONKey(stringValue: "Index 98", intValue: 98), CodingKeys(stringValue: "group", intValue: nil), CodingKeys(stringValue: "state", intValue: nil)], debugDescription: "Cannot initialize GroupState from invalid String value abandon", underlyingError: nil)

