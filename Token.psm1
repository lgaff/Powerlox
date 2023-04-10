Enum TokenType {
    # Single-character tokens
    LEFT_PAREN 
    RIGHT_PAREN 
    LEFT_BRACE
    RIGHT_BRACE
    COMMA 
    DOT 
    MINUS 
    PLUS
    SEMICOLON 
    SLASH 
    STAR
    # One or two character tokens
    BANG
    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LESS
    LESS_EQUAL
    # Literals
    IDENTIFIER
    STRING
    NUMBER
    # Keywords
    AND
    CLASS
    ELSE
    FALSE
    FUN
    FOR
    IF
    NIL
    OR
    PRINT
    RETURN
    SUPER
    THIS
    TRUE
    VAR
    WHILE
    # Source terminator
    EOF
}

Class Token
{
    Hidden [TokenType] $Type
    Hidden [String] $Lexeme
    Hidden [PSObject] $Literal
    Hidden [Int] $Line

    Token([TokenType] $Type, [String] $Lexeme, [PSObject] $Literal, [Int] $Line)
    {
        $this.Type = $Type
        $this.Lexeme = $Lexeme
        $this.Literal = $Literal
        $this.Line = $Line
        Write-Host "$($this.Type.ToString()) " -NoNewLine
        If ($null -ne $this.Literal) { Write-Host "[$($this.Literal)]" } Else { Write-Host ""}
    }

    [String] ToString ()
    {
        Return "$($this.Type) $($this.Lexeme) $($this.Literal)"
    }
}