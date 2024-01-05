%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

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
	Rule **rules;
	int numDecls;
	int numRules;
	char *preludeSigma, concludeSigma;
} Grammar;

Term *createTerm(TermKind kind, char *value);
Cost *createCost(int costValue);
Tree *createTree(Term *term, Tree *leftSubtree, Tree *rightSubtree);
Rule *createRule(char *nonterm, Tree *tree, Cost *cost, char *semanticAction);
Rule *createRuleList(Rule **rules, int numRules);
Declaration* createDeclaration(Term **terms, int numTerms, Rule *startRule);
Grammar* createGrammar(Declaration **decls, int numDecls, 
			Rule **rules, int numRules,
			char *preludeSigma, char *concludeSigma);


static inline void installIndent(int level);
static inline void installSwitch(char *s);
static inline void installCase(char **c, int n, char *a);
static inline void installFunctionDecl(char *ret, char *name, char **params, int nparams, char term);
static inline void installBlockOpen(void);
static inline void installBlockClose(void);
static inline void installIfElseStatement(char **cond, char **t, int ntc, char *f);
static inline void installFunctionCall(char *name, char **args, int nargs);
static inline void installWhileLoop(char *cond, char *body);
static inline void installForLoop(char *cond, char *body);
static inline void installAssignment(char *type, char *lhs, char *rhs);
static inline void installObjectMacro(char *name, char *value);
static inline void installStructure(char *name, char **members, int nmemb);
static inline void installEnumeration(char *name, char **members, int nmemb);
static inline void installUnion(char *name, char **members, int nmemb);
static inline void installArrayLiteral(char *type, char *name, char **elements, int nelements);
static inline void installArrayAccess(char *target, char *index);
static inline void installPointerAccess(char *target, char *member);
static inline void installMemberAccess(char *target, char *member);

void generateCode(Grammar *grammar);

void generateDeclaration(Declaration *declaration);
void generateRule(Rule *rule);
void generateTree(Tree *tree);
void generateTerm(Term *term);
void generateCost(Cost *cost);
void generateSwitch(Rule *rule);
void generateStateFunction(Grammar *grammar);
void generateTreeMatcher(Tree *tree, char *nonterm, int costIndex);

void error(const char *msg, ...);

int yyparser(const char *msg);
int yylex(void);

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
%token <grammarVal> grammar

%type <stringVal> nonterm term
%type <intVal> cost tree

%%

grammar: NEWLINE {
    
}
| declaration_list PERCENT_PERCENT rule_list {
    $$ = createGrammar($1, $<intVal>1, $3, $<intVal>3, NULL, NULL);
    generateCode($$);
}
| PRELUDE declarations_list PERCENT_PERCENT rule_list {
    $$ = createGrammar($2, $<intVal>2, $4, $<intval>4, $1, NULL);
    generateCode($$);
}
| PRELUDE declarations_list PERCENT_PERCENT rule_list PERCENT_PERCENT CONCLUDE {
    $$ = createGrammar($2, $<intVal>2, $4, $<intval>4, $1, $6);
    generateCode($$);
};

declaration_list:
| declaration_list declaration {
    $$ = zRealloc($1, ($<intVal>1 + 1) * sizeof(Declaration *));
    $$[$<intVal>1] = $2;
    $<intVal>1 += 1;
}
| /* Empty */ {
    $$ = NULL;
    $<intVal>1 = 0;
};

declaration: PERCENT_START nonterm {
    $$ = createDeclaration(NULL, 0, createRule($2, NULL, NULL, NULL));
}
| PERCENT_TERM IDENTIFIER '=' INTEGER {
    Term *term = createTerm(TERM_IR_OPCODE, $3);
    Rule *rule = createRule($2, NULL, createCost($5), NULL);
    $$ = createDeclaration(&term, 1, rule);
};

rule_list:
| rule_list rule {
    $$ = zRealloc($1, ($<intVal>1 + 1) * sizeof(Rule *));
    $$[$<intVal>1] = $2;
    $<intVal>1 += 1;
}
| /* Empty */ {
    $$ = NULL;
    $<intVal>1 = 0;
};

rule: nonterm ':' tree '=' cost ';' {
    $$ = createRule($1, $3, $5, NULL);
}
| nonterm ':' tree '=' cost SEMANTIC_ACTION ';' {
    $$ = createRule($1, $3, $5, $6);
};

cost: '(' INTEGER ')' {
    $$ = createCost($2);
};

tree: '|' {
    $$ = NULL;  
}
| term '(' tree ',' tree ')' {
    $$ = createTree($1, $3, $5);
}
| term '(' tree ')' {
    $$ = createTree($1, $3, NULL);
}
| term {
    $$ = createTree($1, NULL, NULL);
};

term: IR_OPCODE {
    $$ = createTerm(TERM_IR_OPCODE, $1);
}
| NONTERM {
    $$ = createTerm(TERM_NONTERM, $1);
};

