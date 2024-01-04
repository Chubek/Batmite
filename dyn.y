%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

typedef enum {
	REG_GENERAL,
	REG_EXTENDED,
	REG_FLOATING,
	REG_SIMD,
	REG_SEGMENT,
	REG_INSTPOINTER,
	REG_STATUS,
	REG_MODELSPECIFIC,
	REG_PROGRRAMCOUNTER,
	REG_STACKPOINTER,
	REG_FRAMEPOINTER,
	REG_LINK,
	REG_SYSTEM,
	REG_TLB,
	REG_EXCEPTION,
	REG_INTEGER,
	REG_VECTOR,
	REG_ZERO,
	REG_GLOBAL,
	REG_LOCAL,
} RegisterKind;

typedef struct {
       RegisterKind kind;
       int number;
       char *name;
} Register;

typedef struct {
	char *value;
	Tree *left;
	Tree *right;
} TreeLeaf;

typedef struct {
	Tree *root;
} Tree;

int yylex(void);

Tree *createTree(void);
TreeLeaf *createLeaf(char *value);
Tree *addLeft(Tree *tree, TreeLeaf *left);
Tree *addRight(Tree *tree, TreeLeaf *right);

int ahoJohnsonDP(DAGNode* node);
Register* code(TreeNode *node, int j);
Register* createRegister();
void issueInstruction(char operator, Register *result, Register *operands[], int operandCount);

%}

%union {
    char *strVal;
    int intVal;
    Tree *treeVal;
}

%token <strVal> VALUE
%type <treeVal> tree leaf

%%

tree: /* empty */ 	{ $$ = createTree(); }
    | leaf         	{ $$ = $1; }

leaf: VALUE            	{ $$ = createLeaf($1); }
    | leaf '<' tree '>' { $$ = addLeft($1, $3->root, $2); }
    | leaf '>' tree '<' { $$ = addRight($1, $3->root, $2); }


%%

int main(void) {
    yyparse();
    return 0;
}

Tree *createTree(void) {
    Tree *tree = (Tree *)zalloc(sizeof(Tree));
    if (tree == NULL) {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }
    tree->root = NULL;
    return tree;
}

TreeLeaf *createLeaf(char *value) {
    TreeLeaf *leaf = (TreeLeaf *)zalloc(sizeof(TreeLeaf));
    if (leaf == NULL) {
        fprintf(stderr, "Memory allocation error\n");
        exit(EXIT_FAILURE);
    }
    leaf->value = zStrDup(value);
    leaf->left = NULL;
    leaf->right = NULL;
    return leaf;
}

Tree *addLeft(Tree *tree, TreeLeaf *parent, char *value) {
    if (tree == NULL || value == NULL) {
        fprintf(stderr, "Invalid tree or value\n");
        exit(EXIT_FAILURE);
    }

    TreeLeaf *newLeaf = createLeaf(value);

    if (parent == NULL) {
        tree->root = newLeaf;
    } else {        
        parent->left = newLeaf;
    }

    return tree;
}

Tree *addRight(Tree *tree, TreeLeaf *parent, char *value) {
    if (tree == NULL || value == NULL) {
        fprintf(stderr, "Invalid tree or value\n");
        exit(EXIT_FAILURE);
    }

    TreeLeaf *newLeaf = createLeaf(value);

    if (parent == NULL) {        
        tree->root = newLeaf;
    } else {        
        parent->right = newLeaf;
    }

    return tree;
}

int* memo_table;


Register* code(TreeNode *node, int j) {
    if (node == NULL) {
        return NULL;
    }

    int k = 0; 
    Register *registers[k];

    
    for (int t = 1; t <= k; t++) {
        registers[t - 1] = code(subtree, j - t + 1);
    }

    
    Register *result;
    if (k > 0) {
        result = registers[0];
    } else {
        result = alloc();
    }

    issueInstruction(node->operator, result, registers, k);
    return result;
}


void yyerror(const char* s) {
    fprintf(stderr, "Parser error: %s\n", s);
    exit(EXIT_FAILURE);
}

