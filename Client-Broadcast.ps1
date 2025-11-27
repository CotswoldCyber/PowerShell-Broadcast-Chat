
$serverIP = ""
$port = 12345
$hostname = $env:COMPUTERNAME


try {
    $client = [System.Net.Sockets.TcpClient]::new($serverIP, $port)
    $stream = $client.GetStream()

    $bytes = [System.Text.Encoding]::utf8.getbytes($hostname)
    $stream.write($bytes, 0, $bytes.Length)
    $stream.flush()

    [System.Console]::WriteLine("$($hostname) has connected to server on port $($port)")
    [System.Console]::WriteLine("Enter a message (or type 'quit' to exit)")

    # Background listener for incomming server broadcast messages
    Start-ThreadJob -ScriptBlock {
        param ($stream)

        $buffer = New-Object byte[] 65535

        try {
            while ($true) {
            $bytesRead = $stream.read($buffer, 0, $buffer.length)

            if ($bytesRead -eq 0) {
                break
            }

            $received = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)

            [System.Console]::WriteLine("`n[Server] $($received)`n")
            [System.Console]::Write("Enter message (or type 'quit' to exit): ")
                 }
        }
    catch {
        [System.Console]::WriteLine("Connection closed")
    }

} -ArgumentList $stream | Out-Null


while ($client.connected) {
    $msg = read-host "Enter message (or type 'quit' to exit)"

    if ($msg -eq 'quit') {
        break
    }

    $data = [System.Text.Encoding]::UTF8.GetBytes($msg)
    $stream.write($data, 0, $data.length)
    $stream.Flush()

    [System.Console]::writeline("Message sent to server: $($msg)")
}
 
}

catch {
    [system.Console]::WriteLine("client error: $_")
}

finally {
    try {$stream.Close()} catch {}
    try {$client.Close()} catch{}
    [System.Console]::WriteLine("Disconnected from server")
}