nonterm: NONTERM {
    $$ = $1;
};

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

Term *createTerm(TermKind kind, char *value) {
    Term *term = (Term*)zAlloc(sizeof(Term));
    term->kind = kind;
    term->value = value;
    return term;
}

Cost *createCost(int costValue) {
    Cost *cost = (Cost*)zAlloc(sizeof(Cost));
    cost->cost = costValue;
    return cost;
}

Tree *createTree(Term *term, Tree *leftSubtree, Tree *rightSubtree) {
    Tree *tree = (Tree*)zAlloc(sizeof(Tree));
    tree->term = term;
    tree->leftSubtree = leftSubtree;
    tree->rightSubtree = rightSubtree;
    return tree;
}

Rule *createRule(char *nonterm, Tree *tree, Cost *cost, char *semanticAction) {
    Rule *rule = (Rule*)zAlloc(sizeof(Rule));
    rule->nonterm = nonterm;
    rule->tree = tree;
    rule->cost = cost;
    rule->semanticAction = semanticAction;
    return rule;
}

Rule 

Declaration *createDeclaration(Term **terms, int numTerms, Rule *startRule) {
    Declaration *declaration = (Declaration*)zAlloc(sizeof(Declaration));
    declaration->terms = terms;
    declaration->numTerms = numTerms;
    declaration->startRule = startRule;
    return declaration;
}

Grammar *createGrammar(Declaration **decls, int numDecls, 
			Rule **rules, int numRules;
			char *preludeSigma, char *concludeSigma) {
    Grammar *grammar = (Grammar*)zAlloc(sizeof(Grammar));
    grammar->decls = decls;
    grammar->numDecls = numDecls;
    gramamr->rules = rules;
    grammar->numRules = numRules;
    grammar->preludeSigma = preludeSigma;
    grammar->concludeSigma = concludeSigma;
    return grammar;
}

static inline void installIndent(int level) {
    for (int i = 0; i < level; i++) {
        printf("    ");
    }
}


static inline void installSwitch(char *s) {
    printf("switch (%s)", s);
}

static inline void installCase(char **c, int n, char *a) {
   while (--n)
   	printf("case %s:", c[i]);
   printf("%s", a);
}

static inline void installFunctionDecl(char *ret, char *name, char **params, int nparams, char term) {
    printf("%s %s(", ret, name);
    int i = 0;
    while (i++ < nparams - 1) {
	printf("%s,", *params++);
    }
    printf("%s)%c", *params, term);
}

static inline void installBlockOpen(void) { printf(" {"); }
static inline void installBlockClose(void) { printf(" }"); }

static inline void installIfElseStatement(char **cond, char **t, int ntc, char *f) {
  printf("if (%s) { %s; }", *cond, *t);
  
  int i = 0;
  while (i++ < ntc) {
     printf("else if (%s) { %s; }", *cond++, *t++);
  }

  if (f != NULL) {
	printf("else { %s; }", f);
  }
}

static inline void installFunctionCall(char *name, char **args, int nargs) {
    printf("%s(", name);
    int i = 0;
    while (i++ < nargs - 1) {
	printf("%s,", *args++);
    }
    printf("%s)", *args);
}

static inline void installWhileLoop(char *cond, char *body) {
   printf("while (%s) { %s; }", cond, body);
}

static inline void installForLoop(char *cond, char *body) {
   printf("for (%s) { %s; }", cond, body);
}

static inline void installAssignment(char *type, char *lhs, char *rhs) {
  printf("%s %s = %s;");
}

static inline void installStructure(char *name, char **members, int nmemb) {
    printf("struct %s {", name);
    
    for (int i = 0; i < nmemb; ++i) {
        printf("%s;", *members++);
    }
    
    printf("};");
}

static inline void installEnumeration(char *name, char **members, int nmemb) {
    printf("enum %s {", name);
    
    for (int i = 0; i < nmemb - 1; ++i) {
        printf("%s,", *members++);
    }
    
    printf("%s};", *members);
}

static inline void installUnion(char *name, char **members, int nmemb) {
    printf("union %s {", name);
    
    for (int i = 0; i < nmemb; ++i) {
        printf("%s;", *members++);
    }
    
    printf("};");
}

static inline void installArrayLiteral(char *type, char *name, char **elements, int nelements) {
    printf("%s %s[] = {", type, name);
    
    for (int i = 0; i < nelements - 1; ++i) {
        printf("%s, ", elements[i]);
    }
    
    printf("%s};", elements[nelements - 1]);
}

static inline void installArrayAccess(char *target, char *index) {
    printf("%s[%s];", target, index);
}

static inline void installPointerAccess(char *target, char *member) {
   printf("%s->%s", target, index);
}

