%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yyerror(const char *msg);
int yylex(void);

typedef enum {
	TERM_IR_OPCODE,
	TERM_NONTERM,
} TermKind;

typedef struct {
	TermKind kind;
	char *value;
} Term;

typedef struct {
	int cost;
} Cost;

typedef struct {
	Term *term;
	Tree *leftSubtree, *rightSubtree;
} Tree;

typedef struct {
	char *nonterm;
	Tree *tree;
	Cost *cost;
	char *semanticAction;
} Rule;

typedef struct {
	Term **terms;
	int numTerms;
	Rule *startRule;
} Declaration;

typedef struct {
	Declaration **decls;
	int numDecls;
	char *preludeSigma, concludeSigma;
} Grammar;

Term *createTerm(TermKind kind, char *value);
Cost *createCost(int costValue);
Tree *createTree(Term *term, Tree *leftSubtree, Tree *rightSubtree);
Tree *addLeftSubtree(Tree **root, Term *term);
Tree *addRightSubtree(Tree **root, Term *term);
Rule *createRule(char *nonterm, Tree *tree, Cost *cost, char *semanticAction);
Declaration* createDeclaration(Term **terms, int numTerms, Rule *startRule);
Grammar* createGrammar(Declaration **decls, int numDecls, char *preludeSigma, char *concludeSigma);

%}

%union {
    char *stringVal;
    char *sigmaVal;
    int intVal;
    Grammar *grammarVal;
    Tree *treeVal;
    Rule *ruleVal;
    Cost *costVal;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM  NEWLINE
/*	"%%"		 "%start"	"%term    */


%token <sigmaVal> SEMANTIC_ACTION PRELUDE CONCLUDE
%token <stringVal> NONTERM IR_OPCODE
%token <intVal> INTEGER

%type <stringVal> nonterm term
%type <intVal> cost tree

%%

grammar: NEWLINE
       | declaration_list PERCENT_PERCENT rule_list
       | PRELUDE declarations_list PERCENT_PERCENT rule_list
       | PRELUDE declarations_list PERCENT_PERCENT rule_list PERCENT_PERCENT CONCLUDE
       ;

declaration_list: /* Empty */ 
	        | declaration_list declaration
		;

declaration: PERCENT_START nonterm
           | PERCENT_TERM IDENTIFIER '=' INTEGER
           ;

rule_list: /* Empty */ 
	 | rule_list rule
	 ;

rule: NONTERM ':' tree '=' cost ';'
    | NONTERM ':' tree '=' cost  SEMANTIC_ACTION  ';'
    ;

cost: '(' INTEGER ')'
    ;

tree: /* Empty */
    | '|'
    | term '(' tree ')'
    | term
    ;

term: IR_OPCODE
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
	char *buffer = (char*)zAlloc(MAX_TOKEN_LENGTH);
	int i = 0;
	int step = 1;
	while ((c = getchar()) != EOF) {
		buffer[i++] = c;
		if (i == MAX_TOKEN_LENGTH - 1) {
			buffer = (char*)zRealloc(buffer, MAX_TOKEN_LENGTH * ++step);	
		}
	}
	yylval.sigmaVal = buffer;
	return CONDLUE;
    }

    else
        return c;

    return 0; 
}

Term* createTerm(TermKind kind, char *value) {
    Term *term = (Term*)zAlloc(sizeof(Term));
    term->kind = kind;
    term->value = value;
    return term;
}

Cost* createCost(int costValue) {
    Cost *cost = (Cost*)zAlloc(sizeof(Cost));
    cost->cost = costValue;
    return cost;
}

Tree* createTree(Term *term, Tree *leftSubtree, Tree *rightSubtree) {
    Tree *tree = (Tree*)zAlloc(sizeof(Tree));
    tree->term = term;
    tree->leftSubtree = leftSubtree;
    tree->rightSubtree = rightSubtree;
    return tree;
}

Tree* addLeftSubtree(Tree **root, Term *term) {
    if (*root == NULL) {
        fprintf(stderr, "Error: Cannot add left subtree to a NULL tree.\n");
        exit(EXIT_FAILURE);
    }

    (*root)->leftSubtree = createTree(term, NULL, NULL);
    return (*root)->leftSubtree;
}

Tree* addRightSubtree(Tree **root, Term *term) {
    if (*root == NULL) {
        fprintf(stderr, "Error: Cannot add right subtree to a NULL tree.\n");
        exit(EXIT_FAILURE);
    }

    (*root)->rightSubtree = createTree(term, NULL, NULL);
    return (*root)->rightSubtree;
}

Rule* createRule(char *nonterm, Tree *tree, Cost *cost, char *semanticAction) {
    Rule *rule = (Rule*)zAlloc(sizeof(Rule));
    rule->nonterm = nonterm;
    rule->tree = tree;
    rule->cost = cost;
    rule->semanticAction = semanticAction;
    return rule;
}

Declaration* createDeclaration(Term **terms, int numTerms, Rule *startRule) {
    Declaration *declaration = (Declaration*)zAlloc(sizeof(Declaration));
    declaration->terms = terms;
    declaration->numTerms = numTerms;
    declaration->startRule = startRule;
    return declaration;
}

Grammar* createGrammar(Declaration **decls, int numDecls, char *preludeSigma, char *concludeSigma) {
    Grammar *grammar = (Grammar*)zAlloc(sizeof(Grammar));
    grammar->decls = decls;
    grammar->numDecls = numDecls;
    grammar->preludeSigma = preludeSigma;
    grammar->concludeSigma = concludeSigma;
    return grammar;
}

