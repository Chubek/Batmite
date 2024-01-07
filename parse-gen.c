#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <stdbool.h>

typedef enum {
    IDENTIFIER,
    INTEGER,
    USER_CODE,
    PERCENT,
    START,
    TERM,
    EQUAL,
    SEMICOLON,
    COLON,
    LPAREN,
    RPAREN,
    LCURLY,
    RCURLY,
    COMMA,
    PERCENT_PERCENT
} TokenType;


typedef struct {
    TokenType type;
    char* lexeme;
} Token;


typedef struct TreeNode {
    char* value;
    struct TreeNode* left;
    struct TreeNode* right;
} TreeNode;


typedef void (*VisitorFunc)(const TreeNode*);


Token* createToken(TokenType type, const char* lexeme) {
    Token* token = (Token*)malloc(sizeof(Token));
    token->type = type;
    token->lexeme = strdup(lexeme);
    return token;
}


void freeToken(Token* token) {
    free(token->lexeme);
    free(token);
}


TreeNode* createTreeNode(const char* value, TreeNode* left, TreeNode* right) {
    TreeNode* node = (TreeNode*)malloc(sizeof(TreeNode));
    node->value = strdup(value);
    node->left = left;
    node->right = right;
    return node;
}


void freeTreeNode(TreeNode* node) {
    free(node->value);
    free(node);
}


Token* ungotToken = NULL;
bool onUserCode = false;
int percentPercentNum = 0;

Token* getNextToken(FILE* fp) {
    if (ungotToken) {
        Token* token = ungotToken;
        ungotToken = NULL;
        return token;
    }

    int c = fgetc(fp);

    while (isspace(c)) {
        c = fgetc(fp);
    }

    if (c == EOF) {
        return createToken(EOF, "");
    }
    
    if (onUserCode || percentPercentNum == 2) {
	char *userCode = calloc(1, 1024);
	int i = 0;
	userCode[i++] = c;
	for (;;) {
	   userCode[i++] = c = fgetc(fp);
	   if (c == '%' || c == EOF) {
		char next = (c == EOF) ? '}' : fgetc(fp);
		if (next == '}') {
			onUserCode = false;
			return createToken(USER_CODE, userCode);
		}
		ungetc(next, fp);
	   }
	   if (!(i % 1024)) {
		userCode = realloc(i + 1024);
	   }
	}
    }

    if (c == '%') {
        c = fgetc(fp);
        if (c == '{') {
	    onUseCode = true;
            return createToken(PERCENT, "%{");
        } else if (c == '%') {
	    percentPercentNum++;
            return createToken(PERCENT_PERCENT, "%%");
        } else {
            ungetc(c, fp);
            return createToken(PERCENT, "%");
        }
    } else if (c == ',') {
    	return createToken(COMMA, ",");
    } else if (c == '}') {
        return createToken(RCURLY, "}");
    } else if (c == '{') {
        return createToken(LCURLY, "{");
    } else if (c == ':') {
        return createToken(COLON, ":");
    } else if (c == ';') {
        return createToken(SEMICOLON, ";");
    } else if (c == '=') {
        return createToken(EQUAL, "=");
    } else if (c == '(') {
        return createToken(LPAREN, "(");
    } else if (c == ')') {
        return createToken(RPAREN, ")");
    } else if (isalpha(c) || c == '_') {       
        char lexeme[100];
        int i = 0;
        lexeme[i++] = c;
        while ((c = fgetc(fp)) && (isalnum(c) || c == '_')) {
            lexeme[i++] = c;
        }
        lexeme[i] = '\0';

        if (strcmp(lexeme, "%start") == 0) {
            return createToken(START, lexeme);
        } else if (strcmp(lexeme, "%term") == 0) {
            return createToken(TERM, lexeme);
        } else {
            return createToken(IDENTIFIER, lexeme);
        }
    } else if (isdigit(c)) {        
        char lexeme[100];
        int i = 0;
        lexeme[i++] = c;
        while ((c = fgetc(fp)) && isdigit(c)) {
            lexeme[i++] = c;
        }
        lexeme[i] = '\0';
        return createToken(INTEGER, lexeme);
    } else {
        fprintf(stderr, "Error: Unexpected character: %c\n", c);
        exit(EXIT_FAILURE);
    }
}