static inline void installMemberAccess(char *target, char *member) {
  printf("%s.%s", target, member);
}

void generateCode(Grammar *grammar) {
    if (!grammar) {
        error("Invalid grammar");
        return;
    }

    
    if (grammar->preludeSigma) {
        printf("%s", grammar->preludeSigma);
    }
   
    generateStateFunction(grammar);
    
    for (int i = 0; i < grammar->numDecls; i++) {
        generateDeclaration(grammar->decls[i]);
    }
    
    for (int i = 0; i < grammar->numRules; i++) {
        generateRule(grammar->rules[i]);
    }
    
    if (grammar->concludeSigma) {
        printf("%s", grammar->concludeSigma);
    }
}


void generateDeclaration(Declaration *declaration) {
    if (!declaration) {
        error("Invalid declaration");
        return;
    }

    for (int i = 0; i < declaration->numTerms; i++) {
        generateRule(declaration->startRule);
    }
}

void generateRule(Rule *rule) {
    if (!rule) {
        error("Invalid rule");
        return;
    }

    
    installIndent(installIndentLevel);
    printf("/* Rule for %s */\n", rule->nonterm);
    
    generateTree(rule->tree);

    
    if (rule->semanticAction) {
        installIndent(installIndentLevel);
        installBlockOpen();
        installIndentLevel++;
        installIndent(installIndentLevel);
        printf("%s", rule->semanticAction);
        installIndentLevel--;
        installIndent(installIndentLevel);
        installBlockClose();
    }
}

void generateTree(Tree *tree) {
    if (!tree) {
        error("Invalid tree");
        return;
    }
    
    if (tree->leftSubtree) {
        generateTree(tree->leftSubtree);
    }
    
    generateTerm(tree->term);
    
    if (tree->rightSubtree) {
        generateTree(tree->rightSubtree);
    }
}

void generateTerm(Term *term) {
    if (!term) {
        error("Invalid term");
        return;
    }

    installIndent(installIndentLevel);
    switch (term->kind) {
        case TERM_IR_OPCODE:
            installObjectMacro("IR_OPCODE", term->value);
            break;
        case TERM_NONTERM:
            installObjectMacro("NONTERM", term->value);
            break;
    }
}

void generateCost(Cost *cost) {
    if (!cost) {
        error("Invalid cost");
        return;
    }    
    installIndent(installIndentLevel);
    installFunctionCall("createCost", cost->cost);
}

void generateTreeMatcher(Tree *tree, char *nonterm, int costIndex) {
    if (tree == NULL) {
        
        printf("return createTree(%s, NULL, NULL);", nonterm);
    } else {
        
        int leftCostIndex = costIndex * 2 + 1;
        int rightCostIndex = costIndex * 2 + 2;

        printf("{\n");
        installBlockOpen();

        
        printf("Tree *leftSubtree = ");
        generateTreeMatcher(tree->leftSubtree, nonterm, leftCostIndex);
        printf(";\n");

        
        printf("Tree *rightSubtree = ");
        generateTreeMatcher(tree->rightSubtree, nonterm, rightCostIndex);
        printf(";\n");

        
        printf("if (t->cost[%d] > t->cost[%d]) {\n", costIndex, leftCostIndex);
        installBlockOpen();
        printf("t->cost[%d] = t->cost[%d];\n", costIndex, leftCostIndex);
        printf("t->rule[%d] = %s;\n", costIndex, nonterm);
        installBlockClose();
        printf("}\n");

        printf("if (t->cost[%d] > t->cost[%d]) {\n", costIndex, rightCostIndex);
        installBlockOpen();
        printf("t->cost[%d] = t->cost[%d];\n", costIndex, rightCostIndex);
        printf("t->rule[%d] = %s;\n", costIndex, nonterm);
        installBlockClose();
        printf("}\n");

        
        printf("return createTree(%s, leftSubtree, rightSubtree);", nonterm);

        installBlockClose();
        printf("}\n");
    }
}

void generateStateFunction(Grammar *grammar) {
    printf("State *state(Tree *t) {\n");
    installBlockOpen();

    installSwitch("t->term->value");

    Rule **rules = grammar->rules;
    for (int i = 0; i < grammar->numRules; ++i) {
        printf("case %s: ", rules[i]->nonterm);
        generateTreeMatcher(rules[i]->tree);
        printf(" break;");
    }

    installBlockClose();
    printf("}\n\n");
}

void generateSwitch(Rule *rule) {
    if (!rule) {
        error("Invalid rule");
        return;
    }

    installIndent(1);
    printf("case %s:\n", rule->nonterm);
    installIndent(2);
    printf("if (!%s) return %s;\n", "t", rule->semanticAction);
}

void error(const char *msg, ...) {
    va_list args;
    va_start(args, msg);
    vfprintf(stderr, msg, args);
    fprintf(stderr, "\n");
    va_end(args);
}
