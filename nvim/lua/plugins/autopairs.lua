-- Auto-pairs: close brackets/quotes as you type, skip over and delete pairs
-- (windwp/nvim-autopairs). blink.cmp's auto_brackets only fires when
-- accepting a completion item; this covers pairing while typing itself.
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {},
}
