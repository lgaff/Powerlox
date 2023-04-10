Using Module '.\Token.psm1'
Using Module '.\LoxError.psm1'

Class Scanner
{
    Hidden [String] $Source
    Hidden [System.Collections.Generic.List[Token]] $Tokens
    Hidden [Int] $Start = 0
    Hidden [Int] $Current = 0
    Hidden [Int] $Line = 1

    Hidden [HashTable] $KeywordMap = @{
        "and" = [TokenType]::AND
        "class" = [TokenType]::CLASS
        "else" = [TokenType]::ELSE
        "false" = [TokenType]::FALSE
        "for" = [TokenType]::FOR
        "if" = [TokenType]::IF
        "nil" = [TokenType]::NIL
        "or" = [TokenType]::OR
        "print" = [TokenType]::PRINT
        "return" = [TokenType]::RETURN
        "super" = [TokenType]::SUPER
        "this" = [TokenType]::THIS
        "true" = [TokenType]::TRUE
        "var" = [TokenType]::VAR
        "while" = [TokenType]::WHILE
    }

    Scanner([String] $Source)
    {
        $this.Source = $Source
        $this.Tokens = New-Object System.Collections.Generic.List[Token]
    }

    [System.Collections.Generic.List[Token]] ScanTokens(){
        While (-Not $this.IsAtEnd())
        {
            $this.Start = $this.Current
            $This.ScanToken()
        }
        $this.Tokens.Add([Token]::New([TokenType]::EOF, "", $Null, $this.Line))
        Return $This.Tokens
    }

    Hidden [Boolean] Match([Char] $Expected)
    {
        If ($this.IsAtEnd()) { Return $false }
        If ($this.Source[$this.Current] -Ne $Expected) { Return $false }

        $this.Current++
        Return $true
    }

    Hidden [Boolean] IsAtEnd()
    {
        Return $this.Current -ge $this.Source.Length
    }

    Hidden [Char] Advance()
    {
        # Write-Host "Advance $($this.Current)"
        Return $this.Source[$This.Current++]
    }

    Hidden [Void] AddToken([TokenType] $Type, [PSObject] $Literal)
    {
        [String] $Text = $this.Source[$this.Start..$this.Current]
        $this.Tokens.Add([Token]::New($Type, $Text, $Literal, $this.Line))
    }

    Hidden [Void] AddToken($Type)
    {
        $this.AddToken($Type, $Null)
    }

    Hidden [Void] ScanToken()
    {
        [Char] $c = $this.Advance()
        #Write-Host "Scanning [$c] ($([Int][Char]$c))"
        Switch -Regex ($c)
        {
            "\(" { $this.AddToken([TokenType]::LEFT_PAREN); Break }
            "\)" { $this.AddToken([TokenType]::RIGHT_PAREN); Break}
            "{" { $this.AddToken([TokenType]::LEFT_BRACE); Break}
            "}" { $this.AddToken([TokenType]::RIGHT_BRACE); Break}
            "," { $this.AddToken([TokenType]::COMMA); Break}
            "\." { $this.AddToken([TokenType]::DOT); Break}
            "-" { $this.AddToken([TokenType]::MINUS); Break}
            "\+" { $this.AddToken([TokenType]::PLUS); Break}
            ";" { $this.AddToken([TokenType]::SEMICOLON); Break}
            "\*" { $this.AddToken([TokenType]::STAR); Break}
            # Double character lexemes
            "!" { $this.Match("=") ? $this.AddToken([TokenType]::BANG_EQUAL) : $this.AddToken([TokenType]::BANG); Break }
            "=" { $this.Match("=") ? $this.AddToken([TokenType]::EQUAL_EQUAL) : $this.AddToken([TokenType]::EQUAL); Break }
            "<" { $this.Match("=") ? $this.AddToken([TokenType]::LESS_EQUAL) : $this.AddToken([TokenType]::LESS); Break }
            ">" { $this.Match("=") ? $this.AddToken([TokenType]::GREATER_EQUAL) : $this.AddToken([TokenType]::GREATER); Break }
            "/" { 
                    If ($this.Match("/")) {
                        # Line comments
                        While ($this.Peek() -Ne "`n" -And -Not $this.IsAtEnd()) { $this.Advance() } # Gobble, gobble.
                    }
                    Else {
                        $this.AddToken([TokenType]::SLASH)
                    }
                    Break
            }
            " " { Break }
            "`r" { Break; }
            "`n" { $this.Line++; Break }
            "`t" { Break }
            "`"" { $this.String(); Break }
            "[0-9]" { $this.Number(); Break }
            "[a-zA-Z]" { $this.Identifier(); Break }
            Default { [LoxError]::Instance.Error($this.Line, "Unexpected Character."); Break }
        }
    }

    Hidden [Char] Peek() 
    {
        If ($this.IsAtEnd()) { Return "`0" }
        # Write-Host "Peek $($this.Current) [$($this.Source[$this.Current])]"
        Return $this.Source[$this.Current]
    }

    Hidden [Char] PeekNext()
    {
        If ($this.Current + 1 -ge $this.Source.Length ) { Return $null }
        Return $this.Source[$this.Current + 1]
    }

    Hidden [Void] String()
    {
        While ($this.Peek() -Ne '"' -And -Not $this.IsAtEnd())
        {
            If ($this.Peek() -eq "`n") { $this.Line++ }
            $this.Advance()
        }

        If ($this.IsAtEnd())
        {
            [LoxError]::Instance.Error($this.Line, "Unterminated String")
            Return
        }

        $this.Advance()
        $this.AddToken([TokenType]::STRING, $(-Join $this.Source[$this.Start..$this.Current]).Trim('"'))
    }

    Hidden [Void] Number() 
    {
        While ($this.Peek() -Match "[0-9]") { $this.Advance() }
        If ( $this.Peek() -eq '.'  -And $this.PeekNext() -Match "[0-9]" ) { $this.Advance() }
        While ($this.Peek() -Match "[0-9]") { $this.Advance() }
         $this.AddToken([TokenType]::NUMBER, [Double]$this.ExtractLexeme())
    }

    Hidden [Void] Identifier()
    {
        While ($this.Peek() -match "[0-9a-zA-Z_]") { $this.Advance() }
        $text = $this.ExtractLexeme()
        If ($this.KeywordMap.Keys -Contains $text) { $type = $this.KeywordMap[$text] }
        Else { $type = [TokenType]::IDENTIFIER }
        $this.AddToken($type, $text)
    }

    Hidden [String] ExtractLexeme()
    {
        Return $this.Source.SubString($this.Start, ($this.Current - $this.Start))
    }
}