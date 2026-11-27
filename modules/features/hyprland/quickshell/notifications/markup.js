.pragma library

// Only the markup the spec allows without body-images; StyledText would also load <img> and obey <font> and the rest.
function markup(body) {
  const anchors = [];
  // A tag ends at the next <, or every unclosed one would scan to the end of the body.
  return body.split(/(<\/?[a-zA-Z][^<>]*>)/).map(part => {
    const tag = /^<\s*(\/?)\s*([a-zA-Z]+)(\s[^>]*|\/)?>$/.exec(part);
    if (!tag) {
      return text(part);
    }
    const closing = tag[1] === "/";
    const name = tag[2].toLowerCase();
    if (["b", "i", "u"].includes(name)) {
      return `<${closing ? "/" : ""}${name}>`;
    }
    if (name === "br") {
      return "<br>";
    }
    if (name !== "a") {
      return "";
    }
    if (closing) {
      return anchors.pop() ? "</a>" : "";
    }
    const href = /href\s*=\s*(?:"([^"]*)"|'([^']*)')/i.exec(tag[3] ?? "");
    const url = href ? href[1] ?? href[2] : "";
    anchors.push(safeLink(url));
    return safeLink(url) ? `<a href="${url.replace(/"/g, "&quot;")}">` : "";
  }).join("");
}

// StyledText reads a bare & as an entity up to the next ; or space, and folds newlines into spaces.
function text(part) {
  return part
    .replace(/&(?!(?:amp|lt|gt|quot|apos|nbsp|#[0-9]+|#[xX][0-9a-fA-F]+);)/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\n/g, "<br>");
}

// Others (file:, an app's own schemes) are not for a notification to open.
function safeLink(url) {
  return /^(https?:\/\/|mailto:)/i.test(url);
}
