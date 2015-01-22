/* Inspired by Chapter 4 of the book "flex & bison", 3rd edition */
/* Based on MySQL 5.6 Reference Manual */

%lex

%options flex case-insensitive

%s BTWMODE

%%

\s+            /* skip whitespaces */

/* keywords for statements */
ALL	  return 'ALL'
DISTINCT  return 'DISTINCT'
DISTINCTROW  return 'DISTINCTROW'
SELECT	  return 'SELECT'
AS	  return 'AS'
FROM      return 'FROM'
WHERE     return 'WHERE'
GROUP     return 'GROUP'
BY	  return 'BY'
ASC	  return 'ASC'
DESC	  return 'DESC'
WITH	  return 'WITH'
ROLLUP	  return 'ROLLUP'
HAVING	  return 'HAVING'
ORDER	  return 'ORDER'
LIMIT	  return 'LIMIT'
OFFSET	  return 'OFFSET'

/* SQL literals */

[-]?[0-9]+                       return 'INT'
[-]?[0-9]+E[-+]?[0-9]+	         return 'DOUBLE'
[-]?[0-9]+"."[0-9]*	         return 'DOUBLE'
[-]?[0-9]+"."[0-9]*E[-+]?[0-9]+  return 'DOUBLE'
[-]?"."[0-9]+ 		         return 'DOUBLE'
[-]?"."[0-9]+E[-+]?[0-9]+        return 'DOUBLE'

TRUE	  return 'TRUE'
FALSE	  return 'FALSE'

['](\\.|''|[^'\n])*[']        return 'STRING'
\"(\\.|\"\"|[^"\n])*\"        return 'STRING'

['](\\.|[^'\n])*$        { console.error("Unterminated string %s", yytext); }
\"(\\.|[^"\n])*$         { console.error("Unterminated string %s", yytext); }

X['][0-9A-F]+[']    return 'STRING'
0X[0-9A-F]+         return 'STRING'

0B[01]+        return 'STRING'
B['][01]+[']   return 'STRING'

/* keywords for expressions */

/* hack for BETWEEN ... AND ... */
BETWEEN	        %{ this.begin('BTWMODE');
		   return 'BETWEEN'; %}
<BTWMODE>AND    %{ this.begin('INITIAL');
		   return 'BTWAND'; %}

OR        return 'OR'
"||"      return 'OR'
XOR	  return 'XOR'
AND	  return 'AND'
"&&"	  return 'AND'
NOT	  return 'NOT'
"!" 	  return '!'
IS	  return 'IS'
NULL	  return 'NULL'
ALL	  return 'ALL'
ANY	  return 'ANY'
"="	  return '='
">="	  return '>='
">"	  return '>'
"<="	  return '<='
"<"	  return '<'
"<>"	  return '<>'
"!="	  return '<>'
IN	  return 'IN'
"|"       return '|'
"&"	  return '&'
"<<"	  return '<<'
">>"	  return '>>'
"+"	  return '+'
"-"	  return '-'
"*" 	  return '*'
"/"	  return '/'
DIV	  return '/'
MOD	  return '%'
"%"	  return '%'
"^"	  return '^'
"~"	  return '~'
BINARY	  return 'BINARY'
ROW	  return 'ROW'
EXISTS	  return 'EXISTS'
"("	  return '('
")" 	  return ')'
"~"       return '~'

","	  return ','
"."	  return '.'

/* identifier */

[A-Za-z][A-Za-z0-9_]*    return 'NAME'

<<EOF>>  return 'EOF'

/lex

%left OR
%left XOR
%left AND
%right NOT
%nonassoc BETWEEN BTWAND
%nonassoc '=' '>=' '>' '<=' '<' '<>' IS IN
%left '|'
%left '&'
%left '<<' '>>'
%left '+' '-'
%left '*' '/' '%'
%left '^'
%nonassoc UMINUS
%nonassoc '!'
%onoassoc BINARY

%start stmt

%%

stmt
    : select_stmt EOF
        { return $1; }
    ;

select_stmt
    : SELECT select_opts select_expr_list opt_from opt_where opt_groupby opt_orderby
        { $$ = ['SELECT', $2, $3, $4, $5, $6, $7]; }
    ;

select_opts
    :  /* could be empty */
        { $$ = null; }
    | ALL
    | DISTINCT
    | DISTINCTROW
    ;

select_expr_list
    : select_expr
        { $$ = [$1]; }
    | select_expr ',' select_expr_list
        { $3.unshift($1); $$ = $3; }
    | '*'
        { $$ = ['*']; }
    ;

select_expr
    : expr
        { $$ = $1; }
    | expr NAME
        { $$ = ['AS', $1, $2]; }
    | expr AS NAME
        { $$ = ['AS', $1, $3]; }
    | NAME '.' '*'
        { $$ = ['TABCOL', $1, '*']; }
    | NAME '.' NAME
        { $$ = ['TABCOL', $1, $3]; }
    ;

