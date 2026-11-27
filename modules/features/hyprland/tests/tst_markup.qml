import QtQuick
import QtTest
import "../quickshell/notifications/markup.js" as Markup

TestCase {
  name: "NotificationMarkup"

  function test_markup_data() {
    return [
      { tag: "keeps b, i and u", body: "<b>a</b> <i>b</i> <u>c</u>", expected: "<b>a</b> <i>b</i> <u>c</u>" },
      { tag: "keeps br", body: "a<br/>b", expected: "a<br>b" },
      { tag: "drops images", body: 'x<img src="http://example.com/a.png">y', expected: "xy" },
      { tag: "drops font", body: '<font size="99">big</font>', expected: "big" },
      { tag: "drops attributes", body: '<b onclick="x">a</b>', expected: "<b>a</b>" },
      { tag: "keeps https links", body: '<a href="https://nixos.org">n</a>', expected: '<a href="https://nixos.org">n</a>' },
      { tag: "keeps mailto links", body: "<a href='mailto:a@b.c'>m</a>", expected: '<a href="mailto:a@b.c">m</a>' },
      { tag: "drops file links", body: '<a href="file:///etc/passwd">p</a>', expected: "p" },
      { tag: "drops a scheme ahead of https", body: '<a href="javascript:x//https://a">p</a>', expected: "p" },
      { tag: "drops links without href", body: "<a>p</a>", expected: "p" },
      { tag: "escapes quotes in links", body: `<a href='https://a/"b'>p</a>`, expected: '<a href="https://a/&quot;b">p</a>' },
      { tag: "escapes stray brackets", body: "1 < 2 > 0", expected: "1 &lt; 2 &gt; 0" },
      { tag: "keeps an address in brackets", body: "From <john@x.com>", expected: "From &lt;john@x.com&gt;" },
      { tag: "breaks lines", body: "a\nb", expected: "a<br>b" },
      { tag: "escapes a bare ampersand", body: "Q&A", expected: "Q&amp;A" },
      { tag: "escapes an ampersand reading as an unknown entity", body: "a&b; c", expected: "a&amp;b; c" },
      { tag: "keeps entities", body: "&lt;&amp;&#233;&#xe9;", expected: "&lt;&amp;&#233;&#xe9;" },
      { tag: "escapes a tag left open before another", body: "<a <b>x", expected: "&lt;a <b>x" },
    ];
  }

  function test_markup(data) {
    compare(Markup.markup(data.body), data.expected);
  }

  // Each unclosed tag once scanned to the end of the body: this took most of a second.
  function test_unclosed_tags_linear() {
    const body = "<a".repeat(25000);
    const start = Date.now();
    compare(Markup.markup(body), "&lt;a".repeat(25000));
    verify(Date.now() - start < 100, `took ${Date.now() - start} ms`);
  }
}
