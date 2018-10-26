

%{

/* Declaration of functions, variables etc. */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Please avoid this , allocate memory properly */
char *variables[100000];
char *var_type[100000];


extern int yylineno;//we use this variable in order to get the errors line
extern FILE* yyin;
void yyerror(char *s);
void symbols(char* string, char* data_type);
void get_type(char *string);
void check_type(char* string_1,char* string_2, char* opt);
void is_declared(char* string);



%}

/* Tokens declaration */

%union {char* var; char* type; }

%token <type> INT  DOUBLE BOOL CHAR FLOAT
%token FOR
%token IF ELSE
%token BYREF BREAK CONTINUE RETURN DELETE FALSE TRUE NEW NULL_T VOID
%token INT_CONST DOUBLE_CONST
%token <var> ID STRING_LITERAL
%token  STRUCT GT LT  MUL_AS DIV_AS ADD_AS MIN_AS MOD_AS EQ NE LE GE INCR DCRS
%type <var> expression identifier

/*  Operator Precedence Table based on C*/

%left NEW CONTINUE BREAK
%left INCR DCRS '[' ']' '(' ')' '{' '}'
%right '!'
%left '*'  '/' '%'
%left '+' '-'
%left GT LT LE GE
%left EQ NE
%left  '&'
%left AND OR
%right      '?' ':'
%right MUL_AS DIV_AS ADD_AS MIN_AS MOD_AS  '='
%left ','
%right  DELETE
%right ELSE
%error-verbose
%start program

%%


program //arxi
     :  declaration
     | program declaration
     ;

declaration
   : variable_declaration ';'
   | function_declaration
   | error                {yyerrok; }
   ;

variable_declaration
   : data_type identifier {symbols($2,"Variable");}
   | variable_declaration ',' identifier
   ;

data_type
   : basic_data_type
   | data_type '*'   %prec '!'
   ;

basic_data_type
   : INT      {get_type($1);}
   | CHAR     {get_type($1);}
   | BOOL     {get_type($1);}
   | DOUBLE   {get_type($1);}
   | FLOAT    {get_type($1);}
   ;

identifier
   : ID identifier_help {$$=$1;}
   ;

identifier_help
   :
   | '[' statheri_expression ']'
   | '[' error ']'           {yyerrok; }
   ;

function_declaration
   : result_type  '(' function_declaration_help ')' '{' declaration_zero_more sentence_zero_more  '}'
   | result_type  '(' function_declaration_help ')' ';'
   | result_type  '(' error ')' ';'    {  yyerrok; }
   | result_type  '(' function_declaration_help error  ';'         {yyerror("Missing ')'"); yyerrok; }
   | result_type  error function_declaration_help error ')' ';'    {yyerror("Missing '('"); yyerrok; }
   | result_type '(' error ')' '{' declaration_zero_more sentence_zero_more '}'
   ;

function_declaration_help
   :
   | parameters_list
   ;

result_type
   : data_type ID {symbols($2,"Function");}
   | VOID ID            {get_type("void"); symbols($2,"Function");}
   ;

parameters_list
   : parameter
   | parameters_list ',' parameter
   | parameters_list ',' error       {yyerrok; }
   ;

parameter
   : BYREF data_type ID {}
   | data_type ID
   ;


sentence_zero_more
   :
   | sentence_zero_more sentence
   ;

declaration_zero_more
   :
   | declaration_zero_more declaration
   ;

expression_help
   :
   | expression
   ;

sentence
   : IF '(' expression ')' sentence
   | IF '(' error ')' sentence                                             {yyerrok; }
   | IF '(' expression ')' sentence ELSE sentence
   | FOR '(' expression_help ';' expression_help ';'  expression_help ')' sentence
   | FOR '(' error ')' sentence                                            {yyerrok; }
   | expression ';'
   | error ';'                                                            {yyerrok; }
   | '{' sentence_zero_more '}'
   | '{' error '}'                                                        {yyerrok; }
   | CONTINUE sentence_help ';'
   | CONTINUE error ';'                                                   {yyerrok; }
   | BREAK sentence_help ';'
   | BREAK error ';'                                                      {yyerrok; }
   | RETURN expression ';'
   | RETURN error ';'                                                     {yyerrok; }
   | RETURN  ';'
   | declaration
   | ';'
   ;

 sentence_help
   :
   | ID
   ;



