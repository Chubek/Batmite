%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexer.h"  // Include the lexer header file
%}

%union {
    char *str;
}

%token <str> IDENTIFIER INTEGER_LITERAL OCT_INTEGER_LITERAL BIN_INTEGER_LITERAL HEX_INTEGER_LITERAL FLOAT_LITERAL BOOL_LITERAL CHAR_LITERAL STRING_LITERAL
%token PLUS MINUS TIMES DIVIDE EQ NEQ LT GT LE GE AND OR NOT INC DEC
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET COMMA COLON SEMICOLON ASSIGN
%token FUN VAL TYPE RECORD OF
%token FOR IN DO DONE IF THEN ELSE FI LOCAL END LET MATCH WITH

%type <str> program declaration functionDeclaration variableDeclaration parameterList
%type <str> defineRecord record recordPairList recordPair recordInstPair
%type <str> defineType typeVariantList typeVariant typeList type
%type <str> forExpression ifExpression expression literal octintegerLiteral binintegerLiteral hexintegerLiteral
%type <str> integerLiteral floatLiteral boolLiteral charLiteral stringLiteral
%type <str> binaryOperator unaryOperator argumentList identifier letter lowercase uppercase any-char
%type <str> bin-digit oct-digit hex-digit digit match patternMatches patternMatch pattern
%type <str> literalPattern identifierPattern

%%

program            : declaration
                  | program declaration
                  ;

declaration        : functionDeclaration
                  | variableDeclaration
                  | defineType
                  | defineRecord
                  ;

functionDeclaration : FUN IDENTIFIER LPAREN parameterList RPAREN COLON type ASSIGN expression
                  ;

variableDeclaration : VAL IDENTIFIER COLON type ASSIGN expression
                  ;

parameterList     : IDENTIFIER
                  | parameterList COMMA IDENTIFIER
                  ;

defineRecord      : RECORD IDENTIFIER ASSIGN record
                  ;

record             : LBRACE recordPairList RBRACE
                  ;

recordPairList   : recordPair
                  | recordPairList SEMICOLON recordPair
                  ;

recordPair        : IDENTIFIER COLON type
                  ;

recordInstPair   : IDENTIFIER ASSIGN (identifierPattern | literalPattern)
                  ;

defineType        : TYPE UserDefinedType ASSIGN typeVariantList
                  ;

typeVariantList  : typeVariant
                  | typeVariantList '|' typeVariant
                  ;

typeVariant       : IDENTIFIER OF typeList
                  | IDENTIFIER
                  ;

typeList          : type
                  | typeList '*' type
                  ;

type               : INTEGER_LITERAL
                  | FLOAT_LITERAL
                  | BOOL_LITERAL
                  | CHAR_LITERAL
                  | STRING_LITERAL
                  | UserDefinedType
                  ;

forExpression     : FOR expression IN expression DO expression DONE
                  ;

ifExpression      : IF expression THEN expression ELSE expression FI
                  ;

expression         : literal
                  | IDENTIFIER
                  | LPAREN expression RPAREN
                  | IDENTIFIER LPAREN (identifierPattern | literalPattern) RPAREN
                  | recordInstPair
                  | expression binaryOperator expression
                  | unaryOperator expression
                  | MATCH expression WITH patternMatches
                  | ifExpression
                  | forExpression
                  | localExpression
                  | assignmentExpression
                  ;

localExpression   : LOCAL expression_list IN expression_list END
                  ;

expression_list    : expression
                  | expression_list expression
                  ;

assignmentExpression : LET IDENTIFIER ASSIGN expression IN expression
                  ;

literal           : integerLiteral
                  | octintegerLiteral
                  | binintegerLiteral
                  | hexintegerLiteral
                  | floatLiteral
                  | boolLiteral
                  | charLiteral
                  | stringLiteral
                  ;

octintegerLiteral : OCT_INTEGER_LITERAL
                  ;

binintegerLiteral : BIN_INTEGER_LITERAL
                  ;

hexintegerLiteral : HEX_INTEGER_LITERAL
                  ;

integerLiteral    : INTEGER_LITERAL
                  ;

floatLiteral      : FLOAT_LITERAL
                  ;

boolLiteral       : BOOL_LITERAL
                  ;

charLiteral       : CHAR_LITERAL
                  ;

stringLiteral     : STRING_LITERAL
                  ;

binaryOperator    : PLUS
                  | MINUS
                  | TIMES
                  | DIVIDE
                  | EQ
                  | NEQ
                  | LT
                  | GT
                  | LE
                  | GE
                  | AND
                  | OR
                  ;

unaryOperator     : MINUS
                  | NOT
                  | INC
                  | DEC
                  ;

argumentList      : expression
                  | argumentList COMMA expression
                  ;

identifier        : IDENTIFIER
                  ;

letter            : lowercase
                  | uppercase
                  ;

match             : MATCH expression WITH patternMatches
                  ;

patternMatches   : patternMatch
                  | patternMatches '|' patternMatch
                  ;

patternMatch     : pattern ARROW expression
                  ;

pattern           : literalPattern
                  | identifierPattern
                  ;

literalPattern   : integerLiteral
                  | floatLiteral
                  | boolLiteral
                  | charLiteral
                  | stringLiteral
                  ;

identifierPattern : IDENTIFIER LPAREN literalPattern RPAREN
                  ;

%%

int main() {
    yyparse();
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}


