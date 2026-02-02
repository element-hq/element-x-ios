//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

enum HTMLFixtures: String, CaseIterable {
    case plainText
    case headers
    case paragraphs
    case matrixIdentifiers
    case links
    case textFormatting
    case groupedBlockQuotes
    case separatedBlockQuotes
    case code
    case wideCodeBlock
    case unorderedList
    case orderedList
    
    var rawValue: String {
        switch self {
        case .plainText:
            """
            Nothing is as permanent as a temporary solution that works. 
            Experience is the name everyone gives to their mistakes. 
            If debugging is the process of removing bugs, then programming must be the process of putting them in.
            """
        case .headers:
            """
            <h1>H1 Header</h1>\
            <h2>H2 Header</h2>\
            <h3>H3 Header</h3>\
            <h4>H4 Header</h4>\
            <h5>H5 Header</h5>\
            <h6>H6 Header</h6>
            """
        case .paragraphs:
            """
            <p>This is a paragraph.</p><p>And this is another one.</p>\
            <div>And this is a division.</div>\
            New lines outside of tags are not ignored.\n\nLike so.</br>\
            This line comes after a line break.</br>
            """
        case .matrixIdentifiers:
            """
            We expect various identifiers to be (partially) detected:</br>
            !room:matrix.org, #room:matrix.org, $event:matrix.org, @user:matrix.org</br>
            matrix://roomid/room:matrix.org, matrix://r/room:matrix.org, matrix://roomid/room:matrix.org/e/event:matrix.org, matrix://roomid/room:matrix.org/u/user:matrix.org</br>
            """
        case .links:
            """
            Links too:</br><a href=\"https://www.alpha.org/\">Matrix rules! 🤘</a>, beta.org, www.gamma.org, http://delta.org
            """
        case .textFormatting:
            """
            <b>Text</b> <i>formatting</i> <u>should</u> <s>work</s> properly.
            <strong>Text</strong> <em>formatting</em> does <del>work!</del>.
            <b>And <i>mixed</i></b> <em><s>formatting</s></em> <del><strong>works</strong></del> <u><b>too!!1!</b></u>.
            <sup>Thumbs</sup> if you liked it, <sub>sub</sub> if you loved it!
            """
        case .groupedBlockQuotes:
            """
            <blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            """
        case .separatedBlockQuotes:
            """
            Text before blockquote\
            <blockquote>Some blockquote</blockquote>\
            Text after first blockquote\
            <blockquote>Some other blockquote</blockquote>\
            Text after second blockquote
            """
        case .code:
            """
            <pre>A pre-formatted code block
            <code>struct ContentView: View {
                var body: some View {
                    VStack {
                        Text("Knock, knock!")
                            .padding()
                            .background(Color.yellow, in: RoundedRectangle(cornerRadius: 8))
                        Text("Who's there?")
                    }
                    .padding()
                }
            }</code></pre></br>
            Followed by some inline code</br>
            <p>Plain text <code>code here</code> more text</p>
            <p><code>Hello, world!</code></p>
            <p><code><b>Hello</b>, <i>world!</i></code></p>
            <p><code>&lt;b&gt;Hello&lt;/b&gt;, &lt;i&gt;world!&lt;/i&gt;</code></p>
            <p><code><a href="https://www.matrix.org">This link should not be interpreted as such</a></code></p>
            <p><code>And this https://www.matrix.org should be not highlighted</code></p>
            """
        case .wideCodeBlock:
            """
            <pre><code>CHHapticPattern.mm:487   +[CHHapticPattern patternForKey:error:]: Failed to read pattern library data: Error Domain=NSCocoaErrorDomain Code=260 \
            "The file “hapticpatternlibrary.plist” couldn’t be opened because there is no such file." \
            UserInfo={NSFilePath=/Library/Audio/Tunings/Generic/Haptics/Library/hapticpatternlibrary.plist, \
            NSURL=file:///Library/Audio/Tunings/Generic/Haptics/Library/hapticpatternlibrary.plist, \
            NSUnderlyingError=0x600000da69d0 {Error Domain=NSPOSIXErrorDomain Code=2 "No such file or directory"}}</code></pre>
            """
        case .unorderedList:
            """
            This is an unordered list
            <ul>
            <li>Jones’ <b>Crumpets</b></li>
            <li><i>Crumpetorium</i></li>
            <li>Village <u>Bakery</u></li>
            </ul>
            """
        case .orderedList:
            """
            This is an ordered list
            <ol>
            <li>Jelly Belly</li>
            <li>Starburst</li>
            <li>Skittles</li>
            </ol>
            """
        }
    }
}
