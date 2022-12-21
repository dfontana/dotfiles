local status_ok, impatient = pcall(require, "impatient")
if not status_ok then
  return
end
-- TODO: this can be dropped with Lazy.nvim
impatient.enable_profile()
