local l_status_ok, neodev = pcall(require, "neodev")
if not l_status_ok then
  return
end

neodev.setup({})
