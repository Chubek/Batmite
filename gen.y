%{
#include <stdio.h>
#include <stdlib.h>


typedef struct {
    int is_terminal;
    char *identifier;
    int value;
} Term;

typedef struct {
    char *start_nonterm;
    char *identifier;
    int value;
} Declaration;

typedef struct {
    char *nonterm;
    Term *term;
    int value;
} Rule;

typedef struct {
     Rule **rules;
     Declaration **decls, *startRule;
     int numRules, numDecls;
     char *definitions, userCode;
} Spec;

Rule *startingRule;

Spec *createSpec
Declaration* createDecl(char *start_nonterm, char *identifier, int value);
Term* createTerm(char *identifier, int value);
Rule* createRule(char *nonterm, Term *term, int value);
void yyerror(const char *msg);
%}

%union {
    char *stringVal;
    int intVal;
    Declaration *declarationVal;
    Term *termVal;
    Rule *ruleVal;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM NEWLINE COLON EQUAL SEMICOLON LPAREN RPAREN COMMA IDENTIFIER 

%token <intVal> INTEGER
%token <stringVal> DEFINITIONS USER_CODE

%type <stringVal> nonterm
%type <declarationVal> dcl
%type <termVal> term
%type <ruleVal> rule
%type <intVal> cost

%start spec
%%

spec: NEWLINE { printf("Parsed successfully!\n"); }
    | dcl PERCENT_PERCENT rule_list PERCENT_PERCENT { printf("Parsed successfully!\n"); }
    | PERCENT_PERCENT { printf("Parsed successfully!\n"); }
    | DEFINITIONS  
    | USER_CODE
    ;

dcl: PERCENT_START nonterm { startingRule = createRule($2, NULL, 0); }
    | PERCENT_TERM IDENTIFIER '=' INTEGER { $$ = createDecl(NULL, $2, $4); }
    ;

rule_list: rule_list rule { /* Add code for handling rule list */ }
    | /* Empty */ { /* Add code for empty rule list */ };

rule: nonterm COLON tree EQUAL INTEGER cost SEMICOLON { /* Add code for handling rule */ }
    | nonterm COLON tree EQUAL INTEGER SEMICOLON { /* Add code for handling rule without cost */ }
    ;

cost: LPAREN INTEGER RPAREN { $$ = $2; }
    | /* Empty */ { $$ = 0; }
    ;

tree: term LPAREN tree COMMA tree RPAREN { /* Add code for handling tree */ }
    | term LPAREN tree RPAREN { /* Add code for handling tree with one subtree */ }
    | term { /* Add code for handling single term */ }
    | nonterm { /* Add code for handling nonterminal */ }
    ;

term: IDENTIFIER { $$ = createTerm($1, 0); }
    | INTEGER { $$ = createTerm(NULL, $1); }
    ;

nonterm: IDENTIFIER { $$ = $1; }
       ;

%%

int numberOfPercentPercent = 0;

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
	   	numberOfPercentPercent++;
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
					yylval.stringVal = zStrDup(&yytext[0]);
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
		yylval.stringVal = zStrDup(&buffer[0]);
		return SEMANTIC_ACTION;	
	}
    }
    else if (numberOfPercentPercent == 2) {
	char *buffer = (char*)zAlloc(MAX_TOKEN_LENGTH);
	int i = 0;
	int step = 1;
	while ((c = getchar()) != EOF) {
		buffer[i++] = c;
		if (i == MAX_TOKEN_LENGTH - 1) {
			buffer = (char*)zRealloc(buffer, MAX_TOKEN_LENGTH * ++step);	
		}
	}
	yylval.stringVal = buffer;
	return CONDLUE;
    }

    else
        return c;

    return 0; 
}


void yyerror(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
    exit(1);
}


Declaration* createDecl(char *start_nonterm, char *identifier, int value) {
    Declaration *declaration = (Declaration *)malloc(sizeof(Declaration));
    declaration->start_nonterm = start_nonterm;
    declaration->identifier = identiier;
    declaration->value = value;
    return declaration;
}

Term* createTerm(char *identifier, int value) {
    Term *term = (Term *)malloc(sizeof(Term));
    term->is_terminal = (identifier != NULL);
    term->identifier = identifier;
    term->value = value;
    return term;
}

Rule* createRule(char *nonterm, Term *term, int value) {
    Rule *rule = (Rule *)malloc(sizeof(Rule));
    rule->nonterm = nonterm;
    rule->term = term;
    rule->value = value;
    return rule;
}

int main() {
    yyparse();
    return 0;
}
f
