# ==========================================

# TEDDY COMPILER v0.1 - BARE METAL EDITION

# ==========================================

# --- 1. THE DATA STRUCTURES (AST) ---

class Token {

\[string\]$Type; \[string\]$Value Token($t, $v) { $this.Type = $t; $this.Value = $v }
}

class AssignmentNode {

\[string\]$Target; \[string\]$Value; \[string\]$DataType AssignmentNode($t, $v, $d) { $this.Target = $t; $this.Value = $v; $this.DataType = $d }
}

class DereferenceNode {

\[string\]$Pointer; \[string\]$Value DereferenceNode($p, $v) { $this.Pointer = $p; $this.Value = $v }
}

class ReserveNode {

\[string\]$Target; \[int\]$Size ReserveNode($t, $s) { $this.Target = $t; $this.Size = $s }
}

class AsmNode {

\[string\]$Code AsmNode($c) { $this.Code = $c }
}

# --- 2. THE LEXER ---

function Invoke-TeddyLexer ([string]$SourceCode) {

$Tokens = \[System.Collections.Generic.List\[Token\]\]::new() \# Master Regex: Now includes memory suffixes (:b,:w,:d) and array offsets (@) $RegexPattern = '(?<Whitespace>^\\s+)|' + '(?<Comment>^#\[^\\r\\n\]\*)|' + '(?<Keyword>^(asm\\b|deref\\b|w\\/|res\\b))|' + '(?<Variable>^\[\\!\\^\]?\\$\[a-zA-Z\_\]\[a-zA-Z0-9\_\]\*(?:\\:\[bwd\])?(?:\\@\[0-9\]+)?)|' + '(?<HexNumber>^0x\[0-9a-fA-F\]+)|' + '(?<Number>^\[0-9\]+)|' + '(?<StringLiteral>^"\[^"\]\*")|' + '(?<Operator>^\\=)|' + '(?<Symbol>^\[\\;\\(\\)\\{\\}\])' while ($SourceCode.Length -gt 0) { if ($SourceCode -cmatch $RegexPattern) { if ($Matches.Keyword) { $Tokens.Add(\[Token\]::new("Keyword", $Matches.Keyword)) } if ($Matches.Variable) { $Tokens.Add(\[Token\]::new("Variable", $Matches.Variable)) } if ($Matches.HexNumber) { $Tokens.Add(\[Token\]::new("HexNumber", $Matches.HexNumber)) } if ($Matches.Number) { $Tokens.Add(\[Token\]::new("Number", $Matches.Number)) } if ($Matches.StringLiteral) { $Tokens.Add(\[Token\]::new("String", $Matches.StringLiteral)) } if ($Matches.Operator) { $Tokens.Add(\[Token\]::new("Operator", $Matches.Operator)) } if ($Matches.Symbol) { $Tokens.Add(\[Token\]::new("Symbol", $Matches.Symbol)) } $SourceCode = $SourceCode.Substring($Matches\[0\].Length) } else { Write-Error "Lexer Error near: '$($SourceCode.Substring(0,10))...'" break } } return $Tokens
}

# --- 3. THE PARSER ---

