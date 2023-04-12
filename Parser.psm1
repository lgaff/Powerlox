Using Module '.\Token.psm1'
Using Module '.\Expr.psm1'
Using Module '.\LoxError.psm1'

class Parser
{
    Hidden [System.Collections.Generic.List[Token]] $tokens
    Hidden [Int] $current = 0

    Parser([System.Collections.Generic.List[Token]] $tokens) { $this.tokens = $tokens }

    Hidden [Boolean] Match([TokenType[]] $types)
    {
        If($this.Check($types)) { $this.Advance(); Return $true }
        Return $false
    }
        
    Hidden [Boolean] IsAtEnd() { Return $this.Peek().Type -Eq [TokenType]::EOF }
    Hidden [Token] Advance() { If (!$this.IsAtEnd()) { $this.current++ }; Return $this.Previous() }
    Hidden [Token] Peek() { Return $this.tokens[$this.current] } 
    Hidden [Token] Previous() { Return $this.tokens[$this.current-1] }
    Hidden [Boolean] Check([TokenType] $type) { Return -Not $this.IsAtEnd() -And $($this.Peek().Type) -Eq $type }
    Hidden [Boolean] Check([TokenType[]] $types) { Return -Not $this.IsAtEnd() -And $this.Peek().Type -In $types }

    [Expr] Parse()
    {
        Try
        {
            Return $this.Expression()
        }
        Catch [ParseError]
        {
            Return $null
        }
    }
    Hidden [Expr] Expression() { Return $this.Equality() }

    Hidden [Expr] Equality()
    {
        [Expr] $expr = $this.Comparison()

        While ($this.Match(([TokenType]::BANG_EQUAL, [TokenType]::EQUAL_EQUAL)))
        {
            [Token] $operator = $this.Previous()
            [Expr] $right = $this.Comparison()
            $expr = [Binary]::new($expr, $operator, $right)
        } 
        Return $expr
    }

    Hidden [Expr] Term() 
    {
        [Expr] $expr = $this.Factor()

        While ($this.Match(("MINUS", "PLUS")))
        {
            [Token] $operator = $this.Previous()
            [Expr] $right = $this.Unary()
            $expr = [Binary]::new($expr, $operator, $right)
        } 
        Return $expr
    }

    Hidden [Expr] Comparison()
    { 
        [Expr] $expr = $this.Term()
        While ($this.Match(("GREATER", "GREATER_EQUAL", "LESS", "LESS_EQUAL")))
        {
            [Token] $operator = $this.Previous()
            [Expr] $right = $this.Term()
            $expr = [Binary]::new($expr, $operator, $right)
        }
        Return $expr 
    }



    Hidden [Expr] Factor()
    { 
        [Expr] $expr = $this.Unary()

        While ($this.Match(("SLASH", "STAR")))
        {
            [Token] $operator = $this.Previous()
            [Expr] $right = $this.Unary()
            $expr = [Binary]::new($expr, $operator, $right)
        }
 
        Return $expr
    }

    Hidden [Expr] Unary()
    { 
        If ($this.Match(("BANG", "MINUS")))
        { 
            [Token] $operator = $this.Previous()
            [Expr] $right = $this.Unary()
            Return [Unary]::New($operator, $right)
        } 
        Return $this.Primary()
    }

    Hidden [Expr] Primary()
    { 
        If($this.Match(("FALSE"))) { Return [Literal]::New($false) }
        If($this.Match(("TRUE"))) { Return [Literal]::New($true) }
        If($this.Match(("NIL"))) { Return [Literal]::New($null) }
        If($this.Match(("NUMBER", "STRING"))) { Return [Literal]::New($this.Previous().Literal) }
        If($this.Match(("LEFT_PAREN")))
        {
            [Expr] $expr = $this.Expression()
            $this.Consume("RIGHT_PAREN", "Expect ')' after expression.")
            Return [Grouping]::New($expr)
        } 
        Throw $this.Error($this.Peek(), "Expect expression.")
    }

    Hidden [Token] Consume([TokenType] $type, [String]$message)
    {
        If ($this.Check($type)) { Return $this.Advance() }
        Throw $this.Error($this.Peek(), $message)
    }

    Hidden [ParseError] Error([Token] $token, [String] $message)
    {
        [LoxError]::Error($token, $message)
        Return [ParseError]::new()
    }

    Hidden [Void] Synchronise()
    {
        $this.Advance()

        While (-Not $this.IsAtEnd())
        {
            If ($this.Previous().Type -eq [TokenType]::SEMICOLON -Or `
               $this.Peek().Type -In ("CLASS", "FUN", "FOR", "VAR", "IF", "WHILE", "PRINT", "RETURN")) { Return }
        }
        $this.Advance()
    }
}