void ungetToken(Token* token) {
    if (ungotToken) {
        fprintf(stderr, "Error: ungetToken called twice without consuming token\n");
        exit(EXIT_FAILURE);
    }

    ungotToken = malloc(sizeof(Token));
    if (!ungotToken) {
        fprintf(stderr, "Error: Failed to allocate memory for ungotToken\n");
        exit(EXIT_FAILURE);
    }

    memcpy(ungotToken, token, sizeof(Token));
}

TreeNode* parseSpec(FILE* fp);
TreeNode* parseHead(FILE* fp);
TreeNode* parseTrail(FILE* fp);
TreeNode* parseDcl(FILE* fp);
TreeNode* parseRule(FILE* fp);
TreeNode* parseCost(FILE* fp);
TreeNode* parseTree(FILE* fp);
TreeNode* parseUserCode(FILE* fp);
TreeNode* parseTerm(FILE* fp);
TreeNode* parseNonterm(FILE*fp);
TreeNode* parseIdent(FILE* fp);
TreeNode* parseAny(FILE* fp);


void visitSpec(const TreeNode* node);
void visitHead(const TreeNode* node);
void visitTrail(const TreeNode* node);
void visitDcl(const TreeNode* node);
void visitRule(const TreeNode* node);
void visitCost(const TreeNode* node);
void visitTree(const TreeNode* node);
void visitCCode(const TreeNode* node);
void visitTerm(const TreeNode* node);
void visitNonterm(const TreeNode* node);
void visitIdent(const TreeNode* node);
void visitAny(const TreeNode* node);


void applyVisitor(const TreeNode* node, VisitorFunc visitor);


int main() {
    FILE* fp = fopen("input.txt", "r");
    if (!fp) {
        perror("Error opening input file");
        return EXIT_FAILURE;
    }

    TreeNode* spec = parseSpec(fp);
    fclose(fp);

    applyVisitor(spec, visitSpec);
    applyVisitor(spec, (VisitorFunc)freeTreeNode);

    return 0;
}


TreeNode* parseSpec(FILE* fp) {
    TreeNode* userDef = parseUserCode(fp);
    TreeNode* head = parseHead(fp);
    TreeNode* dcl = parseDcl(fp);
    TreeNode* trail = parseTrail(fp);
    TreeNode* userCode = parseUserCode(fp);
    return createTreeNode("spec", head, createTreeNode("dcl", dcl, trail));
}

TreeNode* parseHead(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == PERCENT_PERCENT) {
        freeToken(token);
        return createTreeNode("head", NULL, NULL);
    } else if (token->type == PERCENT) {
        freeToken(token);
        TreeNode* userCode = parseUserCode(fp);
        return createTreeNode("head", userCode, NULL);
    } else {
        fprintf(stderr, "Error: Expected '%%' or '%{' in head\n");
        exit(EXIT_FAILURE);
    }
}

TreeNode* parseDcl(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == START || token->type == TERM) {
        TreeNode* declaration = createTreeNode(token->lexeme, NULL, NULL);
        freeToken(token);

        token = getNextToken(fp);
        if (token->type == IDENTIFIER) {
            TreeNode* identifier = createTreeNode(token->lexeme, NULL, NULL);
            freeToken(token);

            token = getNextToken(fp);
            if (token->type == LCURLY) {
                freeToken(token);

                TreeNode* trail = parseTrail(fp);

                token = getNextToken(fp);
                if (token->type == RCURLY) {
                    freeToken(token);
                    return createTreeNode("declaration", identifier, trail);
                } else {
                    fprintf(stderr, "Error: Expected '}' in declaration\n");
                    exit(EXIT_FAILURE);
                }
            } else {
                fprintf(stderr, "Error: Expected '{' in declaration\n");
                exit(EXIT_FAILURE);
            }
        } else {
            fprintf(stderr, "Error: Expected an identifier in declaration\n");
            exit(EXIT_FAILURE);
        }
    } else {
        fprintf(stderr, "Error: Expected '%%start' or '%%term' in declaration\n");
        exit(EXIT_FAILURE);
    }
}

