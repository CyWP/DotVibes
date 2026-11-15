-- Code review: inline comments + gutter signs on files/diffs, exports markdown
-- (quickfix-review by MMesch; +/- cycles comment type, ]r/[r navigate comments)
return {
  "MMesch/quickfix-review-nvim",
  cmd = {
    "ReviewAddIssue", "ReviewAddSuggestion", "ReviewAddNote", "ReviewAddPraise",
    "ReviewDelete", "ReviewView", "ReviewExport", "ReviewClear",
    "ReviewSave", "ReviewLoad", "ReviewSummary", "ReviewGoto",
  },
  keys = {
    { "<leader>ca", desc = "Review: add comment (current type)" },
    { "<leader>cd", desc = "Review: delete comment" },
    { "<leader>cv", desc = "Review: view comment" },
    { "<leader>ce", desc = "Review: export markdown" },
    { "<leader>cc", desc = "Review: clear all" },
    { "<leader>cS", desc = "Review: summary" },
    { "<leader>cw", desc = "Review: save" },
    { "<leader>cr", desc = "Review: load" },
    { "<leader>co", desc = "Review: open comment list" },
    { "<leader>cg", desc = "Review: goto real file" },
    { "]r", desc = "Review: next comment" },
    { "[r", desc = "Review: previous comment" },
  },
  config = function()
    require("quickfix-review").setup()
  end,
}
