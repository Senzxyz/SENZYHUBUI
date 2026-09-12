VerifyBtn.MouseButton1Click:Connect(function()
        local inputKey = TextBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        
        if inputKey == "" then
            VerifyBtn.Text = "Enter a key first!"
            task.wait(1.5)
            VerifyBtn.Text = "Verify Key"
            return
        end

        VerifyBtn.Text = "Checking..."
        print("[KeySystem] Verifying key:", inputKey)

        -- ใช้ฟังก์ชัน request ของตัวรันสคริปต์โดยตรง
        local req = (syn and syn.request) or (http_request) or (request)
        
        if not req then
            VerifyBtn.Text = "Executor not supported!"
            warn("[KeySystem] Error: Your executor does not support HTTP requests.")
            task.wait(2)
            VerifyBtn.Text = "Verify Key"
            return
        end

        local success, response = pcall(function()
            return req({
                Url = supabaseUrl .. "/rest/v1/keys?key_string=eq." .. inputKey .. "&select=*",
                Method = "GET",
                Headers = {
                    ["apikey"] = supabaseKey,
                    ["Authorization"] = "Bearer " .. supabaseKey,
                    ["Content-Type"] = "application/json"
                }
            })
        end)

        if success and response and (response.StatusCode == 200 or response.status_code == 200) then
            local body = response.Body or response.body
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)

            if decodeSuccess and data and #data > 0 then
                VerifyBtn.Text = "Success!"
                print("[KeySystem] Key Valid! Loading script...")
                task.wait(0.5)
                ScreenGui:Destroy()
                successCallback()
            else
                VerifyBtn.Text = "Invalid Key!"
                print("[KeySystem] Key not found or incorrect.")
                task.wait(1.5)
                VerifyBtn.Text = "Verify Key"
            end
        else
            VerifyBtn.Text = "Connection Error!"
            warn("[KeySystem] Connection Failed. Response:", tostring(response))
            task.wait(1.5)
            VerifyBtn.Text = "Verify Key"
        end
    end)
