Class Lox {
    Hidden [Boolean] $HadError = $False

    [Void] Prompt ()
    {
        For (;;)
        {
            [String] $Line = Read-Host -Prompt "Lox> "
            IF ($null -eq $Line) { Break }
            Run($Line)
            $this.HadError = $False
        }
    }

    [Void] File ([System.IO.FileInfo] $File)
    {
        $Source = [IO.File]::ReadAllText($File)
        Run($Source)
        If ($This.HadError) { Exit(65) }
    }

    Hidden [Void] Run ([String] $Source)
    {
        [Scanner] $Scanner = [Scanner]::new($Source)
        [System.Collections.Generic.List[Token]] $Tokens = $scanner.ScanTokens()

        ForEach ($Token in $Tokens) 
        {
            Write-Output $Token
        }
    }

    Static [Void] Error([Int] $Line, [String] $Message)
    {
        Report($Line, "", $Message)
    }

    Hidden [Void] Report([Int] $Line, [String] $Where, [String] $Message)
    {
        Write-Error "[Line $Line] Error ${Where}: $Message"
        $This.HadError = $true
    }
}
