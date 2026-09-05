%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "yacc.tab.h"
%}

%%
"vars"            { return VARS; }
"sqrt"            { return SQRT; }
"abs"             { return ABS; }
"min"             { return MIN; }
"max"             { return MAX; }
"ecart_type"      { return ECART_TYPE; }
"somme"           { return SOMME; }
"moyenne"         { return MOYENNE; }
"variance"        { return VARIANCE; }
[0-9]+(\.[0-9]+)? { yylval.fval = atof(yytext); return NUM; } /* Changé f en fval */
"+"               { return '+'; }
"-"               { return '-'; }
"*"               { return '*'; }
"/"               { return '/'; }
"="               { return '='; }
"%"               { return '%'; }
"^"               { return '^'; }
"<="              { return LE; }
">="              { return GE; }
"=="              { return EQ; }
"!="              { return NE; }
"<"               { return '<'; }
">"               { return '>'; }
","               { return ','; }
"("               { return '('; }
")"               { return ')'; }
"\n"              { return '\n'; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.sval = strdup(yytext); return IDENT; }
[ \t]             { ; }
.                 { printf("Erreur lexicale: %s\n", yytext); }
%%

int yywrap(){ return 1; }