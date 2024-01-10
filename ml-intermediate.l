%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"  // Include the yacc header file
%}

%%
"fun"               { return FUN; }
"val"               { return VAL; }
"type"              { return TYPE; }
"record"            { return RECORD; }
"of"                { return OF; }
"for"               { return FOR; }
"in"                { return IN; }
"do"                { return DO; }
"done"              { return DONE; }
"if"                { return IF; }
"then"              { return THEN; }
"else"              { return ELSE; }
"fi"                { return FI; }
"local"             { return LOCAL; }
"end"               { return END; }
"let"               { return LET; }
"match"             { return MATCH; }
"with"              { return WITH; }

"=="                { return EQ; }
"!="                { return NEQ; }
"<="                { return LE; }
">="                { return GE; }
"&&"                { return AND; }
"||"                { return OR; }
"++"                { return INC; }
"--"                { return DEC; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return TIMES; }
"/"                 { return DIVIDE; }
"="                 { return ASSIGN; }
"<"                 { return LT; }
">"                 { return GT; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
"["                 { return LBRACKET; }
"]"                 { return RBRACKET; }
","                 { return COMMA; }
":"                 { return COLON; }
";"                 { return SEMICOLON; }
"'"                 { return CHAR_LITERAL; }
'"'                 { return STRING_LITERAL; }
[0-9]+              { yylval.str = strdup(yytext); return INTEGER_LITERAL; }
[0-9]+[Oo]          { yylval.str = strdup(yytext); return OCT_INTEGER_LITERAL; }
[0-1]+[Bb]          { yylval.str = strdup(yytext); return BIN_INTEGER_LITERAL; }
[0-9a-fA-F]+[Hh]    { yylval.str = strdup(yytext); return HEX_INTEGER_LITERAL; }
[0-9]+[.][0-9]+     { yylval.str = strdup(yytext); return FLOAT_LITERAL; }
"true"|"false"      { yylval.str = strdup(yytext); return BOOL_LITERAL; }
[A-Za-z_][A-Za-z0-9_]*  { yylval.str = strdup(yytext); return IDENTIFIER; }
.                   { return yytext[0]; }
%%

int yywrap() {
    return 1;
}

