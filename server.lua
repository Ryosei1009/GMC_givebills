local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add("giveblackmoney", "マークされたお金を付与 (Admin Only)", {{name = "id", help = "プレイヤーのID"}, {name = "amount", help = "金額"}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])

    if not targetId or not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', source, "無効な引数です。使用方法: /giveblackmoney [id] [amount]", "error")
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        Player.Functions.AddItem("markedbills", 1, false, {worth = amount})
        TriggerClientEvent('QBCore:Notify', source, "ID " .. targetId .. " に $" .. amount .. " のマークされたお金を付与しました。", "success")
        TriggerClientEvent('QBCore:Notify', targetId, "あなたは $" .. amount .. " のマークされたお金を受け取りました。", "success")
    else
        TriggerClientEvent('QBCore:Notify', source, "指定されたIDのプレイヤーが見つかりません。", "error")
    end
end, "admin")

QBCore.Commands.Add("givebills", "補填用のお金を付与 (Admin Only)", {{name = "id", help = "プレイヤーのID"}, {name = "amount", help = "金額"}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])

    if not targetId or not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', source, "無効な引数です。使用方法: /givebills [id] [amount]", "error")
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        Player.Functions.AddItem("compensatingbills", 1, false, {worth = amount})
        TriggerClientEvent('QBCore:Notify', source, "ID " .. targetId .. " に $" .. amount .. " の補填用のお金を付与しました。", "success")
        TriggerClientEvent('QBCore:Notify', targetId, "あなたは $" .. amount .. " の補填用のお金を受け取りました。", "success")
    else
        TriggerClientEvent('QBCore:Notify', source, "指定されたIDのプレイヤーが見つかりません。", "error")
    end
end, "admin")


QBCore.Functions.CreateUseableItem("compensatingbills", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        -- ox_inventoryではmetadataを使用、従来のインベントリではinfoを使用
        local itemData = item.metadata or item.info or {}
        local billAmount = itemData.worth or 0
        
        if billAmount > 0 then
            Player.Functions.AddMoney("cash", billAmount, "compensatingbills-used")

            local found = false
            for _, invItem in pairs(Player.PlayerData.items) do
                if invItem.name == "compensatingbills" then
                    local invItemData = invItem.metadata or invItem.info or {}
                    if invItemData.worth == billAmount then
                        Player.Functions.RemoveItem('compensatingbills', 1, invItem.slot)
                        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['pdmarkedbills'], "remove")
                        found = true
                        break
                    end
                end
            end

            if found then
                TriggerClientEvent('QBCore:Notify', source, billAmount.."円が追加されました。", "success")
                local message = {
                    username = "補填用のお金変換監視君",
                    embeds = {{
                        title = "補填用のお金 -> 現金",
                        description = string.format("アイテム: 現金\n金額: %s\nプレイヤー: %s", billAmount, Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname),
                        color = 16776960,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                }
                PerformHttpRequest("https://discord.com/api/webhooks/1322801409543901235/4EmGHGXwsSE54G1keFVqbxUPldKafOy5dBlyhN1ah3sCeMoAfsxQh8CokvnMUYXpjACl", function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
            else
                TriggerClientEvent('QBCore:Notify', source, "値段が一致する補填用のお金が見つかりませんでした。", "error")
            end
        else
            TriggerClientEvent('QBCore:Notify', source, "これらの補填用のお金には価値がありません。", "error")
        end
    end
end)