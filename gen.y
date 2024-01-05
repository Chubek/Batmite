%{
#include <stdio.h>
%}

%union {
    char *identifier;
    int integer;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM
/*	"%%"		 "%start"	"%term	  */

%token NEWLINE

%token <identifier> IDENTIFIER 
%token <integer> INTEGER 

%type <identifier> nonterm term
%type <integer> cost tree

%%

grammar: NEWLINE
       | declaration_list RULES rule_list;

declaration_list: /* Empty */ 
	        | declaration_list declaration
		;

declaration: PERCENT_START nonterm
           | PERCENT_TERM IDENTIFIER '=' INTEGER
           ;

RULES: PERCENT_PERCENT
     ;

rule_list: /* Empty */ 
	 | rule_list rule
	 ;

rule: nonterm ':' tree '=' INTEGER cost ';' 
    ;

cost: '(' INTEGER ')'
    ;

tree: /* Empty */
    | '|'
    | term '(' tree ',' tree ')'
    | term '(' tree ')'
    | term
    ;

term: IDENTIFIER
    | INTEGER
    ;

nonterm: IDENTIFIER
       ;

%%

int main() {
    yyparse();
    return 0;
}

int yyerror(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
    return 1;
}

int yylex() {
    // Implement your lexer (tokenization) logic here
    return 0;
}

