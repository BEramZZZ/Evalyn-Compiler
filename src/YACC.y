%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
void yyerror(const char *s);
int yylex();

#define MAX_VARS 100

typedef struct {
    char name[32];
    float value;
} Variable;

Variable symtab[MAX_VARS];
int var_count = 0;

float lookup(char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(symtab[i].name, name) == 0)
            return symtab[i].value;
    }
    printf("Erreur: variable '%s' non definie\n", name);
    return 0;
}

void set_var(char *name, float value) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(symtab[i].name, name) == 0) {
            symtab[i].value = value;
            return;
        }
    }
    if (var_count < MAX_VARS) {
        strcpy(symtab[var_count].name, name);
        symtab[var_count].value = value;
        var_count++;
    }
}
%}

/* Bloc spécial pour que la struct soit visible dans yacc.tab.h */
%code requires {
  struct stats {
      float sum;
      float sum_sq;
      int count;
      float min;
      float max;
  };
}

%union {
    float fval;
    struct stats st;
    char *sval;
}

%token <sval> IDENT
%token <fval> NUM
%token SOMME VARIANCE MOYENNE
%token VARS
%token LE GE EQ NE
%token SQRT ABS MIN MAX ECART_TYPE
%type <fval> exp
%type <st> arg_list


%nonassoc '<' '>' LE GE EQ NE
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%right '^'

%%

input: 
     | input line
     ;

line: '\n'
    | VARS '\n' {
        if (var_count == 0) {
            printf("Aucune variable definie\n");
        } else {
            for (int i = 0; i < var_count; i++) {
                printf("%s = %g\n", symtab[i].name, symtab[i].value);
            }
        }
      }
    | IDENT '=' exp '\n' {
        set_var($1, $3);
        printf("%s = %g\n", $1, $3);
        free($1);
      }           
    | exp '\n' {
        if ($1 == (int)$1)
            printf("Result : %d\n", (int)$1);
        else
            printf("Result : %f\n", $1);
      }
    | error '\n'       { yyerrok; printf("Syntax Error - Enter next expression:\n"); }
    ;

exp: NUM               { $$ = $1; }
   | exp '+' exp       { $$ = $1 + $3; }
   | exp '-' exp       { $$ = $1 - $3; }
   | exp '*' exp       { $$ = $1 * $3; }
   | exp '/' exp       { 
        if($3 == 0) { yyerror("Division by zero"); $$ = 0; }
        else { $$ = $1 / $3; }
     }
   | exp '<' exp   { $$ = ($1 < $3)  ? 1 : 0; }
   | exp '>' exp   { $$ = ($1 > $3)  ? 1 : 0; }
   | exp LE  exp   { $$ = ($1 <= $3) ? 1 : 0; }
   | exp GE  exp   { $$ = ($1 >= $3) ? 1 : 0; }
   | exp EQ  exp   { $$ = ($1 == $3) ? 1 : 0; }
   | exp NE  exp   { $$ = ($1 != $3) ? 1 : 0; }
   
   | IDENT { $$ = lookup($1); free($1); }
   | SOMME '(' arg_list ')'    { $$ = $3.sum; }
   | MOYENNE '(' arg_list ')'  { $$ = $3.sum / $3.count; }
   | VARIANCE '(' arg_list ')' { 
       float mean = $3.sum / $3.count;
       $$ = ($3.sum_sq / $3.count) - (mean * mean); 
     }
   | '(' exp ')'       { $$ = $2; }
   | '-' exp %prec UMINUS      { $$ = -$2; }
   | exp '%' exp                { $$ = fmod($1, $3); }
   | exp '^' exp                { $$ = pow($1, $3); }
   | SQRT '(' exp ')'           { $$ = sqrt($3); }
   | ABS '(' exp ')'            { $$ = fabs($3); }
   | MIN '(' arg_list ')'       { $$ = $3.min; }
   | MAX '(' arg_list ')'       { $$ = $3.max; }
   | ECART_TYPE '(' arg_list ')' {
       float mean = $3.sum / $3.count;
       float variance = ($3.sum_sq / $3.count) - (mean * mean);
       $$ = sqrt(variance);
   };


arg_list: exp { 
            $$.sum = $1; 
            $$.sum_sq = $1 * $1; 
            $$.count = 1; 
            $$.min = $1;
            $$.max = $1;
          }
        | arg_list ',' exp { 
            $$.sum = $1.sum + $3; 
            $$.sum_sq = $1.sum_sq + ($3 * $3);
            $$.count = $1.count + 1; 
            $$.min = ($3 < $1.min) ? $3 : $1.min;
            $$.max = ($3 > $1.max) ? $3 : $1.max;
          }
        ;
%%
void yyerror(const char *msg) { fprintf(stderr, "Erreur: %s\n", msg); }
int main() { return yyparse(); }