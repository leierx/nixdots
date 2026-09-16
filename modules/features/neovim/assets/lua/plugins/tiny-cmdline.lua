-- tiny-cmdline is setup-less; it needs the new cmdline UI framework
require("vim._core.ui2").enable()
vim.o.cmdheight = 0

require("tiny-cmdline").setup({
    position = { y = "40%" },
    native_types = {}, -- enable all types
})

-- MAYBE WORTH AN ISSUE ON THE REPO?
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "cmd",
--   callback = function()
--     vim.schedule(function()
--       local ok, c = pcall(require, "vim._core.ui2.cmdline")
--       if not ok or c.__no_search_cmdheight then return end
--       c.__no_search_cmdheight = true
--
--       local orig = c.cmdline_show
--       c.cmdline_show = function(...)
--         local r = orig(...)
--         if vim.fn.getcmdtype() ~= "" and vim.o.cmdheight ~= 0 then
--           vim._with({ noautocmd = true, o = { splitkeep = "screen" } }, function()
--             vim.o.cmdheight = 0
--           end)
--         end
--         return r
--       end
--     end)
--   end,
-- })
