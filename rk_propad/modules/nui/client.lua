--- Not recommended to edit this file as it can fully break the script!
--- This file is not supported if modified. Proceed with edits at your own discretion.
--- Copyright (c) 2025 rk.dev - @9zku - All rights reserved.

---@diagnostic disable: duplicate-set-field, lowercase-global

---@class nui
nui = {}

---Sends a message to the NUI frontend.
---@param action string The action name to send.
---@param data any The associated data to send.
function nui:msg(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

---Custom function to register a callback for a nui msg
---@param name string The name of the callback to register.
---@param cb fun(data: any, cb_: fun(response: any): void) The function to execute when the NUI message is received.
function nui:cb(name, cb)
    RegisterNUICallback(name, function(data, cb_)
        cb(data, cb_)
    end)
end

return nui