TreeNode* parseRule(FILE* fp) {
    TreeNode* nonterm = parseNonterm(fp);

    Token* token = getNextToken(fp);
    if (token->type == COLON) {
        freeToken(token);

        TreeNode* tree = parseTree(fp);

        token = getNextToken(fp);
        if (token->type == EQUAL) {
            freeToken(token);

            TreeNode* integer = parseIdent(fp);

            token = getNextToken(fp);
            if (token->type == SEMICOLON) {
                freeToken(token);

                token = getNextToken(fp);
                if (token->type == LPAREN) {
                    freeToken(token);

                    TreeNode* cost = parseCost(fp);

                    token = getNextToken(fp);
                    if (token->type == RPAREN) {
                        freeToken(token);

                        return createTreeNode("rule", nonterm, createTreeNode("rule-details", tree, createTreeNode("cost", integer, cost)));
                    } else {
                        fprintf(stderr, "Error: Expected ')' after cost\n");
                        exit(EXIT_FAILURE);
                    }
                } else {
                    ungetToken(token);
                    return createTreeNode("rule", nonterm, createTreeNode("rule-details", tree, createTreeNode("cost", integer, NULL)));
                }
            } else {
                fprintf(stderr, "Error: Expected ';' at the end of the rule\n");
                exit(EXIT_FAILURE);
            }
        } else {
            fprintf(stderr, "Error: Expected '=' in the rule\n");
            exit(EXIT_FAILURE);
        }
    } else {
        fprintf(stderr, "Error: Expected ':' after nonterminal\n");
        exit(EXIT_FAILURE);
    }
}

TreeNode* parseCost(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == LPAREN) {
        freeToken(token);

        TreeNode* integer = parseIdent(fp);

        token = getNextToken(fp);
        if (token->type == RPAREN) {
            freeToken(token);
            return createTreeNode("cost", integer, NULL);
        } else {
            fprintf(stderr, "Error: Expected ')' after cost value\n");
            exit(EXIT_FAILURE);
        }
    } else {
        ungetToken(token);
        return createTreeNode("cost", NULL, NULL);
    }
}

TreeNode* parseTree(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == IDENTIFIER) {
        TreeNode* term = parseTerm(fp);

        token = getNextToken(fp);
        if (token->type == LPAREN) {
            freeToken(token);

            TreeNode* left = parseTree(fp);

            token = getNextToken(fp);
            if (token->type == COMMA) {
                freeToken(token);

                TreeNode* right = parseTree(fp);

                token = getNextToken(fp);
                if (token->type == RPAREN) {
                    freeToken(token);
                    return createTreeNode("tree", term, createTreeNode("tree-details", left, right));
                } else {
                    fprintf(stderr, "Error: Expected ')' after right subtree\n");
                    exit(EXIT_FAILURE);
                }
            } else if (token->type == RPAREN) {
                freeToken(token);
                return createTreeNode("tree", term, createTreeNode("tree-details", left, NULL));
            } else {
                fprintf(stderr, "Error: Expected ',' or ')' in tree expression\n");
                exit(EXIT_FAILURE);
            }
        } else if (token->type == RPAREN) {
            freeToken(token);
            return createTreeNode("tree", term, NULL);
        } else {
            fprintf(stderr, "Error: Expected '(' or ')' in tree expression\n");
            exit(EXIT_FAILURE);
        }
    } else {
        ungetToken(token);
        return parseNonterm(fp);
    }
}


