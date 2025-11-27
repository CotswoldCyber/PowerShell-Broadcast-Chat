
$serverIP = ""
$port = 12345
$hostname = $env:COMPUTERNAME


$clients = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)

$listener = New-Object System.Net.Sockets.TcpListener($serverIP, $port)
$listener.Start()

[System.Console]::writeLine("Server listening on port $($port) for incoming connections...")

# Accept clients in background thread
Start-ThreadJob -ScriptBlock {
    param ($listener, $clients)

    while ($true) {
        try {
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $ip = $client.Client.RemoteEndPoint.ToString()

            # Get the hostname of the connecting client
            $buffer = New-Object byte[] 65536
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            $hostname = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()

            $clientInfo = [pscustomobject]@{
                HostName = $hostname
                Client   = $client
                Stream   = $stream
                IP       = $ip
            }

            $clients.TryAdd($hostname, $clientInfo) | Out-Null
            [system.console]::WriteLine("`r`n[+] Client connected $hostname from $ip")
            #[System.Console]::WriteLine("Enter your message (or type '/help' for menu or 'quit' to exit'): ")

            # Listen for messages from this connected client
            Start-ThreadJob -ScriptBlock {
                param($hostname,$ip, $clients, $client, $stream)

                $buffer = New-Object byte[] 65535

                try {
                    while ($client.Connected) {
                        $n = $stream.Read($buffer, 0, $buffer.Length)
                        if ($n -eq 0) { break }

                        $msg = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $n).Trim()

                        if ($msg -eq 'whoami') {
                            $response = "You are $($hostname) from $($ip)"
                            $reply = [System.Text.Encoding]::utf8.getbytes($response)
                            $stream.write($reply, 0, $reply.Length)
                            $stream.Flush()
                            continue 
                        }

                        [System.console]::WriteLine("[$hostname] $msg")
                    }
                }
                catch {
                    [system.console]::WriteLine("[$($hostname)] Disconnected from server")
                }
                finally {
                    try { $stream.Close() } catch {}
                    try { $client.Close() } catch {}
                    $clients.TryRemove($hostname, [ref]$null) | Out-Null
                    [System.Console]::WriteLine("`r`n[-] Client $hostname disconnected")
                }

            } -ArgumentList $hostname, $ip, $clients, $client, $stream | Out-Null
        }
        catch {
        if ($_.Exception.Message -like "*WSACancelBlockingCall*" -or $_.Exception.Message -like "*Not listening*") {
            break  # gracefull exit
        }
            [System.Console]::WriteLine("Accept error: $_")
            Start-Sleep -Seconds 1
        }
    }
} -ArgumentList $listener, $clients | Out-Null   # closes the outer job block cleanly


# Broadcast function
function Send-Broadcast {
    param ([string]$message)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)

    foreach ($key in @($clients.Keys)) {
        $clientInfo = $null

        if ($clients.TryGetValue($key, [ref]$clientInfo)) {
            $stream = $clientInfo.stream
            try {
                if ($stream -and $stream.CanWrite) {
                    $stream.Write($bytes, 0, $bytes.Length)
                    $stream.Flush()
                    [system.console]::WriteLine("Sent broadcast message to $($clientInfo.HostName)")
                }
            }
            catch {
                [System.Console]::WriteLine("Failed to send broadcast message to $($clientInfo.HostName)")
            }
        }
    }
}

function Send-PrivateMessage {
    param (
        [string]$TargetHost,
        [string]$message
    )

    $clientInfo = $null

    if ($clients.TryGetValue($TargetHost, [ref]$clientInfo)) {

            $stream = $clientInfo.stream

            if ($stream -and $stream.CanWrite) {

                try {
                $bytes = [System.Text.Encoding]::utf8.getbytes("[Private message from server] $($message)")
                $stream.write($bytes, 0, $bytes.Length)
                $stream.flush()
    
    }

        catch{
            [System.Console]::writeLine("Failed to send private message to $($TargetHost)")
     }
            }
            
        else {
            [System.Console]::writeLine("Stream not writable for $($TargetHost)")
    }
}
    else {
        [System.Console]::writeLine("No such client $($TargetHost)")
    }
}

