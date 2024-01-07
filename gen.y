%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef enum {
    TERM_OPCODE,
    TERM_IDENTIFIER,
} TermKind;

typedef struct {
    bool nonterminal;
    TermKind kind;
    char *identifier;
    IROpcode opcode;
} Term;

typedef struct {
    Term *value;
    Tree *left, *right;
} Tree;

typedef struct {
    char *ident;
    int extRuleNum;
} Decl;

typedef struct {
    char *nonterm;
    Term *term;
    int value;
} Rule;

typedef struct {
     Rule **rules;
     Decl **decls;
     int numRules, numDecls;
     char *definitions, userCode;
} Spec;

Rule *startingRule = NULL;

Spec *createSpec(Rule **rules, Decl **decls, 
			int numRules, int numDecls,
			char *definitions, char *userCode);

Decl* createDecl(char *ident, int extRuleNum);

Tree *createTree(Term *term, Tree *left, Tree *right);

Term *createOpcodeTerm(IROpcode opcode);
Term *createIdentTerm(char *ident, bool nonterminal);

Rule* createRule(char *nonterm, Term *term, int value);

int yylex(void);
void yyerror(const char *msg);
%}

%union {
    char *stringVal;
    int intVal;
    IROpcode opcodeVal;
    Decl *declVal;
    Term *termVal;
    Rule *ruleVal;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM NEWLINE COLON EQUAL SEMICOLON LPAREN RPAREN COMMA

%token <intVal> INTEGER
%token <opcodeVal> IR_OPCODE
%token <stringVal> DEFINITIONS USER_CODE IDENTIFIER

%type <stringVal> nonterm
%type <declVal> dcl
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

rule_list: rule_list rule {  }
    |  };

rule: nonterm COLON tree EQUAL INTEGER cost SEMICOLON {  }
    | nonterm COLON tree EQUAL INTEGER SEMICOLON {  }
    ;

cost: LPAREN INTEGER RPAREN { $$ = $2; }
    |  { $$ = 0; }
    ;

tree: term LPAREN tree COMMA tree RPAREN {  }
    | term LPAREN tree RPAREN {  }
    | term {  }
    | nonterm {  }
    ;

term: IDENTIFIER { $$ = createIdentTerm($1, false); }
    | IR_OPCODE { $$ = createOpcodeTerm($1); }
    ;

