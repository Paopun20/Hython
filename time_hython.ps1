function Measure-Avg {
    param($Label, $Cmd, $Runs = 5)
    $times = @()
    for ($i = 0; $i -lt $Runs; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & $Cmd[0] $Cmd[1..($Cmd.Length-1)]
        $sw.Stop()
        $times += $sw.ElapsedMilliseconds
    }
    $avg = ($times | Measure-Object -Average).Average
    Write-Output "$Label avg over $Runs runs: $([math]::Round($avg, 1)) ms  (runs: $($times -join ', ') ms)"
}

Measure-Avg "Hython" @('E:\Hython\bin\build\cpp\Main.exe', 'E:\Hython\pytest\test_loop.py')
Measure-Avg "Python"  @('python', 'E:\Hython\pytest\test_loop.py')