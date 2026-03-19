import app from "ags/gtk4/app"
import style from "./style/main.scss"
import Topbar from "./widget/topbar"
import { Gdk } from "ags/gtk4"
import { For, This, createBinding } from "ags"

// TESTING
// import { execAsync } from "ags/process"
// import { monitorFile } from "ags/file"
// (async () => {
//   const pathsToMonitor = [`${SRC}/style` ]
//   const mainScss = `${SRC}/style/main.scss` // SCSS input file to compile
//   const css = `/tmp/style.css` // CSS output file
// 
//   let isApplying = false
// 
//   async function transpileAndApply() {
//     if (isApplying) return
//     isApplying = true
// 
//     try {
//       await execAsync(`sass ${mainScss} ${css}`)
//       app.apply_css(css, true)
//       print("CSS applied successfully!")
//     } catch (error) {
//       print("Error transpiling SCSS:", error)
//       execAsync(`notify-send -u critical "Error transpiling SCSS" "${error}"`)
//     } finally {
//       isApplying = false
//     }
//   }
// 
//   pathsToMonitor.forEach((path) => monitorFile(path, transpileAndApply))
// 
//   return transpileAndApply()
// })()

function main() {
  const monitors = createBinding(app, "monitors")

  return (
    <For each={monitors}>
      {(monitor: Gdk.Monitor) => (
        <This this={app}>
          <Topbar gdkmonitor={monitor}/>
        </This>
      )}
    </For>
  )
}

app.start({ css: style, main })
