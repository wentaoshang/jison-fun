/* Inspired by Chapter 4 of the book "flex & bison", 3rd edition */
/* Based on MySQL 5.6 Reference Manual */

%lex

%options flex case-insensitive

%s BTWMODE

%%

\s+            /* skip whitespaces */

/* keywords for statements */
ALL	  return 'ALL'
ANY 	  return 'ANY'
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

JOIN      return 'JOIN'
ON        return 'ON'
INNER     return 'INNER'
CROSS     return 'CROSS'
OUTER     return 'OUTER'
LEFT      return 'LEFT'
RIGHT     return 'RIGHT'
NATURAL   return 'NATURAL'

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
%nonassoc UMINUS '~'
%nonassoc '!'
%nonassoc BINARY

%start stmt

%%

stmt
    : select_stmt EOF
        { return $1; }
    ;

subquery
    : select_stmt { $$ = $1; }
    ;

select_stmt
    : SELECT select_opts select_expr_list opt_from opt_where
      opt_groupby opt_having opt_orderby opt_limit
        { $$ = [['SELECT', $2, $3], $4, $5, $6, $7, $8, $9]; }
    ;

select_opts
    :  /* could be empty */
        { $$ = 'ALL'; }  /* default to ALL */
    | ALL
    | DISTINCT
    | DISTINCTROW
    ;

select_expr_list
    : select_expr
        { $$ = [$1]; }
    | select_expr ',' select_expr_list
        { $3.unshift($1); $$ = $3; }
    ;

select_expr
    : expr
        { $$ = $1; }
    | expr NAME
        { $$ = ['AS', $1, $2]; }
    | expr AS NAME
        { $$ = ['AS', $1, $3]; }
    | '*'
        { $$ = '*'; }
    ;

opt_from
    : /* could be empyt */
        { $$ = null; }
    | FROM table_references
        { $$ = ['FROM', $2]; }
    ;

table_references
    : table_reference
        { $$ = [$1]; }
    | table_reference ',' table_references
        { $3.unshift($1); $$ = $3; }
    ;

table_reference
    : table_factor
    | join_table
    ;

table_factor
    : table_id
        { $$ = $1; }
    | table_id NAME
        { $$ = ['AS', $1, $2]; }
    | table_id AS NAME
        { $$ = ['AS', $1, $3]; }
    | '(' table_references ')'
        { $$ = $2; }
    ;

table_id
    : NAME
        { $$ = $1; }
    | NAME '.' NAME
        { $$ = ['DBTAB', $1, $3]; }
    ;

join_table
      /* use SQL standard definition of CROSS JOIN, i.e., no ON clause can be used */
    : table_reference CROSS JOIN table_factor
        { $$ = ['CROSSJOIN', $1, $4]; }
      /* use SQL standard definition of INNER JOIN, i.e., ON clause must be used */
    | table_reference opt_inner JOIN table_factor ON expr
        { $$ = ['INNERJOIN', $1, $4, $6]; }
    | table_reference LEFT opt_outer JOIN table_factor ON expr
        { $$ = ['LEFTJOIN', $1, $5, $7]; }
    | table_reference RIGHT opt_outer JOIN table_factor ON expr
        { $$ = ['RIGHTJOIN', $1, $5, $7]; }
    | table_reference NATURAL JOIN table_factor
        { $$ = ['NATURALJOIN', $1, $4]; }
    ;

opt_inner
    : /* could be empty */
    | INNER
    ;

opt_outer
    : /* could be empty */
    | OUTER
    ;

opt_where
    :  /* could be empty */
        { $$ = null; }
    | WHERE expr
        { $$ = ['WHERE', $2]; }
    ;

opt_groupby
    : /* could be empty */
        { $$ = null; }
    | GROUP BY expr_list opt_asc_desc
        { $$ = ['GROUPBY', $3, $4]; }
    ;

expr_list
    : expr
        { $$ = [$1]; }
    | expr ',' expr_list
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

opt_having
    : /* could be empty */
        { $$ = null; }
    | HAVING expr
        { $$ = ['HAVING', $2]; }
    ;

opt_limit
    : /* could be empty */
        { $$ = null; }
    | LIMIT expr
        { $$ = ['LIMIT', 0, $2]; }
    | LIMIT expr ',' expr
        { $$ = ['LIMIT', $2, $4]; }
    | LIMIT expr OFFSET expr
        { $$ = ['LIMIT', $4, $2]; }
    ;

opt_orderby
    : /* could be empty */
        { $$ = null; }
    | ORDER BY expr_list opt_asc_desc
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

comparison_ops
    : '='  { $$ = 'EQ'; }
    | '>=' { $$ = 'GE'; }
    | '>'  { $$ = 'GT'; }
    | '<=' { $$ = 'LE'; }
    | '<'  { $$ = 'LT'; }
    | '<>' { $$ = 'NE'; }
    | '!=' { $$ = 'NE'; }
    ;

all_or_any
    : ALL  { $$ = 'ALL'; }
    | ANY  { $$ = 'ANY'; }
    ;

boolean_primary
    : boolean_primary IS NULL
        { $$ = ['EQ', $1, null]; }
    | boolean_primary IS NOT NULL
        { $$ = ['NE', $1, null]; }
    | boolean_primary comparison_ops predicate
        { $$ = [$2, $1, $3]; }
    | boolean_primary comparison_ops all_or_any '(' subquery ')'
        { $$ = [$2, $1, $3, $4]; }
    | predicate
        { $$ = $1; }
    ;

predicate
    : bit_expr IN '(' subquery ')'
        { $$ = ['IN', $1, $4]; }
    | bit_expr NOT IN '(' subquery ')'
        { $$ = ['NOTIN', $1, $5]; }
    | bit_expr IN '(' expr_list ')'
        { $$ = ['IN', $1, $4]; }
    | bit_expr NOT IN '(' expr_list ')'
        { $$ = ['NOTIN', $1, $5]; }
    | bit_expr BETWEEN bit_expr BTWAND predicate %prec BETWEEN
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
    | NAME '.' '*'
        { $$ = ['TABCOL', $1, '*']; }
    | NAME '.' NAME
        { $$ = ['TABCOL', $1, $3]; }
    | NAME '(' expr_list ')'
        { $$ = ['FUNCALL', $1, $3]; }
    | NAME '(' '*' ')'
        { $$ = ['FUNCALL', $1, '*']; }
    | '(' subquery ')'
        { $$ = $2; }
    | EXISTS '(' subquery ')'
        { $$ = ['EXISTS', $3]; }
    | '(' expr_list ')'
        { $$ = $2; }
    | '-' simple_expr %prec UMINUS
        { $$ = ['NEG', $2]; }
    | '~' simple_expr
        { $$ = ['~', $2]; }
    | '!' simple_expr
        { $$ = ['!', $2]; }
    ;
