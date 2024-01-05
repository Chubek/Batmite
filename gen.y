%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yyerror(const char *msg);
int yylex(void);

%}

%union {
    char *identifier;
    char *sigma;
    int integer;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM
/*	"%%"		 "%start"	"%term	  */

%token NEWLINE

%token <sigma> SEMANTIC_ACTION
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

rule: nonterm ':' tree '=' cost ';' 
    | nonterm ':' tree '=' cost  SEMANTIC_ACTION  ';'
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

#define MAX_TOKEN_LENGTH 65535

int yylex(void) {
    char c = getchar();

    while (c == ' ' || c == '\t' || c == '\n') {
        c = getchar();
    }

    if (c == EOF) {
        return 0; 
    }

    if (c == '%') {
        char buffer[MAX_TOKEN_LENGTH];
        int i = 0;

        if ((c = getchar()) == 't') {
            while ((c = getchar()) != '\n') {
                if (i < MAX_TOKEN_LENGTH - 1) {
                    buffer[i++] = c;
                }
            }
            buffer[i] = '\0';
            if (strcmp(buffer, "oken") == 0) {
                return IDENTIFIER;
            } else if (strcmp(buffer, "ype") == 0) {
                return INTEGER;
            }
        }

        else if (c == 's') {
            while ((c = getchar()) != '\n') {
                if (i < MAX_TOKEN_LENGTH - 1) {
                    buffer[i++] = c;
                }
            }
            buffer[i] = '\0';
            if (strcmp(buffer, "tart") == 0) {
                return PERCENT_START;
            } else if (strcmp(buffer, "erm") == 0) {
                return PERCENT_TERM;
            }
        }

        else if (c == '%') {
            if ((c = getchar()) == '%') {
                return PERCENT_PERCENT;
            }
        }
    }

    else if (c >= '0' && c <= '9') {
        char buffer[MAX_TOKEN_LENGTH];
        int i = 0;

        while (c >= '0' && c <= '9') {
            if (i < MAX_TOKEN_LENGTH - 1) {
                buffer[i++] = c;
            }
            c = getchar();
        }

        buffer[i] = '\0';
        yylval.integer = atoi(buffer);
        ungetc(c, stdin);
        return INTEGER;
    }

    else if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) {
        char buffer[MAX_TOKEN_LENGTH];
        int i = 0;

        while ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
            if (i < MAX_TOKEN_LENGTH - 1) {
                buffer[i++] = c;
            }
            c = getchar();
        }

        buffer[i] = '\0';
        yylval.identifier = strdup(buffer);
        ungetc(c, stdin);
        return IDENTIFIER;
    }

    else if (c == '{') {
	char buffer[MAX_TOKEN_LENGTH];
	int i = 0;
	int nbraces = 1;
	
	while (nbraces > 0) {	
		buffer[i++] = c = getchar();
		if (c == '{')
			nbraces++;
		else if (c == '}')
			nbraces--;
	}
	yylval.sigma = strdup(&buffer[0]);
	return SEMANTIC_ACTION;	
    }

    else
        return c;

    return 0; 
}