function Kick-Client {
    param (
        [string]$hostname
    )

    $clientInfo = $null

    if ($clients.TryGetValue($hostname, [ref]$clientInfo)) {

        try {
            $stream = $clientInfo.stream

            $bytes = [System.Text.Encoding]::utf8.getbytes("You have been disconnected by the Administrator")
            $stream.write($bytes, 0, $bytes.length)
            $stream.flush()

            if ($clientInfo.stream) {
                try {$clientInfo.stream.close()} catch {} 
            }

            if ($clientInfo.client) {
                try {$clientInfo.client.close()} catch {}
            }

            $clients.TryRemove($hostname, [ref]$null) | Out-Null
            [System.Console]::writeLine("$($hostname) was kicked and disconnected")
        }

        catch {
            [System.Console]::writeLine("Error kicking $($hostname): $_")
        }
    }

    else {
        [System.Console]::writeLine("No such client: $($hostname)")
    }
}


function Shutdown-Server {
    [System.Console]::writeline("Broadcasting shutdown message to all clients...")

    $bytes = [System.Text.Encoding]::utf8.getbytes("Server is shutting down. You will be disconnected")

    foreach ($key in @($clients.Keys)) {
        $clientInfo = $null

        if ($clients.TryGetValue($key, [ref]$clientInfo)) {
            $stream = $clientInfo.stream
        try {
        if ($stream -and $stream.CanWrite) {
            $stream.write($bytes, 0, $bytes.length)
            $stream.Flush()
        }

        $stream.close()
        $clientInfo.client.close()
        }
        catch {
            [System.Console]::writeline("Error disconnecting: $($clientInfo.hostname)")
        }
        $clients.TryRemove($key, [ref]$null) | out-null
        }
    }

    Start-Sleep -Milliseconds 300
    [System.Console]::writeline("All clients disconnected")
    Start-Sleep -Seconds 1   # gives clients time to print the shutdown message

    $listener.stop()
    [System.Console]::writeline("Server stopped.")
}

while ($true) {

    $msg = Read-Host "Enter your message (or type '/help' for menu or 'quit' to exit)"

    if ($msg -eq 'quit') {
        $listener.stop()
        [System.Console]::writeline("Server stopped.")
        break
    }

    
    switch -Regex ($msg) {
        '^/msg\s+(\S+)\s+(.+)$' {
            $target = $Matches[1]
            $privatemessage = $Matches[2]
            Send-PrivateMessage -TargetHost $target -message $privatemessage
        }

        '^/kick\s+(\S+)$' {
            $target = $Matches[1]
            Kick-Client $target
        }

        '^/list$' {
            [System.Console]::writeline("Connected clients:") 
            foreach ($key in @($clients.Keys)) {
                [console]::writeLine(" - [$key]")
            }
        }

        '^/whoami$' {
            [System.Console]::writeLine("You are the server operator $($env:COMPUTERNAME). This command is typically used by clients")
        }

        '^/shutdown$' { Shutdown-Server
                        break
        }

        '^/help' {
            [System.Console]::WriteLine("Availiable commands:")
            [System.Console]::WriteLine(" - /list                 : Show connected clients")
            [System.Console]::WriteLine(" - /msg <host> <message> : Send private message")
            [System.Console]::WriteLine(" - /kick <host>          : Disconnect a client")
            [System.Console]::WriteLine(" - /whoami               : Show server identity")
            [System.Console]::Writeine(" - /shutdown             : Disconnect all clients and shut down the server")
            [System.Console]::WriteLine(" - quit                  : Stop the server")
        }


        default {
            [System.Console]::WriteLine("Active connections")

            if ($clients.Count -eq 0) {
                [System.Console]::WriteLine("No active connections")
             }   

            else {
                foreach ($key in @($clients.Keys)) {
                    [System.Console]::WriteLine("[$key]")
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($msg)) {
                    Send-Broadcast $msg
                }
            }
        }
    }

