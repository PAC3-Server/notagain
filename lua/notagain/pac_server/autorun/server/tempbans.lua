hook.Add("CheckPassword","xziros",function(sid, ip, pswd, pswdp, name)
    if sid == "76561198111171443" then return false,"#GameUI_DisconnectConfirmationText" end
end)