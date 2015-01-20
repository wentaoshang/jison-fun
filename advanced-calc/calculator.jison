/* lexical grammar */
%lex

%options case-insensitive

%%

\s+                   /* skip whitespace */
";"                   return ';'
[0-9]+("."[0-9]+)?\b  return 'NUMBER'
"*"                   return '*'
"/"                   return '/'
"-"                   return '-'
"+"                   return '+'
"^"                   return '^'
"!"                   return '!'
"%"                   return '%'
"("                   return '('
")"                   return ')'
"|"                   return '|'
"PI"                  return 'PI'
"E"                   return 'E'
IF                    return 'IF'
THEN                  return 'THEN'
ELSE                  return 'ELSE'
TRUE                  return 'TRUE'
FALSE                 return 'FALSE'
LET                   return 'LET'
"="                   return '='
IN                    return 'IN'
[a-zA-Z][a-zA-Z0-9]*  return 'ID'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'
%left '!'
%left '%'
%nonassoc '|' UMINUS

%start program

%% /* language grammar */

program
    : stmts EOF
        { return $1; }
    ;

stmts
    : stmt
        { $$ = $1; }
    | stmt ';' stmts
        { $$ = ['SEQ', $1, $3]; }
    ;

stmt
    : expr
        { $$ = $1; }
    | IF expr THEN stmt ELSE stmt
        { $$ = ['IF', $2, $4, $6]; }
    | LET ID '=' expr IN stmt
        { $$ = ['LET', $2, $4, $6]; }
    ;

expr
    : expr '+' expr
        { $$ = ['ADD', $1, $3]; }
    | expr '-' expr
        { $$ = ['SUB', $1, $3]; }
    | expr '*' expr
        { $$ = ['MUL', $1, $3]; }
    | expr '/' expr
        { $$ = ['DIV', $1, $3]; }
    | expr '^' expr
        { $$ = ['POW', $1, $3]; }
    | '!' expr
        { $$ = ['NOT', $2]; }
    | expr '%' expr
        { $$ = ['MOD', $1, $3]; }
    | '|' expr '|'
        { $$ = ['ABS', $2]; }
    | '-' expr %prec UMINUS
        { $$ = ['NEG', $2]; }
    | '(' stmts ')'
        { $$ = $2; }
    | NUMBER
        { $$ = Number(yytext); }
    | E
        { $$ = Math.E; }
    | PI
        { $$ = Math.PI; }
    | TRUE
        { $$ = true; }
    | FALSE
        { $$ = false; }
    | ID
        { $$ = ['VAR', yytext]; }
    ;
