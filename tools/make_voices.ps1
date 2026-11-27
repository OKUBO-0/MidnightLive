Add-Type -AssemblyName System.Speech
$speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
$lines = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../docs/generated/dialogues.json') -Raw | ConvertFrom-Json
try {
    foreach ($line in $lines) {
        $target = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ('../assets/' + $line.file)))
        $speech.SelectVoice($line.voice)
        $speech.Rate = $line.rate
        $speech.Volume = 80
        $speech.SetOutputToWaveFile($target)
        $speech.Speak($line.text)
        $speech.SetOutputToNull()
    }
    Write-Output ('Generated {0} Japanese synthesized voice lines' -f $lines.Count)
} finally {
    $speech.Dispose()
}