expression
   : '(' expression ')'
   | '(' error ')'            {yyerrok;}
   | ID '(' expression_list ')'
   | ID '(' error ')'         {yyerrok; }
   | expression '[' expression ']'
   | expression '[' error ']'    {yyerrok; }
   | expression '&' expression
   | expression '*' expression  {check_type($1,$3,"multiply");}
   | expression '*' error    {yyerrok; }
   | expression '!' expression
   | expression '+' expression  {check_type($1,$3,"add");}
   | expression '-' expression  {check_type($1,$3,"substract");}
   | expression '/' expression  {check_type($1,$3,"divide");}
   | expression '%' expression  {check_type($1,$3,"mod");}
   | expression ',' expression
   | expression AND expression
   | expression OR expression
   | expression INCR
   | expression DCRS
   | expression '=' expression             {check_type($1,$3,"assign");}
   | expression DIV_AS expression          {check_type($1,$3,"assign");}
   | expression MOD_AS expression          {check_type($1,$3,"assign");}
   | expression MUL_AS expression          {check_type($1,$3,"assign");}
   | expression ADD_AS expression          {check_type($1,$3,"assign");}
   | expression MIN_AS expression          {check_type($1,$3,"assign");}
   | expression LE expression              {check_type($1,$3,"compare");}
   | expression GE expression              {check_type($1,$3,"compare");}
   | expression NE expression              {check_type($1,$3,"compare");}
   | expression EQ expression              {check_type($1,$3,"compare");}
   | expression LT expression              {check_type($1,$3,"compare");}
   | expression GT expression              {check_type($1,$3,"compare");}
   | expression LT error                              {yyerrok; }
   | expression GT error                              {yyerrok; }
   | '(' data_type ')' expression
   | expression '?' expression ':' expression
   | NEW data_type
   | NEW error                                     {yyerrok;}
   | NEW data_type '[' expression ']'
   | DELETE expression
   | ID                                            { is_declared($1);}
   | TRUE
   | FALSE
   | NULL_T
   | INT_CONST
   | DOUBLE_CONST
   | STRING_LITERAL  {$$ = $1;}
   //| error   {yyerrok; }


   ;

 expression_list
   : expression
   | expression_list ',' expression
   | expression_list ',' error {yyerrok;}
   ;

statheri_expression
   : expression
   ;



%%

//////////////////////////////////////////////////////////////////////////////////////////

int count = 0;

/* Everytime that we find a variable , we save its name in "variables" array and
   then we save its type on the same index in "var_type" array.
*/

void symbols(char* string, char* data_type) {

  int i;
  //printf("String to check: %s \n", string);

  for (i = 0; i < 100000; i++) {

    //check if we have a variable or a function
    if (strcmp(variables[i], string) == 0) {

      char erstr[50] = " ";

      strcpy(erstr, data_type);
      strcat(erstr, " '");
      strcat(erstr, string);
      strcat(erstr, "' already declared");

      yyerror(erstr);
      return;

    }

  }

  variables[count] = string;
    //printf("String: %s  Type: %s \n",variables[count],var_type[count]);


  count++; //index used for both arrays

}


//////////////////////////////////////////////////////////////////////////////////////////
/* Store variables*/

void get_type(char* string) {

  var_type[count] = string;
  //printf("get_type : %s\n",string);

}

//////////////////////////////////////////////////////////////////////////////////////////
/* Type checking */