function Invoke-TeddyParser ($Tokens) {

$AST = \[System.Collections.Generic.List\[Object\]\]::new() $Pos = 0 $Peek = { if ($Pos -lt $Tokens.Count) { return $Tokens\[$Pos\] }; return $null } $Consume = { $Current = &$Peek; $Pos++; return $Current } while ($Pos -lt $Tokens.Count) { $Token = &$Peek \# Rule 1: Variable Assignment ($var = 0x10; or $var = "Hi";) if ($Token.Type -eq "Variable") { $Var = &$Consume $Op = &$Consume $Val = &$Consume $Semi = &$Consume if ($Op.Value -ne "=" -or $Semi.Value -ne ";") { Write-Error "Syntax Error: Assignment"; break } $AST.Add(\[AssignmentNode\]::new($Var.Value, $Val.Value, $Val.Type)) } \# Rule 2: Array Reservation (res $var w/ 10;) elseif ($Token.Type -eq "Keyword" -and $Token.Value -eq "res") { &$Consume # Eat 'res' $Var = &$Consume $W = &$Consume $Num = &$Consume $Semi = &$Consume if ($W.Value -ne "w/" -or $Semi.Value -ne ";") { Write-Error "Syntax Error: res"; break } $AST.Add(\[ReserveNode\]::new($Var.Value, \[int\]$Num.Value)) } \# Rule 3: Dereference (deref $var w/ 0x4B;) elseif ($Token.Type -eq "Keyword" -and $Token.Value -eq "deref") { &$Consume # Eat 'deref' $Var = &$Consume $W = &$Consume $Val = &$Consume $Semi = &$Consume if ($W.Value -ne "w/" -or $Semi.Value -ne ";") { Write-Error "Syntax Error: deref"; break } $AST.Add(\[DereferenceNode\]::new($Var.Value, $Val.Value)) } \# Rule 4: Inline ASM (asm { hlt }) elseif ($Token.Type -eq "Keyword" -and $Token.Value -eq "asm") { &$Consume # Eat 'asm' $OpenBracket = &$Consume $AsmCode = &$Consume # For V1, we assume the next variable/keyword is the raw ASM instruction $CloseBracket = &$Consume $AST.Add(\[AsmNode\]::new($AsmCode.Value)) } else { $Pos++ } # Skip unhandled tokens for now } return $AST
}

# --- 4. THE GENERATOR (BACKEND) ---

function Invoke-TeddyGenerator ($AST) {

$AsmOutput = \[System.Collections.Generic.List\[string\]\]::new() $DataSection = \[System.Collections.Generic.List\[string\]\]::new() $VariableMap = @{} # Tracks RAM variables so we don't declare them twice $AsmOutput.Add("; --- COMPILED BY TEDDY v0.1 ---") $AsmOutput.Add("\[BITS 16\]") $AsmOutput.Add("") foreach ($Node in $AST) { \# --- GENERATE: ASSIGNMENT --- if ($Node -is \[AssignmentNode\]) { \# Strip suffixes and prefixes to get the raw name $RawName = $Node.Target -replace '\[\\!\\^\\$\\:bwd\\@0-9\]', '' $CleanTarget = "var\_$RawName" \# Is it an array access? (e.g., $var@2) $Offset = 0 if ($Node.Target -match '\\@(\[0-9\]+)') { $Offset = $Matches\[1\] } \# Generate String Assignment if ($Node.DataType -eq "String") { $StringData = $Node.Value -replace '"', "'" # Convert "Hi" to 'Hi' $DataSection.Add("$CleanTarget: db $StringData, 0x00") } \# Generate Number Assignment else { \# Determine Assembly Size (byte, word, dword) $AsmSize = "word" if ($Node.Target -match '\\:b') { $AsmSize = "byte"; $DataSection.Add("$CleanTarget: db 0") } if ($Node.Target -match '\\:w') { $AsmSize = "word"; $DataSection.Add("$CleanTarget: dw 0") } if ($Node.Target -match '\\:d') { $AsmSize = "dword"; $DataSection.Add("$CleanTarget: dd 0") } if ($Offset -gt 0) { $AsmOutput.Add(" mov $AsmSize \[$CleanTarget + $Offset\], $($Node.Value)") } else { $AsmOutput.Add(" mov $AsmSize \[$CleanTarget\], $($Node.Value)") } } } \# --- GENERATE: DEREFERENCE --- elseif ($Node -is \[DereferenceNode\]) { $RawName = $Node.Pointer -replace '\[\\!\\^\\$\\:bwd\\@0-9\]', '' $AsmOutput.Add(" ; Dereferencing $RawName") $AsmOutput.Add(" mov bx, \[var\_$RawName\]") $AsmOutput.Add(" mov byte \[bx\], $($Node.Value)") } \# --- GENERATE: RESERVE (ARRAYS) --- elseif ($Node -is \[ReserveNode\]) { $RawName = $Node.Target -replace '\[\\!\\^\\$\\:bwd\\@0-9\]', '' $DataSection.Add("var\_$RawName: times $($Node.Size) db 0") } \# --- GENERATE: INLINE ASM --- elseif ($Node -is \[AsmNode\]) { $AsmOutput.Add(" $($Node.Code)") } } $AsmOutput.Add("") $AsmOutput.Add(" jmp \`$ ; End of Execution Hang") $AsmOutput.Add("") $AsmOutput.Add("; --- RAM DATA SECTION ---") \# Deduplicate and write the data section $DataSection | Select-Object -Unique | ForEach-Object { $AsmOutput.Add($\_) } return $AsmOutput -join "\`n"
}

# ==========================================

# TEST: COMPILE BEAROS KERNEL

# ==========================================

$MyKernelCode = @"

# Setup the video pointer (DWord size)

^`$video_memory:d = 0xB8000;

# Print a 'K' to the screen!

deref `$video_memory w/ 0x4B;

# Testing Array Reservation (Reserve 10 bytes)

res `$buffer:b w/ 10;

`$buffer@2 = 0xFF;

# Testing Auto Null-Terminated Strings

`$os_name = "BearOS";

# Hang CPU

asm { hlt }

"@

Write-Host "Lexing..." -ForegroundColor Cyan

$Tokens = Invoke-TeddyLexer $MyKernelCode

Write-Host "Parsing..." -ForegroundColor Cyan

$AST = Invoke-TeddyParser $Tokens

Write-Host "Generating Assembly...`n" -ForegroundColor Cyan

$GeneratedAssembly = Invoke-TeddyGenerator $AST

Write-Host $GeneratedAssembly -ForegroundColor Green
