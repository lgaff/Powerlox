Using Module ".\Lox.psm1"

[String] $TestData  = @"
3 == 2 + 1
"@
Write-Host $TestData

$lox = New-Object -Type Lox

$lox.Run($TestData)

Exit