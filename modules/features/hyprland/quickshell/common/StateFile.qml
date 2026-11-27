import QtQuick
import Quickshell
import Quickshell.Io

FileView {
  id: root

  required property string name
  // Once the saved file is read, or found missing: the read is async even with blockLoading, as an adapter has it, and a write before it cancels it, saving the defaults over the file.
  property bool ready: false
  property bool unsaved: false

  function save(): void {
    if (root.ready) root.writeAdapter();
    else root.unsaved = true;
  }

  function finishRead(): void {
    root.ready = true;
    if (!root.unsaved) return;
    root.unsaved = false;
    root.writeAdapter();
  }

  path: Quickshell.statePath(name)
  // There is no file until the first write.
  printErrors: false
  // Deferred: writing at once loses a second change made in the same turn.
  onAdapterUpdated: Qt.callLater(root.save)
  onLoaded: root.finishRead()
  onLoadFailed: error => {
    if (error !== FileViewError.FileNotFound) console.warn(`Reading ${path} failed: ${FileViewError.toString(error)}`);
    root.finishRead();
  }
  onSaveFailed: error => console.warn(`Writing ${path} failed: ${FileViewError.toString(error)}`)
}
