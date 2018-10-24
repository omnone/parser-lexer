
%{
#include "parser.tab.h"
#include <stdio.h>

extern void yyerror(const char *);
char buffer[500];


%}

%option  nodefault yylineno


%%

\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\/  { ; }
\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*       {yyerror("Unclosed comment");}
"//".*                       {;}
\".*\"                       {yylval.type = strdup(yytext); return STRING_LITERAL;}
[\t]+                        {;}
\n.*                         {strncpy(buffer, yytext+1, sizeof(buffer));  yyless(1);  }
"int"                        {yylval.type = strdup(yytext); return INT;}
"float"                      {yylval.type = strdup(yytext); return FLOAT;}
"char"                       {yylval.type = strdup(yytext); return CHAR;}
"void"                       {yylval.type = strdup(yytext); return VOID;}
"double"                     {yylval.type = strdup(yytext); return DOUBLE;}
"for"                        {return FOR;}
"else"                       {return ELSE;}
"if"                         {return IF;}
"null"                       {return NULL_T;}
"byref"                      {return BYREF;}
"break"                      {return BREAK;}
"continue"                   {return CONTINUE;}
"return"                     {return RETURN;}
"delete"                     {return DELETE;}
"true"                       {return  TRUE;}
"false"                      {return FALSE;}
"new"                        {return NEW;}
^"#include ".+               {;}
[0-9]*\.[0-9]+               {return DOUBLE_CONST;}
[0-9]+                       {return INT_CONST;}
[_a-zA-Z]([_a-zA-Z]|[_0-9])* {yylval.var = strdup(yytext);return ID;}
"<="                         {return LE;}
">="                         {return GE;}
"=="                         {return EQ;}
"!="                         {return NE;}
"&&"                         {return AND;}
"||"                         {return OR;}
"*="                         {return MUL_AS;}
"/="                         {return DIV_AS;}
"+="                         {return ADD_AS;}
"-="                         {return MIN_AS;}
"%="                         {return MOD_AS;}
"++"                         {return INCR;}
"--"                         {return DCRS;}
">"                          {return GT;}
"<"                          {return LT;}
"-"                          {return('-'); }
"+"                          {return('+'); }
"*"                          {return('*'); }
"/"                          {return('/'); }
"%"                          {return('%'); }
","                          {return(','); }
":"                          {return(':'); }
"="                          {return('='); }
"("                          {return('('); }
")"                          {return(')'); }
"{"                          {return('{'); }
"}"                          {return('}'); }
";"                          {return ';'; }
[ \t\r\n]+                   {;}
.                            {return *yytext;}


%%



int yywrap (void) {return 1;}
