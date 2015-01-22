%lex
%%

\s+           /* skip whitespaces */
[-]?[0-9]+    return 'INT'
","	      return ','
"["           return '['
"]"	      return ']'
<<EOF>>       return 'EOF'

/lex

// user-defined variables

%{
var total = 0;
%}

%start integers

%%

integers
    : '[' list ']' EOF
        { console.log(total); }
    ;

list
    : INT
        { add(Number($1)); }
    | list ',' INT
        { add(Number($3)); }
    ;

%%

// user-defined functions

function add (item) { total += item; }
