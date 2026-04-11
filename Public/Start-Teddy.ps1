$tempSource = "res $buffer w/ 10;"

class Token {
    [string]$Type
    [string]$Value

    Token($t, $v) {
        $this.Type
        $this.Value
    }
}

function Start-Lexer ([string]$tempSource) {
    $RegexPattern = 
        '(?<Space>^\\s+)|' + # Whitespace
        '(?<Key>^(asm|deref|res))|' + # Keyword
        '(?<RegVar>^!\\$[a-zA-Z_].*?)|' + 
        '(?<Var>^\\$[a-zA-Z_].*?)|' + # Variable
        '(?<Int>^[0-9]+)|' + # Integer Value
        '(?<Operator>^=)|' # Operator
}
