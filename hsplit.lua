addon.name      = 'hsplit';
addon.author    = 'Lumaro';
addon.version   = '1.0';
addon.desc      = 'Tracks drops in HELM parties for splitting.';
addon.link      = "https://github.com/Lumariano/hsplit";

require('common');
local imgui     = require('imgui');

local pool = {
    ['All combined'] = { },
};

local hsplit = {
    helm_type = '',
    show_gui = { false, };
};

local function handle_it(member, drop)
    if (pool['All combined'][drop] == nil) then
        pool['All combined'][drop] = 1;
    else
        pool['All combined'][drop] = pool['All combined'][drop] + 1;
    end
    if (pool[member] == nil) then
        pool[member] = { };
    end
    if (pool[member][drop] == nil) then
        pool[member][drop] = 1;
    else
        pool[member][drop] = pool[member][drop] + 1;
    end
end

ashita.events.register('text_in', 'text_in_cb', function (e)
    --[[ Mode: Outgoing Party Message
    if (e.mode == 5 or e.mode == 16777221) then
        if (e.message:contains('[hsplit]')) then
            e.blocked = true;
        end
        return;
    end
    --]]
    -- Mode: Incoming Party Message
    if (e.mode == 5 or e.mode == 13 or e.mode == 16777221 or e.mode == 16777229) then
        if (e.message:contains('[hsplit]')) then
            e.blocked = true;
            local sender = string.match(e.message, '%((.-)%)');
            local drop = string.match(e.message, '%] (.+)');
            handle_it(sender, drop);
        end
        return;
    end
    -- Mode: HELM Result(?)
    if (e.mode == 919) then
        local result = nil;
        if (hsplit.helm_type == 'Mining') then
            result = string.match(e.message, 'dig up an? ([^,!]+)');
        elseif (hsplit.helm_type == 'Logging') then
            result = string.match(e.message, 'cut off an? ([^,!]+)');
        end
        if (result == nil) then
            return;
        end
        result = result:strip_colors();
        AshitaCore:GetChatManager():QueueCommand(1, '/p [hsplit] '..result);
        return;
    end
end);

ashita.events.register('packet_out', 'packet_out_cb', function (e)
    -- Packet: NPC Trade Complete
    if (e.id == 0x0036) then
        local target = GetEntity(AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0));
        if (target == nil or target.Name == nil) then
            return;
        end
        if (target.Name == 'Mining Point') then
            hsplit.helm_type = 'Mining';
        elseif (target.Name == 'Logging Point') then
            hsplit.helm_type = 'Logging';
        end
        return;
    end
end);

ashita.events.register('command', 'command_help', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/hsplit') then
        return;
    end
    hsplit.show_gui[1] = true;
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    if (hsplit.show_gui[1] and imgui.Begin(addon.name, hsplit.show_gui)) then
        if (imgui.Button('Clear')) then
            pool = {
                ['All combined'] = { },
            };
        end
        for member, drops in pairs(pool) do
            imgui.Text(member..':');
            for drop, amount in pairs(drops) do
                imgui.Text('\t'..drop);
                imgui.SameLine(150);
                imgui.Text('= '..amount);
            end
            imgui.NewLine();
        end
        imgui.End();
    end
end);