TreeNode* parseTerm(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == IDENTIFIER) {
        TreeNode* ident = createTreeNode(token->lexeme, NULL, NULL);
        freeToken(token);
        return createTreeNode("term", ident, NULL);
    } else {
        fprintf(stderr, "Error: Expected an identifier for term\n");
        exit(EXIT_FAILURE);
    }
}

TreeNode* parseNonterm(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == IDENTIFIER) {
        TreeNode* ident = createTreeNode(token->lexeme, NULL, NULL);
        freeToken(token);
        return createTreeNode("nonterm", ident, NULL);
    } else {
        fprintf(stderr, "Error: Expected an identifier for nonterm\n");
        exit(EXIT_FAILURE);
    }
}

TreeNode* parseIdent(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == IDENTIFIER) {
        TreeNode* ident = createTreeNode(token->lexeme, NULL, NULL);
        freeToken(token);
        return ident;
    } else {
        fprintf(stderr, "Error: Expected an identifier\n");
        exit(EXIT_FAILURE);
    }
}

TreeNode* parseUserCode(FILE* fp) {
    Token* token = getNextToken(fp);
    if (token->type == USER_CODE) {
        TreeNode* userCode = createTreeNode(token->lexeme, NULL, NULL);
        freeToken(token);
        return userCode;
    } else {
        fprintf(stderr, "Error: Expected C code\n");
        exit(EXIT_FAILURE);
    }
}


void visitSpec(const TreeNode* node) {
    printf("<spec>\n");
    applyVisitor(node->left, visitHead);
    applyVisitor(node->right, visitDcl);
    printf("</spec>\n");
}

void visitHead(const TreeNode* node) {
    if (node) {
        printf("<head>\n");
        applyVisitor(node, visitCCode);
        printf("</head>\n");
    }
}

void visitTrail(const TreeNode* node) {
    if (node) {
        printf("<trail>\n");
        applyVisitor(node, visitCCode);
        printf("</trail>\n");
    }
}

void visitDcl(const TreeNode* node) {
    if (node) {
        printf("<dcl>\n");
        
        applyVisitor(node->left, visitIdent);
        applyVisitor(node->right, visitTrail);
        printf("</dcl>\n");
    }
}

void visitRule(const TreeNode* node) {
    if (node) {
        printf("<rule>\n");
        applyVisitor(node->left, visitNonterm);
        applyVisitor(node->right->left, visitTree);
        applyVisitor(node->right->right, visitIdent);
        applyVisitor(node->right->right->right, visitCost);
        printf(";</rule>\n");
    }
}

void visitCost(const TreeNode* node) {
    if (node) {
        printf("<cost>\n");
        applyVisitor(node->left, visitIdent);
        printf("</cost>\n");
    }
}

void visitTree(const TreeNode* node) {
    if (node) {
        printf("<tree>\n");
        applyVisitor(node, visitTerm);
        applyVisitor(node->left->left, visitTree);
        applyVisitor(node->left->right, visitTree);
        printf("</tree>\n");
    }
}

void visitCCode(const TreeNode* node) {
    if (node) {
        printf("<c-code>\n");
        printf("%s", node->value);
        printf("</c-code>\n");
    }
}

void visitTerm(const TreeNode* node) {
    if (node) {
        printf("<term>\n");
        applyVisitor(node, visitIdent);
        printf("</term>\n");
    }
}

void visitNonterm(const TreeNode* node) {
    if (node) {
        printf("<nonterm>\n");
        applyVisitor(node, visitIdent);
        printf("</nonterm>\n");
    }
}

void visitIdent(const TreeNode* node) {
    if (node) {
        printf("<ident>%s</ident>\n", node->value);
    }
}

void visitAny(const TreeNode* node) {
    if (node) {
        printf("<any>%s</any>\n", node->value);
    }
}


void applyVisitor(const TreeNode* node, VisitorFunc visitor) {
    if (node) {
        visitor(node);
        applyVisitor(node->left, visitor);
        applyVisitor(node->right, visitor);
    }
}
 
