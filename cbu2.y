%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


#define DEBUG   0

#define    MAXSYM   100
#define    MAXSYMLEN   20
#define    MAXTSYMLEN   15
#define    MAXTSYMBOL   MAXSYM/2

#define STMTLIST 500

typedef struct nodeType {
	int token;
	int tokenval;
	struct nodeType *son;
	struct nodeType *brother;
} Node;

#define YYSTYPE Node*
   
int tsymbolcnt=0;
int errorcnt=0;

FILE *yyin;
FILE *fp;

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node * MakeOPTree(int, Node*, Node*);
Node * MakeNode(int, int);
Node * MakeListTree(Node*, Node*);
void codegen(Node* );
void prtcode(int, int);

void   dwgen();
int   gentemp();
void   assgnstmt(int, int);
void   numassgn(int, int);
void   addstmt(int, int, int);
void   substmt(int, int, int);
int    insertsym(char *);
%}


%token   IF ELSE THEN EQ LT GT ADD SUB MUL DIV ASSGN ID NUM STMTEND START END ID2 '(' ')' 
%left '(' ')'
%left ADD SUB
%left MUL DIV
%left EQ LT GT

%%
program     : START stmt_list END   { if (errorcnt==0) {codegen($2); dwgen();} }
			;

stmt_list   :   stmt_list stmt  {$$=MakeListTree($1, $2);}
			|   stmt            {$$=MakeListTree(NULL, $1);}
			|   error STMTEND   { errorcnt++; yyerrok;}
			;
   
stmt    :    ID ASSGN expr STMTEND   { $1->token = ID2; $$=MakeOPTree(ASSGN, $1, $3);}
		|    IF expr THEN stmt_list ELSE stmt_list END { $$=MakeOPTree(IF, $2, MakeListTree($4, $6)); }
		;

expr    :   '(' expr ')'     { $$ = $2; }
		|   expr ADD expr   { $$=MakeOPTree(ADD, $1, $3); }
		|   expr SUB expr   { $$=MakeOPTree(SUB, $1, $3); }
		|   expr MUL expr   { $$=MakeOPTree(MUL, $1, $3); }
		|   expr DIV expr   { $$=MakeOPTree(DIV, $1, $3); }
		|   expr EQ expr    { $$=MakeOPTree(EQ, $1, $3); }
		|   expr LT expr    { $$=MakeOPTree(LT, $1, $3); }
		|   expr GT expr    { $$=MakeOPTree(GT, $1, $3); }
		|   term
		;


term    :   ID      { /* ID node is created in lex */ }
      |   NUM      { /* NUM node is created in lex */ }
      ;


%%
int main(int argc, char *argv[]) 
{
   printf("\nsample CBU compiler v2.0\n");
   printf("(C) Copyright by Jae Sung Lee (jasonlee@cbnu.ac.kr), 2022.\n");
   
    if (argc == 2)
		yyin = fopen(argv[1], "r");
     
    else {
		printf("Usage: cbu2 inputfile\noutput file is 'a.asm'\n");
		return(0);
    }
      
    fp=fopen("a.asm", "w");
   
    yyparse();
   
    fclose(yyin);
    fclose(fp);

    if (errorcnt==0) 
	{ printf("Successfully compiled. Assembly code is in 'a.asm'.\n");}
}

yyerror(s)
char *s;
{
   printf("%s (line %d)\n", s, lineno);
}


Node * MakeOPTree(int op, Node* operand1, Node* operand2)
{
	Node * newnode;

	newnode = (Node *)malloc(sizeof (Node));
	newnode->token = op;
	newnode->tokenval = op;
	newnode->son = operand1;
	newnode->brother = NULL;
	operand1->brother = operand2;
	return newnode;
}

Node * MakeNode(int token, int operand)
{
    Node * newnode;

    newnode = (Node *) malloc(sizeof (Node));
    newnode->token = token;
    newnode->tokenval = operand; 
    newnode->son = newnode->brother = NULL;
    return newnode;
}

Node * MakeListTree(Node* operand1, Node* operand2)
{
    Node * newnode;
    Node * node;

    if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
    }
     
    else {
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
    }
}

void codegen(Node * root)
{
    DFSTree(root);
}

void DFSTree(Node * n)
{
    if (n==NULL) return;
   
    if (n->token == IF) 
    {
		prtcode(n->son->token, n->son->tokenval);

		fprintf(fp, "IF_FALSE L%d\n", n->son->brother->tokenval); 
		DFSTree(n->son->brother->brother); 
		fprintf(fp, "GOTO L%d\n", n->brother->tokenval); 
		fprintf(fp, "LABEL L%d\n", n->son->brother->tokenval);
		DFSTree(n->brother);
		fprintf(fp, "LABEL L%d\n", n->brother->tokenval); 
    }   
        
    else 
    {   
		prtcode(n->token, n->tokenval);
    }
   
   DFSTree(n->brother);
}

void prtcode(int token, int val)
{
	switch (token) {
    case ID:
		fprintf(fp,"RVALUE %s\n", symtbl[val]);
		break;
    case ID2:
		fprintf(fp, "LVALUE %s\n", symtbl[val]);
		break;
    case NUM:
		fprintf(fp, "PUSH %d\n", val);
		break;
	case ADD:
		fprintf(fp, "+\n");
		break;
	case SUB:
		fprintf(fp, "-\n");
		break;
	case MUL:
		fprintf(fp, "*\n");
		break;
	case DIV:
		fprintf(fp, "/\n");
		break;
	case EQ:
		fprintf(fp, "==\n");
		break;
	case LT:
		fprintf(fp, "<\n");
		break;
	case GT:
		fprintf(fp, ">\n");
		break;
	case ASSGN:
		fprintf(fp, ":=\n");
		break;
	case IF:
		break;
	case THEN:
	case ELSE:
	case END:
		break;
	case STMTLIST:
	default:
		break;
    };
}


/*
int gentemp()
{
	char buffer[MAXTSYMLEN];
	char tempsym[MAXSYMLEN]="TTCBU";

	tsymbolcnt++;
	if (tsymbolcnt > MAXTSYMBOL) printf("temp symbol overflow\n");
	itoa(tsymbolcnt, buffer, 10);
	strcat(tempsym, buffer);
	return( insertsym(tempsym) ); // Warning: duplicated symbol is not checked for lazy implementation
}
*/

void dwgen()
{
	int i;
	fprintf(fp, "HALT\n");
	fprintf(fp, "$ -- END OF EXECUTION CODE AND START OF VAR DEFINITIONS --\n");

	for(i=0; i<maxsym; i++) 
		fprintf(fp, "DW %s\n", symtbl[i]);
	fprintf(fp, "END\n");
}