opt_from
    : /* could be empyt */
        { $$ = null; }
    | FROM table_references
        { $$ = ['FROM', $2]; }
    ;

table_references
    : table_reference
    /* only allow a single table reference */
    ;

table_reference
    : table_factor
    /* do not support joins for now */
    ;

table_factor
    : table_id
        { $$ = $1; }
    | table_id NAME
        { $$ = ['AS', $1, $2]; }
    | table_id AS NAME
        { $$ = ['AS', $1, $3]; }
    ;

table_id
    : NAME
        { $$ = $1; }
    | NAME '.' NAME
        { $$ = ['DBTAB', $1, $3]; }
    ;

opt_where
    :  /* could be empty */
        {$$ = null; }
    | WHERE expr
        { $$ = ['WHERE', $2]; }
    ;

opt_groupby
    : /* could be empty */
        { $$ = null; }
    | GROUP BY groupby_list opt_asc_desc
        { $$ = ['GROUPBY', $3, $4]; }
    ;

groupby_list
    : expr
        { $$ = [$1]; }
    | expr ',' groupby_list
        { $3.unshift($1); $$ = $3; }
    ;

opt_asc_desc
    : /* could be empyt */
        { $$ = 'ASC'; }
    | ASC
        { $$ = 'ASC'; }
    | DESC
        { $$ = 'DESC'; }
    ;

opt_orderby
    : /* could be empty */
        { $$ = null; }
    | ORDER BY groupby_list opt_asc_desc
        { $$ = ['ORDERBY', $3, $4]; }
    ;

expr
    : expr OR expr
        { $$ = ['OR', $1, $3]; }
    | expr XOR expr
        { $$ = ['XOR', $1, $3]; }
    | expr AND expr
        { $$ = ['AND', $1, $3]; }
    | NOT expr
        { $$ = ['NOT', $2]; }
    | boolean_primary IS TRUE
        { $$ = ['EQ', $1, true]; }
    | boolean_primary IS FALSE
        { $$ = ['EQ', $1, false]; }
    | boolean_primary IS NOT TRUE
        { $$ = ['NE', $1, true]; }
    | boolean_primary IS NOT FALSE
        { $$ = ['NE', $1, false]; }
    | boolean_primary
        { $$ = $1; }
    ;

boolean_primary
    : boolean_primary IS NULL
        { $$ = ['==', $1, null]; }
    | boolean_primary IS NOT NULL
        { $$ = ['!=', $1, null]; }
    | boolean_primary '=' predicate
        { $$ = ['EQ', $1, $3]; }
    | boolean_primary '>=' predicate
        { $$ = ['GE', $1, $3]; }
    | boolean_primary '>' predicate
        { $$ = ['GT', $1, $3]; }
    | boolean_primary '<=' predicate
        { $$ = ['LE', $1, $3]; }
    | boolean_primary '<' predicate
        { $$ = ['LT', $1, $3]; }
    | boolean_primary '<>' predicate
        { $$ = ['NE', $1, $3]; }
    | predicate
        { $$ = $1; }
    ;

predicate
    : bit_expr BETWEEN bit_expr BTWAND predicate %prec BETWEEN
        { $$ = ['AND', ['GE', $1, $3], ['LE', $1, $5]]; }
    | bit_expr NOT BETWEEN bit_expr BTWAND predicate
        { $$ = ['OR', ['LT', $1, $3], ['GT', $1, $5]]; }
    | bit_expr
        { $$ = $1; }
    ;

bit_expr
    : bit_expr '|' bit_expr
        { $$ = ['|', $1, $3]; }
    | bit_expr '&' bit_expr
        { $$ = ['&', $1, $3]; }
    | bit_expr '<<' bit_expr
        { $$ = ['<<', $1, $3]; }
    | bit_expr '>>' bit_expr
        { $$ = ['>>', $1, $3]; }
    | bit_expr '+' bit_expr
        { $$ = ['+', $1, $3]; }
    | bit_expr '-' bit_expr
        { $$ = ['-', $1, $3]; }
    | bit_expr '*' bit_expr
        { $$ = ['*', $1, $3]; }
    | bit_expr '/' bit_expr
        { $$ = ['/', $1, $3]; }
    | bit_expr '%' bit_expr
        { $$ = ['%', $1, $3]; }
    | bit_expr '^' bit_expr
        { $$ = ['^', $1, $3]; }
    | simple_expr
        { $$ = $1; }
    ;

simple_expr
    : INT
        { $$ = Number(yytext); }
    | DOUBLE
        { $$ = Number(yytext); }
    | TRUE
        { $$ = true; }
    | FALSE
        { $$ = false; }
    | STRING
        { $$ = yytext; }
    | NAME
        { $$ = yytext; }
    | NAME '(' expr ')'
        { $$ = ['FUNCALL', $1, $3]; }
    | NAME '(' '*' ')'
        { $$ = ['FUNCALL', $1, '*']; }
    ;
