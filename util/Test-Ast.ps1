Using Module '..\Token.psm1'
Using Module '..\Expr.psm1'

Class AstPrinter : ExprVisitor
{
    [String] Print([Expr] $expr) { Return $expr.Accept($this) }

    [String] Visit([Binary] $expr) { Return $this.Parenthesize($expr.Operator.Lexeme, ($expr.Left, $expr.Right)) }
    [String] Visit([Grouping] $expr) { Return $this.Parenthesize("Group", $expr.Expression) }
    [String] Visit([Literal] $expr) 
    {
        If ($null -Eq $expr.Value) { Return "nil" }
        Return $expr.Value#.ToString()
    }
    [String] Visit([Unary] $expr) { Return $this.Parenthesize($expr.Operator.Lexeme, $expr.Right)}

    Hidden [String] Parenthesize([String]$Name, [Expr[]]$exprs)
    {
        Return "($Name $(ForEach ($expr in $exprs) { "$($expr.Accept($this))" }))"
    }
}

[Expr] $TestExpr = [Binary]::new(
    [Unary]::New(
        [Token]::New([TokenType]::MINUS, "-", $null, 1),
        [Literal]::New(123)),
    [Token]::New([TokenType]::STAR, "*", $null, 1),
    [Grouping]::New(
        [Literal]::New(45.67)))

$astprinter = New-Object -Type AstPrinter
Write-Host $astprinter.Print($TestExpr)