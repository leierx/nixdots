import Quickshell
import Quickshell.Io

FileView {
  required property string name

  path: Quickshell.statePath(name)
  // There is no file until the first write.
  printErrors: false
  // Deferred: writing at once loses a second change made in the same turn.
  onAdapterUpdated: Qt.callLater(writeAdapter)
  onLoadFailed: error => {
    if (error !== FileViewError.FileNotFound) console.warn(`Reading ${path} failed: ${FileViewError.toString(error)}`);
  }
  onSaveFailed: error => console.warn(`Writing ${path} failed: ${FileViewError.toString(error)}`)
}
