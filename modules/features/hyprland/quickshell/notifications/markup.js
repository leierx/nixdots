.pragma library

// Only the markup the spec allows without body-images; StyledText would also load <img> and obey <font> and the rest.
function markup(body) {
  const anchors = [];
  return body.split(/(<\/?[a-zA-Z][^>]*>)/).map(part => {
    if (!part.startsWith("<")) {
      return part.replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }
    const tag = /^<\s*(\/?)\s*([a-zA-Z]+)([^>]*)>$/.exec(part);
    if (!tag) {
      return "";
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
    const href = /href\s*=\s*(?:"([^"]*)"|'([^']*)')/i.exec(tag[3]);
    const url = href ? href[1] ?? href[2] : "";
    anchors.push(safeLink(url));
    return safeLink(url) ? `<a href="${url.replace(/"/g, "&quot;")}">` : "";
  }).join("");
}

// Others (file:, an app's own schemes) are not for a notification to open.
function safeLink(url) {
  return /^(https?:\/\/|mailto:)/i.test(url);
}
