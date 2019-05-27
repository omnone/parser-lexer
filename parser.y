

%{

/* Declaration of functions, variables etc. */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

//size for the hashtable
#define SIZE 200

struct variableItem {
   char *type;   
   char *data_type;
   char *name;
};


extern int yylineno;//we use this variable in order to get the errors line
extern FILE* yyin;
void yyerror(char *s);
void check_declaration_and_store(char* string, char* data_type,char *type);
void check_type(char* string_1,char* string_2, char* opt);
void is_declared(char* string);
int generate_hash(char* string);
struct variableItem *search(char *name);
void insert(char *name, char *type,char *data_type);



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


program 
     :  declaration
     | program declaration
     ;

declaration
   : variable_declaration ';'
   | function_declaration
   | error                {yyerrok; }
   ;

variable_declaration
   : data_type identifier {check_declaration_and_store($2,"Variable",$<type>1);}
   | variable_declaration ',' identifier
   ;

data_type
   : basic_data_type 
   | data_type '*'   %prec '!'
   ;

basic_data_type
   : INT      //{$$=$1;}
   | CHAR     //{$$=$1;}
   | BOOL     //{$$=$1;}
   | DOUBLE   //{$$=$1;}
   | FLOAT    //{$$=$1;}
   ;

identifier
   : ID identifier_help {$$=$1;}
   ;

identifier_help
   :
   | '[' const_expression ']'
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
   : data_type ID {check_declaration_and_store($2,"Function",$<type>1);}
   | VOID ID      {check_declaration_and_store($2,"Function",$<type>1);}
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

const_expression
   : expression
   ;



%%

//////////////////////////////////////////////////////////////////////////////////////////

struct variableItem *hashArray[SIZE];
struct variableItem *item;

//Generate hash index for a string
int generate_hash(char *string)
{
    int hash_code = 0;

    int index;
    for (index = 0; string[index] != '\0'; index++)
    {
        //printf("%c has ascci code %d\n", string[index], (int)string[index]);
        hash_code += (int)string[index];
    }

    hash_code = hash_code % 100;

    return hash_code;
}

//insert variable's or function's name ,type and datatype to hash table
void insert(char *name, char *type, char *data_type)
{

    struct variableItem *item = (struct variableItem *)malloc(sizeof(struct variableItem));
    item->type = type;
    item->name = name;

    //get the hash
    int hash_index = generate_hash(name);

    //move in array until an empty or deleted cell
    while (hashArray[hash_index] != NULL)
    {
        //go to next cell
        ++hash_index;

        //wrap around the table
        hash_index %= SIZE;
    }

    hashArray[hash_index] = item;
}

//search for the variable or function to hash table
struct variableItem *search(char *name)
{
    //get the hash
    int hash_index = generate_hash(name);

    //move in array until an empty
    while (hashArray[hash_index] != NULL)
    {

        if (!strcmp(hashArray[hash_index]->name, name))
        {
            return hashArray[hash_index];
        }

        //go to next cell
        ++hash_index;

        //wrap around the table
        hash_index %= SIZE;
    }

    return NULL;
}

////////////////////////////////////////////////////////////////////////////////////////////
// Here we check if a variable or a function is already declared and if is not
// then we save it to hash table
void check_declaration_and_store(char *string, char *data_type, char *type)
{
    struct variableItem *item = search(string);

    //if item is not null then the variable or function is already declared
    if (item != NULL)
    {

        char erstr[50] = " ";

        strcpy(erstr, data_type);
        strcat(erstr, " '");
        strcat(erstr, string);
        strcat(erstr, "' already declared");

        yyerror(erstr);
        return;
    }

    //save variable or function to hash table
    if (type)
        insert(string, type, data_type);
    else
        insert(string, "", "");
}

//////////////////////////////////////////////////////////////////////////////////////////
/* Type checking */
void check_type(char *string_1, char *string_2, char *opt)
{

    char erstr[100] = " ";
    int found_1 = 0; //flag for string_1
    int found_2 = 0; //flag flag string_2

    struct variableItem *variable_1 = search(string_1);
    struct variableItem *variable_2 = search(string_2);

    //search the first item
    int hash_index_1 = generate_hash(string_1);

    //search the hash table until you find a type for the specific
    //variable or name. If we dont find anything that means that we have a string literal etc.
    while (hashArray[hash_index_1] != NULL && hash_index_1 < SIZE)
    {

        if (!strcmp(hashArray[hash_index_1]->name, string_1) && strcmp(hashArray[hash_index_1]->type, ""))
        {
            variable_1 = hashArray[hash_index_1];
            found_1 = 1;
            break;
        }

        //go to next cell
        ++hash_index_1;

        //wrap around the table
        hash_index_1 %= SIZE;
    }

    //search the second item
    int hash_index_2 = generate_hash(string_2);

    //move in array until an empty
    while (hashArray[hash_index_2] != NULL && hash_index_2 < SIZE)
    {

        if (!strcmp(hashArray[hash_index_2]->name, string_2) && strcmp(hashArray[hash_index_2]->type, ""))
        {
            variable_2 = hashArray[hash_index_2];
            found_2 = 1;
            break;
        }

        //go to next cell
        ++hash_index_2;

        //wrap around the table
        hash_index_2 %= SIZE;
    }

    if ((found_1 == 1) && (found_2 == 1))
    {
        if (strcmp(variable_1->type, variable_2->type) != 0)
        {

            strcpy(erstr, "Can't ");
            strcat(erstr, opt);
            strcat(erstr, " a variable with type '");
            strcat(erstr, variable_2->type);
            strcat(erstr, "' and a variable with type '");
            strcat(erstr, variable_1->type);
            strcat(erstr, "'");

            yyerror(erstr);
        }
    }
    else if ((found_1 == 1) && (found_2 == 0))
    {

        if ((strcmp(variable_1->type, "char") != 0) && (strcmp(variable_1->type, " ") != 0) && (string_2[0] == '"'))
        {

            strcpy(erstr, "Can't ");
            strcat(erstr, opt);
            strcat(erstr, " a variable with type '");
            strcat(erstr, variable_1->type);
            strcat(erstr, "' with a string literal");

            yyerror(erstr);
        }
        else if ((strcmp(variable_1->type, "char") == 0) && (string_2[0] != '"'))
        {

            strcpy(erstr, "Can't ");
            strcat(erstr, opt);
            strcat(erstr, " a variable with type '");
            strcat(erstr, variable_1->type);
            strcat(erstr, "' with a number");
            yyerror(erstr);
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////

/* Check if variable is declared */
void is_declared(char *string)
{

    if (!search(string))
    { //if found = 0 then variable is not declared

        char erstr[100] = " ";

        strcpy(erstr, "Variable '");
        strcat(erstr, string);
        strcat(erstr, "' is undeclared");

        yyerror(erstr);
    }
}

//////////////////////////////////////////////////////////////////////////////////////////
int count_errors = 0;

int main(int argc, char *argv[])
{

    if (argc > 1)
    {

        printf("\n================================================================================================\nError report:\n================================================================================================\n\n");

        //open file
        yyin = fopen(argv[1], "r");

        if (yyparse() == 0)
        { //we parsing until the  yyparse() returns 0
            printf("\n================================================================================================\n");
            printf("\n[+] Parsing file : \"%s\" completed\n", argv[1]);
        }
        else
        { //parsing failed
            printf("\n================================================================================================\n");
            printf("\n[-] Parsing file : \"%s\" failed\n", argv[1]);
        }

        //total errors
        printf("\nTotal: [%d] errors\n", count_errors);

        fclose(yyin); //close file
    }
    else
    { //file not found

        printf("Error: No file input!\n");
        exit(1);
    }

    return 0;
}

//////////////////////////////////////////////////////////////////////////////////////////
/* Print errors */

void yyerror(char *s)
{

    //extern int line_n;
    count_errors++; // errors counter

    printf("[%d] Error : %s  at line %d \n", count_errors, s, yylineno);
}

//////////////////////////////////////////////////////////////////////////////////////////
