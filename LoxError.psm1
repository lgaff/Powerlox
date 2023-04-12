Using Module '.\Token.psm1'
class LoxError {
    
    # Singleton stuff up front. This is intended to be a global
    # Logger to get around the ban on circular references in Powershell
    # that prevents me from playing the Java source for jlox straight.

    hidden static [LoxError] $_instance = [LoxError]::new()
    static [LoxError] $Instance = [LoxError]::GetInstance()

    [Guid] $LoxErrorTarget = [Guid]::NewGuid()

    hidden LoxError() {
    }

    hidden static [LoxError] GetInstance() {
        return [LoxError]::_instance
    }

    Hidden [Boolean] $HadError = $false
    [Boolean] HadError() { Return $this.HadError }
    [Void] SetError() { $this.HadError = $true }
    [Void] ClearError() { $this.HadError = $false }
    
    [Void] Error([Token] $token, [String] $message)
    {
        If ($token.Type -Eq [TokenType]::EOF) { $this.Report($token.Line, " at end", $message) }
        Else { $this.Report($token.Line, " at '$($token.Lexeme)'", $message) }
    }

    [Void] Error([Int] $Line, [String] $Message)
    {   
        $this.Report($Line, "", $Message)
    }

    Hidden [Void] Report([Int] $Line, [String] $Where, [String] $Message)
    {
        [Console]::Error.WriteLine("[Line $Line] Error ${Where}: $Message")
        $this.SetError()
    }
}

class ParseError : System.Management.Automation.RuntimeException { }