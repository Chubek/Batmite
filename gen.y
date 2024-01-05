%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yyerror(const char *msg);
int yylex(void);

%}

%union {
    char *stringVal;
    char *sigmaVal;
    int intVal;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM
/*	"%%"		 "%start"	"%term    */

%token NEWLINE

%token <sigmaVal> SEMANTIC_ACTION PRELUDE CONCLUDE
%token <stringVal> IDENTIFIER NONTERM OPCODE
%token <intVal> INTEGER

%type <stringVal> nonterm term
%type <intVal> cost tree

%%

grammar: NEWLINE
       | declaration_list RULES rule_list
       | PRELUDE declarations_list RULES rule_list
       | PRELUDE declarations_list RULES rule_list RULES CONCLUDE
       ;

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

rule: nonterm ':' tree '=' cost  SEMANTIC_ACTION  ';'
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
    | OPCODE
    | NONTERM
    ;

nonterm: NONTERM
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

int npcntpcnt = 0;

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
	    	npcntpcnt++;
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
        yylval.intVal = atoi(buffer);
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
        yylval.stringVal = zStrDup(buffer);
        ungetc(c, stdin);
        return IDENTIFIER;
    }

    else if (c == '{') {
	char buffer[MAX_TOKEN_LENGTH];
	int i = 0;
	int nbraces = 1;

	if ((c = getchar()) = '%') {
		for (;;) {
			buffer[i++] = c = getchar();
			if (c == '%') {
				if ((c = getchar()) == '}') {
					yylval.sigmaVal = zStrDup(&yytext[0]);
					return PRELUDE;
				}
				ungetc();
			}
		}
	} else {	
		while (nbraces > 0) {	
			buffer[i++] = c = getchar();
			if (c == '{')
				nbraces++;
			else if (c == '}')
				nbraces--;
		}
		yylval.sigmaVal = zStrDup(&buffer[0]);
		return SEMANTIC_ACTION;	
	}
    }
    else if (npcntpcnt == 2) {
	char *buffer = (char*)zalloc(MAX_TOKEN_LENGTH);
	int i = 0;
	int step = 1;
	while ((c = getchar()) != EOF) {
		buffer[i++] = c;
		if (i == MAX_TOKEN_LENGTH - 1) {
			buffer = (char*)zealloc(buffer, MAX_TOKEN_LENGTH * ++step);	
		}
	}
	yylval.sigmaVal = buffer;
	return CONDLUE;
    }

    else
        return c;

    return 0; 
}

static const *char boilerplate = <<< END_HEADER_STR
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

@@ DEFINITIONS @@

#define stmt_NT		1
#define disp_NT		2
#define rc_NT		3
#define reg_NT		4
#define con_NT		5

typedef struct State State;
typedef struct {
	OPCODE_TYPE opcode;
	State *left;
	State *right;
	struct {
	   stmt : 2;
	   disp : 2;
	   rc   : 2;
	   reg  : 2;
	   con  : 2;
	} cost;
	struct {
	   stmt : 2;
	   disp : 2;
	   rc   : 2;
	   reg  : 2;
	   con  : 2;
	} rule;
} State;

LABEL_TYPE fnLabel(NODEPTR_TYPE nodeP) {
	if (nodeP) {
		LABEL_TYPE left   = label(LEFT_CHILD(nodeP));
		LABEL_TYPE right  = label(RIGHT_CHILD(nodeP));
		return STATE_LABEL(nodeP) = state(OP_LABEL(nodeP), left, right);
	} else {
	 	return LABEL_DEFAULT;
	}
}