void check_type(char* string_1, char* string_2, char* opt) {

  //printf("check_type\n");

  int i;

  int index_1 = 0; //index of string_1 which represents variables name
  int index_2 = 0; //index of string_2 which represents types name

  int found_1 = 0; //flag for string_1
  int found_2 = 0; //flag flag string_2

  //printf("Strings to compare: %s  %s\n",string_1,string_2);

  for (i = 0; i < 100000; i++) {

    //printf("%d\n",i);

    if ((strcmp(variables[i], string_1) == 0) && (strcmp(var_type[i], " ") != 0)) {
      //string_1 found!

      index_1 = i;
      found_1 = 1;

    }

    if ((strcmp(variables[i], string_2) == 0) && (strcmp(var_type[i], " ") != 0)) {

      //string_2 found!

      index_2 = i;
      found_2 = 1;
    }

    //printf("%d %d",index_1,index_2);

  }

  char erstr[100] = " ";

  if (( found_1 == 1) && (found_2 == 1)) { //we found variables name and type


    //printf("Types: %s %s",var_type[index_1],var_type[index_2]);

    //error: different types
    if (strcmp(var_type[index_2], var_type[index_1]) != 0) {



      strcpy(erstr, "Can't ");
      strcat(erstr, opt);
      strcat(erstr, " a variable with type '");
      strcat(erstr, var_type[index_2]);
      strcat(erstr, "' and a variable with type '");
      strcat(erstr, var_type[index_1]);
      strcat(erstr, "'");


      yyerror(erstr);
    }
  } else if (( found_1 == 1) && (found_2 == 0)){

    if ((strcmp(var_type[index_1], "char") != 0) && (strcmp(var_type[index_1], " ") != 0) && (string_2[0] == '"')) {

      strcpy(erstr, "Can't ");
      strcat(erstr, opt);
      strcat(erstr, " a variable with type '");
      strcat(erstr, var_type[index_1]);
      strcat(erstr, "' with a string literal");

      yyerror(erstr);

    } else if ((strcmp(var_type[index_1], "char") == 0) && (string_2[0] != '"')) {

      strcpy(erstr, "Can't ");
      strcat(erstr, opt);
      strcat(erstr, " a variable with type '");
      strcat(erstr, var_type[index_1]);
      strcat(erstr, "' with a number");
      yyerror(erstr);
    }
  }
}



//////////////////////////////////////////////////////////////////////////////////////////

/* Check if variable is declared */

void is_declared(char* string) {

  int i;
  int found = 0;

  for (i = 0; i < 100000; i++) {

    if (strcmp(variables[i], string) == 0) {

      found = 1;
      break;

    }
  }

  if ( found == 0) { //if found = 0 then variable is not declared

    char erstr[100] = " ";

    strcpy(erstr, "Variable '");
    strcat(erstr, string);
    strcat(erstr, "' is undeclared");

    yyerror(erstr);
  }

}


//////////////////////////////////////////////////////////////////////////////////////////
int count_errors = 0;

int main(int argc, char *argv[]) {

  int i;

  if (argc > 1) {

    printf("\n================================================================================================\nError report:\n================================================================================================\n\n");

    for (i = 0; i < 100000; i++) { //a bad array initialization , no time for dat

      variables[i] = " ";
      var_type[i]  = " ";

    }


    //open file
    yyin = fopen(argv[1], "r");


    if (yyparse() == 0) { //we parsing until the  yyparse() returns 0
      printf("\n================================================================================================\n");
      printf("\n[+] Parsing file : \"%s\" completed\n", argv[1]);
    }
    else { //parsing failed
      printf("\n================================================================================================\n");
      printf("\n[-] Parsing file : \"%s\" failed\n", argv[1]);
    }


    //total errors
    printf("\nTotal: [%d] errors\n", count_errors);

    fclose(yyin); //close file

  }
  else {//file not found

    printf("Error: No file input!\n");
    exit(1);
  }

  return 0;

}

//////////////////////////////////////////////////////////////////////////////////////////
/* Print errors */

void yyerror(char* s) {

  //extern int line_n;
  count_errors++; // errors counter

  printf("[%d] Error : %s  at line %d \n", count_errors, s, yylineno);



}

//////////////////////////////////////////////////////////////////////////////////////////
