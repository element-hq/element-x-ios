//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

enum HTMLFixtures: String, CaseIterable {
    case plainText
    case headers
    case paragraphs
    case matrixIdentifiers
    case links
    case textFormatting
    case blockQuotes
    case codeBlocks
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
            <h1>H1 Header</h1></br>
            <h2>H2 Header</h2></br>
            <h3>H3 Header</h3></br>
            <h4>H4 Header</h4></br>
            <h5>H5 Header</h5></br>
            <h6>H6 Header</h6>
            """
        case .paragraphs:
            """
            <p>This is a paragraph.</p><p>And this is another one.</p>
            <div>And this is a division.</div>
            New lines are ignored.\n\nLike so.</br>
            But this line comes after a line break.</br>
            """
        case .matrixIdentifiers:
            """
            We expect various identifiers to be (partially) detected:</br>
            !room:matrix.org, #room:matrix.org, $event:matrix.org, @user:matrix.org</br>
            matrix://roomid/room:matrix.org, matrix://r/room:matrix.org, matrix://roomid/room:matrix.org/e/event:matrix.org, matrix://roomid/room:matrix.org/u/user:matrix.org</br>
            """
        case .links:
            """
            Links too:</br><a href=\"https://www.matrix.org/\">Matrix rules! 🤘</a>, matrix.org, www.matrix.org, http://matrix.org
            """
        case .textFormatting:
            """
            <b>Text</b> <i>formatting</i> <u>should</u> <s>work</s> properly.</br>
            <strong>Text</strong> <em>formatting</em> does <del>work!</del>.</br>
            <b>And <i>mixed</i></b> <em><s>formatting</s></em> <del><strong>works</strong></del> <u><b>too!!1!</b></u>.
            <br>
            <sup>Thumbs</sup> if you liked it, <sub>sub</sub> if you loved it!
            """
        case .blockQuotes:
            """
            <blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            """
        case .codeBlocks:
            """
            <pre>A preformatted code block<code>struct ContentView: View {
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
            Followed by some plain code blocks</br>
            <code>Hello, world!</code>
            <code><b>Hello</b>, <i>world!</i></code>
            <code><b>Hello</b>, <a href="https://www.matrix.org">world!</a></code>
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
