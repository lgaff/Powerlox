param (
    [System.IO.FileInfo]$Output = ".\"
)


Function Expand-Type
{
    Param
    (
        [String]$BaseName,
        [String]$Name,
        [System.Collections.Specialized.OrderedDictionary]$Fields
    )
    Write-Host "$Name Fields [$($Fields.Keys)] $($Fields.GetType())" #.GetType()
    $ConstructorParameters = $($Fields.GetEnumerator() | ForEach-Object { "[$($_.Value)] `$$($_.Key)" } | Join-String -Separator ", ")
    Write-Host $ConstructorParameters
    @"
Class ${Name} : ${BaseName}
{
    $($Fields.GetEnumerator() | Foreach-Object { "[$($_.Value)] `$$($_.Key)"} | Join-String -Separator "`n    ")
    
    ${Name} ($ConstructorParameters)
    {
        $($Fields.Keys | Foreach-Object { "`$this.$_ = `$$_"} | Join-String -Separator "`n        ")
    }

    [PSObject] Accept([${BaseName}Visitor] `$visitor) { Return `$visitor.Visit(`$this) }
}
"@
}

Function Expand-Visitor
{
    # Powershell currently has no mechanism for defining interfaces outside the standard PSH libraries,
    # It also has no support for abstract classes or generics.
    # This is as close to equivalent semantics for an AST as defined in CI as I think I can get
    # with such ill-equipped tools.
    Param
    (
        [String] $BaseName,
        [String] $Type
    )
    "[${BaseName}] Visit([${Type}] `$$($Type.ToLower())) { Return `$null }"
}
Function Write-Ast { # Modified from DefineAst to use PSH approved verbiage
    Param  
    (
        [String] $OutFolder, 
        [String] $BaseName, 
        [hashtable] $Types
    )

    $path = "${OutFolder}\$baseName`.psm1"
    Write-Host $path
    $Visitors = $($Types.GetEnumerator() | ForEach-Object { $(Expand-Visitor -BaseName $BaseName -Type $($_.Key))} | Join-String -Separator "`n    ")
    $SubClasses = $($Types.GetEnumerator() | ForEach-Object { $(Expand-Type -BaseName $BaseName -Name $($_.Key) -Fields $($_.Value)) } | Join-String -Separator "`n`n")
    @"
Using Module ".\Token.psm1"

Class ${BaseName}Visitor 
{
    # Psh has no (ability to define new) interfaces, or generics; this is as good as we're going to get I think
    $Visitors
}

Class ${baseName} 
{
    [Void] Accept() { 0 }
}
$SubClasses
"@ | Out-File -Path $path -Encoding utf8
}

$TypesMap = @{
    "Unary" = [Ordered]@{ "Operator" = "Token"; "Right" = "Expr" }
    "Binary" =  [Ordered]@{"Left" = "Expr"; "Operator" = "Token"; "Right" = "Expr"}
    "Grouping" =  [Ordered]@{"Expression" = "Expr"}
    "Literal" = [Ordered]@{"Value" = "PSObject" }
    
}

Write-Ast -OutFolder $Output -baseName "Expr" `
    -types $TypesMap
