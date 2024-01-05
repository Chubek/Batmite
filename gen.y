%{
#include <stdio.h>
#include <stdlib.h>

// Data structures
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

// Function prototypes
Declaration* createDecl(char *start_nonterm, char *identifier, int value);
Term* createTerm(char *identifier, int value);
Rule* createRule(char *nonterm, Term *term, int value);
void yyerror(const char *msg);

// Yacc declarations
%union {
    char *stringVal;
    int intVal;
    Declaration *declarationVal;
    Term *termVal;
    Rule *ruleVal;
}

%token PERCENT_PERCENT PERCENT_START PERCENT_TERM NEWLINE COLON EQUAL SEMICOLON LPAREN RPAREN COMMA IDENTIFIER INTEGER

%type <stringVal> nonterm
%type <declarationVal> dcl
%type <termVal> term
%type <ruleVal> rule
%type <intVal> cost

%start spec
%%

spec: NEWLINE { printf("Parsed successfully!\n"); }
    | dcl PERCENT_PERCENT rule_list PERCENT_PERCENT { printf("Parsed successfully!\n"); }
    | PERCENT_PERCENT { printf("Parsed successfully!\n"); };

dcl: PERCENT_START nonterm { $$ = createDecl($2, NULL, 0); }
    | PERCENT_TERM IDENTIFIER '=' INTEGER { $$ = createDecl(NULL, $2, $4); };

rule_list: rule_list rule { /* Add code for handling rule list */ }
    | /* Empty */ { /* Add code for empty rule list */ };

rule: nonterm COLON tree EQUAL INTEGER cost SEMICOLON { /* Add code for handling rule */ }
    | nonterm COLON tree EQUAL INTEGER SEMICOLON { /* Add code for handling rule without cost */ };

cost: LPAREN INTEGER RPAREN { $$ = $2; }
    | /* Empty */ { $$ = 0; };

tree: term LPAREN tree COMMA tree RPAREN { /* Add code for handling tree */ }
    | term LPAREN tree RPAREN { /* Add code for handling tree with one subtree */ }
    | term { /* Add code for handling single term */ }
    | nonterm { /* Add code for handling nonterminal */ };

term: IDENTIFIER { $$ = createTerm($1, 0); }
    | INTEGER { $$ = createTerm(NULL, $1); };

nonterm: IDENTIFIER { $$ = $1; };

%%

// Lexical Analyzer
int yylex(void) {
    int c;
    // Implement a basic lexer for demonstration
    while ((c = getchar()) == ' ' || c == '\t' || c == '\n') {
        // Skip whitespace
    }

    if (c == EOF) {
        return 0; // End of file
    }

    // Tokenize based on single characters for simplicity
    switch (c) {
        case '%': 
		if ((c = getchar) == '%')
			return PERCENT_PERCENT;
		ungetc();
        case '{': return PERCENT_START;
        case '}': return PERCENT_TERM;
        case '\n': return NEWLINE;
        case ':': return COLON;
        case '=': return EQUAL;
        case ';': return SEMICOLON;
        case '(': return LPAREN;
        case ')': return RPAREN;
        case ',': return COMMA;
        default:
            if (isalpha(c)) {
                char buffer[1024];
                int i = 0;
                do {
                    buffer[i++] = c;
                    c = getchar();
                } while (isalnum(c) || c == '_');
                buffer[i] = '\0';
                yylval.stringVal = strdup(buffer);
                ungetc(c, stdin);
                return IDENTIFIER;
            } else if (isdigit(c)) {
                char buffer[1024];
                int i = 0;
                do {
                    buffer[i++] = c;
                    c = getchar();
                } while (isdigit(c));
                buffer[i] = '\0';
                yylval.intVal = atoi(buffer);
                ungetc(c, stdin);
                return INTEGER;
            } else {
                yyerror("Unexpected character");
            }
    }

    return 0; // This should not be reached
}

// Error handler
void yyerror(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
    exit(1);
}

// Helper functions
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
