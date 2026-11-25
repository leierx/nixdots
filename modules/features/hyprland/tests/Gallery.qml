import QtQuick
import Quickshell
import qs.common

// qs-test's gallery of every common/ piece in every state, opened as the panel "gallery" (qst gallery).
Scope {
  Component.onCompleted: Panels.names = [...Panels.names, "gallery"]

  LazyLoader {
    active: Panels.active === "gallery"

    GalleryWindow {}
  }
}
