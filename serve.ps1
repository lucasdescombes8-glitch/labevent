# Simple HTTP server for LabEvent (no Node.js required)
$port = 3741
$root = $PSScriptRoot

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "LabEvent running at http://localhost:$port/"

while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response
    try {
        $local = $req.Url.LocalPath
        if ($local -eq '/' -or $local -eq '') { $local = '/index.html' }
        $file = Join-Path $root ($local.TrimStart('/').Replace('/', '\'))
        if (Test-Path $file -PathType Leaf) {
            $ext = [IO.Path]::GetExtension($file).ToLower()
            $resp.ContentType = switch ($ext) {
                '.html' { 'text/html; charset=utf-8' }
                '.css'  { 'text/css' }
                '.js'   { 'application/javascript' }
                '.json' { 'application/json' }
                default { 'application/octet-stream' }
            }
            $bytes = [IO.File]::ReadAllBytes($file)
            $resp.ContentLength64 = $bytes.Length
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $resp.StatusCode = 404
        }
    } catch { $resp.StatusCode = 500 }
    finally  { $resp.Close() }
}
