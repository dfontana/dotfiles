vim.cmd[[let g:VM_leader = '<Leader>']]
vim.cmd[[let g:VM_default_mappings = 0]]
vim.cmd([[
  let g:VM_maps = {}
  let g:VM_maps["Add Cursor Down"] = '<S-Down>'
  let g:VM_maps["Add Cursor Up"] = '<S-Up>'
  let g:VM_maps["Mouse Cursor"]  = '<C-LeftMouse>' 
  
  let g:VM_maps["Switch Mode"]                 = '<Tab>'
  
  let g:VM_maps["Find Next"]                   = ''
  let g:VM_maps["Find Prev"]                   = '' 
  let g:VM_maps["Goto Next"]                   = '' 
  let g:VM_maps["Goto Prev"]                   = '' 
  let g:VM_maps["Seek Next"]                   = ''
  let g:VM_maps["Seek Prev"]                   = ''
  let g:VM_maps["Skip Region"]                 = ''
  let g:VM_maps["Remove Region"]               = ''
  let g:VM_maps["Invert Direction"]            = ''
  let g:VM_maps["Find Operator"]               = ''
  let g:VM_maps["Surround"]                    = ''
  let g:VM_maps["Replace Pattern"]             = ''
  
  let g:VM_maps["Tools Menu"]                  = ''
  let g:VM_maps["Show Registers"]              = ''
  let g:VM_maps["Case Setting"]                = ''
  let g:VM_maps["Toggle Whole Word"]           = ''
  let g:VM_maps["Transpose"]                   = ''
  let g:VM_maps["Align"]                       = ''
  let g:VM_maps["Duplicate"]                   = ''
  let g:VM_maps["Rewrite Last Search"]         = ''
  let g:VM_maps["Merge Regions"]               = ''
  let g:VM_maps["Split Regions"]               = ''
  let g:VM_maps["Remove Last Region"]          = ''
  let g:VM_maps["Visual Subtract"]             = ''
  let g:VM_maps["Case Conversion Menu"]        = ''
  let g:VM_maps["Search Menu"]                 = ''
     
  let g:VM_maps["Run Normal"]                  = ''
  let g:VM_maps["Run Last Normal"]             = ''
  let g:VM_maps["Run Visual"]                  = ''
  let g:VM_maps["Run Last Visual"]             = ''
  let g:VM_maps["Run Ex"]                      = ''
  let g:VM_maps["Run Last Ex"]                 = ''
  let g:VM_maps["Run Macro"]                   = ''
  let g:VM_maps["Align Char"]                  = ''
  let g:VM_maps["Align Regex"]                 = ''
  let g:VM_maps["Numbers"]                     = ''
  let g:VM_maps["Numbers Append"]              = ''
  let g:VM_maps["Zero Numbers"]                = ''
  let g:VM_maps["Zero Numbers Append"]         = ''
  let g:VM_maps["Shrink"]                      = ''
  let g:VM_maps["Enlarge"]                     = ''
     
  let g:VM_maps["Toggle Block"]                = ''
  let g:VM_maps["Toggle Single Region"]        = ''
  let g:VM_maps["Toggle Multiline"]            = ''
]])  