nonterm: IDENTIFIER { $$ = createIdentTerm($1, true); }
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
        char buffer[MAX_TOKEN_LENGTH] = {0};
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

    else if (c == '$') {
        char buffer[MAX_TOKEN_LENGTH] = {0};
	buffer[0] = '$';
	int i = 1;

	while (!isblank((c = getchar())))
		buffer[i++] = c;

	IROpcode lexOpcodeResult = getOpcode(&buffer[0]);

	if (lexOpcodeResult != IR_PHI) {
	 	yylval.opcodeVal = lexOpcodeResult;
		return IR_OPCODE;
	} else {
		fprintf(stderr, "Illegal opcode: %s", &buffer[0]);
		exit(EXIT_FAILURE);
	}
    }

    else if (c >= '0' && c <= '9') {
        char buffer[MAX_TOKEN_LENGTH] = {0};
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
        char buffer[MAX_TOKEN_LENGTH] = {0};
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
	char buffer[MAX_TOKEN_LENGTH] = {0};
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

IROpcode getOpcode(char *input) {
  if (input[0] == '$') {
    if (strcmp(input + 1, "IR_ADD") == 0) return IR_ADD;
    if (strcmp(input + 1, "IR_SUB") == 0) return IR_SUB;
    if (strcmp(input + 1, "IR_MUL") == 0) return IR_MUL;
    if (strcmp(input + 1, "IR_DIV") == 0) return IR_DIV;
    if (strcmp(input + 1, "IR_UDIV") == 0) return IR_UDIV;
    if (strcmp(input + 1, "IR_UREM") == 0) return IR_UREM;
    if (strcmp(input + 1, "IR_POW") == 0) return IR_POW;
    if (strcmp(input + 1, "IR_MOD") == 0) return IR_MOD;
    if (strcmp(input + 1, "IR_NEG") == 0) return IR_NEG;
    if (strcmp(input + 1, "IR_AND") == 0) return IR_AND;
    if (strcmp(input + 1, "IR_OR") == 0) return IR_OR;
    if (strcmp(input + 1, "IR_XOR") == 0) return IR_XOR;
    if (strcmp(input + 1, "IR_NOT") == 0) return IR_NOT;
    if (strcmp(input + 1, "IR_LSR") == 0) return IR_LSR;
    if (strcmp(input + 1, "IR_LSL") == 0) return IR_LSL;
    if (strcmp(input + 1, "IR_ASR") == 0) return IR_ASR;
    if (strcmp(input + 1, "IR_ULT") == 0) return IR_ULT;
    if (strcmp(input + 1, "IR_ULE") == 0) return IR_ULE;
    if (strcmp(input + 1, "IR_UGT") == 0) return IR_UGT;
    if (strcmp(input + 1, "IR_UGE") == 0) return IR_UGE;
    if (strcmp(input + 1, "IR_UEQ") == 0) return IR_UEQ;
    if (strcmp(input + 1, "IR_UNE") == 0) return IR_UNE;
    if (strcmp(input + 1, "IR_LT") == 0) return IR_LT;
    if (strcmp(input + 1, "IR_LE") == 0) return IR_LE;
    if (strcmp(input + 1, "IR_GT") == 0) return IR_GT;
    if (strcmp(input + 1, "IR_GE") == 0) return IR_GE;
    if (strcmp(input + 1, "IR_EQ") == 0) return IR_EQ;
    if (strcmp(input + 1, "IR_NE") == 0) return IR_NE;
    if (strcmp(input + 1, "IR_GOTO") == 0) return IR_GOTO;
    if (strcmp(input + 1, "IR_RETURN") == 0) return IR_RETURN;
    if (strcmp(input + 1, "IR_JUMP") == 0) return IR_JUMP;
    if (strcmp(input + 1, "IR_JUMP_IF_TRUE") == 0) return IR_JUMP_IF_TRUE;
    if (strcmp(input + 1, "IR_JUMP_IF_FALSE") == 0) return IR_JUMP_IF_FALSE;
    if (strcmp(input + 1, "IR_BLIT") == 0) return IR_BLIT;
    if (strcmp(input + 1, "IR_CALL") == 0) return IR_CALL;
    if (strcmp(input + 1, "IR_HALT") == 0) return IR_HALT;
    if (strcmp(input + 1, "IR_NOP") == 0) return IR_NOP;
    if (strcmp(input + 1, "IR_LOAD_QUAD") == 0) return IR_LOAD_QUAD;
    if (strcmp(input + 1, "IR_STORE_QUAD") == 0) return IR_STORE_QUAD;
    if (strcmp(input + 1, "IR_LOAD_DOUBLE") == 0) return IR_LOAD_DOUBLE;
    if (strcmp(input + 1, "IR_STORE_DOUBLE") == 0) return IR_STORE_DOUBLE;
    if (strcmp(input + 1, "IR_LOAD_HALF") == 0) return IR_LOAD_HALF;
    if (strcmp(input + 1, "IR_STORE_HALF") == 0) return IR_STORE_HALF;
    if (strcmp(input + 1, "IR_LOAD_BYTE") == 0) return IR_LOAD_BYTE;
    if (strcmp(input + 1, "IR_STORE_BYTEi") == 0) return IR_STORE_BYTEi;
    if (strcmp(input + 1, "IR_NULL") == 0) return IR_NULL;
    if (strcmp(input + 1, "IR_ALLOCA_4B") == 0) return IR_ALLOCA_4B;
    if (strcmp(input + 1, "IR_ALLOCA_8B") == 0) return IR_ALLOCA_8B;
    if (strcmp(input + 1, "IR_ALLOCA_16B") == 0) return IR_ALLOCA_16B;
    if (strcmp(input + 1, "IR_TRUNC_QUAD2DOUBLE_S") == 0) return IR_TRUNC_QUAD2DOUBLE_S;
    if (strcmp(input + 1, "IR_TRUNC_QUAD2HALF_S") == 0) return IR_TRUNC_QUAD2HALF_S;
    if (strcmp(input + 1, "IR_TRUNC_QUAD2BYTE_S") == 0) return IR_TRUNC_QUAD2BYTE_S;
    if (strcmp(input + 1, "IR_TRUNC_DOUBLE2HALF_S") == 0) return IR_TRUNC_DOUBLE2HALF_S;
    if (strcmp(input + 1, "IR_TRUNC_DOUBLE2BYTE_S") == 0) return IR_TRUNC_DOUBLE2BYTE_S;
    if (strcmp(input + 1, "IR_TRUNC_HALF2BYTE_S") == 0) return IR_TRUNC_HALF2BYTE_S;
    if (strcmp(input + 1, "IR_TRUNC_QUAD2DOUBLE_U") == 0) return IR_TRUNC_QUAD2DOUBLE_U;
    if (strcmp(input + 1, "IR_TRUNC_QUAD2HALF_U") == 0) return IR_TRUNC_QUAD2HALF_U;
    if (strcmp(input + 1, "IR_TRUNC_QUAD2BYTE_U") == 0) return IR_TRUNC_QUAD2BYTE_U;
    if (strcmp(input + 1, "IR_TRUNC_DOUBLE2HALF_U") == 0) return IR_TRUNC_DOUBLE2HALF_U;
    if (strcmp(input + 1, "IR_TRUNC_DOUBLE2BYTE_U") == 0) return IR_TRUNC_DOUBLE2BYTE_U;
    if (strcmp(input + 1, "IR_TRUNC_HALF2BYTE_U") == 0) return IR_TRUNC_HALF2BYTE_U;
    if (strcmp(input + 1, "IR_EXTEND_DOUBLE2QUAD_S") == 0) return IR_EXTEND_DOUBLE2QUAD_S;
    if (strcmp(input + 1, "IR_EXTEND_HALF2QUAD_S") == 0) return IR_EXTEND_HALF2QUAD_S;
    if (strcmp(input + 1, "IR_EXTEND_BYTE2QUAD_S") == 0) return IR_EXTEND_BYTE2QUAD_S;
    if (strcmp(input + 1, "IR_EXTEND_HALF2DOUBLE_S") == 0) return IR_EXTEND_HALF2DOUBLE_S;
    if (strcmp(input + 1, "IR_EXTEND_BYTE2DOUBLE_S") == 0) return IR_EXTEND_BYTE2DOUBLE_S;
    if (strcmp(input + 1, "IR_EXTEND_BYTE2HALF_S") == 0) return IR_EXTEND_BYTE2HALF_S;
    if (strcmp(input + 1, "IR_EXTEND_DOUBLE2QUAD_U") == 0) return IR_EXTEND_DOUBLE2QUAD_U;
    if (strcmp(input + 1, "IR_EXTEND_HALF2QUAD_U") == 0) return IR_EXTEND_HALF2QUAD_U;
    if (strcmp(input + 1, "IR_EXTEND_BYTE2QUAD_U") == 0) return IR_EXTEND_BYTE2QUAD_U;
    if (strcmp(input + 1, "IR_EXTEND_HALF2DOUBLE_U") == 0) return IR_EXTEND_HALF2DOUBLE_U;
    if (strcmp(input + 1, "IR_EXTEND_BYTE2DOUBLE_U") == 0) return IR_EXTEND_BYTE2DOUBLE_U;
    if (strcmp(input + 1, "IR_EXTEND_BYTE2HALF_U") == 0) return IR_EXTEND_BYTE2HALF_U;
    if (strcmp(input + 1, "IR_COPY_DATA") == 0) return IR_COPY_DATA;
  }
  
  return IR_PHI;
}

void yyerror(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
    exit(1);
}


Decl* createDecl(char *start_nonterm, char *identifier, int value) {
    Decl *declaration = (Decl *)malloc(sizeof(Decl));
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
