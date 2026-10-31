#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static int sSol[81];
static int sFound;

static int pc(unsigned m){int c=0;while(m&0x1FFu){c+=(int)(m&1u);m>>=1;}return c;}

static int countSols(int *b,unsigned *rm,unsigned *cm,unsigned *bm,int limit,int shuf){
  int best=-1,bestMask=0,bestN=10;
  for(int i=0;i<81;i++){
    if(b[i])continue;
    int r=i/9,c=i%9,bx=(r/3)*3+c/3;
    unsigned av=(~(rm[r]|cm[c]|bm[bx]))&0x1FFu; int n=pc(av);
    if(!n)return 0;
    if(n<bestN){bestN=n;best=i;bestMask=(int)av;if(n==1)break;}
  }
  if(best<0){if(!sFound){memcpy(sSol,b,sizeof(int)*81);sFound=1;}return 1;}
  int r=best/9,c=best%9,bx=(r/3)*3+c/3;
  int cand[9],m=0;
  for(int d=1;d<=9;d++) if(bestMask&(1<<(d-1))) cand[m++]=d;
  if(shuf) for(int i=m-1;i>0;i--){int j=rand()%(i+1);int t=cand[i];cand[i]=cand[j];cand[j]=t;}
  int total=0;
  for(int k=0;k<m;k++){
    int d=cand[k];unsigned bit=1u<<(d-1);
    b[best]=d;rm[r]|=bit;cm[c]|=bit;bm[bx]|=bit;
    total+=countSols(b,rm,cm,bm,limit-total,shuf);
    b[best]=0;rm[r]&=~bit;cm[c]&=~bit;bm[bx]&=~bit;
    if(total>=limit)return total;
  }
  return total;
}

static void masks(int *b,unsigned *rm,unsigned *cm,unsigned *bm){
  memset(rm,0,36);memset(cm,0,36);memset(bm,0,36);
  for(int i=0;i<81;i++){int d=b[i];if(!d)continue;int r=i/9,c=i%9,bx=(r/3)*3+c/3;unsigned bit=1u<<(d-1);
    rm[r]|=bit;cm[c]|=bit;bm[bx]|=bit;}
}
static void fullSolve(int *b){unsigned rm[9],cm[9],bm[9];masks(b,rm,cm,bm);sFound=0;countSols(b,rm,cm,bm,1,1);memcpy(b,sSol,sizeof(int)*81);}
static int unique(int *b){int c2[81];memcpy(c2,b,sizeof c2);unsigned rm[9],cm[9],bm[9];masks(c2,rm,cm,bm);return countSols(c2,rm,cm,bm,2,0)==1;}
static void shuf(int *a,int n){for(int i=n-1;i>0;i--){int j=rand()%(i+1);int t=a[i];a[i]=a[j];a[j]=t;}}
static int clues(int *b){int n=0;for(int i=0;i<81;i++)if(b[i])n++;return n;}

/* mirrors generatePuzzle() including the fallback path */
static void generate(int diff,int *puzzle,int *solution){
  int best[81],bestSol[81],bestDelta=1<<30,haveBest=0,order[81];
  int attempts=(diff==2)?10:14;
  int target=(diff==0)?44:(diff==1)?32:24;
  for(int a=0;a<attempts;a++){
    memset(puzzle,0,sizeof(int)*81);
    fullSolve(puzzle);
    memcpy(solution,puzzle,sizeof(int)*81);
    for(int i=0;i<81;i++)order[i]=i;
    shuf(order,81);
    if(diff==2){
      int changed=1,pass=0;
      while(changed&&pass<8){changed=0;pass++;shuf(order,81);
        for(int k=0;k<81;k++){int i=order[k];if(!puzzle[i])continue;int v=puzzle[i];puzzle[i]=0;
          if(unique(puzzle))changed=1;else puzzle[i]=v;}}
      if(clues(puzzle)<=26){memcpy(puzzle,puzzle,sizeof(int)*81);memcpy(solution,solution,sizeof(int)*81);return;}
    } else {
      int lo=(diff==0)?38:28, hi=(diff==0)?81:36;
      for(int k=0;k<41;k++){int x=order[k],y=80-order[k];if(!puzzle[x])continue;
        int vx=puzzle[x],vy=puzzle[y];puzzle[x]=0;puzzle[y]=0;
        if(!unique(puzzle)){puzzle[x]=vx;puzzle[y]=vy;}
        if(clues(puzzle)<=target)break;}
      int cl=clues(puzzle);
      if(cl>=lo&&cl<=hi) return;
    }
    int delta=abs(clues(puzzle)-target);
    if(!haveBest||delta<bestDelta){bestDelta=delta;memcpy(best,puzzle,sizeof(int)*81);
      memcpy(bestSol,solution,sizeof(int)*81);haveBest=1;}
  }
  if(haveBest){memcpy(puzzle,best,sizeof(int)*81);memcpy(solution,bestSol,sizeof(int)*81);return;}
  memset(solution,0,sizeof(int)*81);fullSolve(solution);memcpy(puzzle,solution,sizeof(int)*81);
}

int main(void){
  srand((unsigned)time(NULL));
  const char*nm[3]={"easy","medium","hard"};
  int bad=0;
  for(int d=0;d<3;d++){
    int minC=99,maxC=0,sum=0;
    for(int t=0;t<200;t++){
      int puz[81],sol[81];
      generate(d,puz,sol);
      int c=clues(puz);sum+=c;if(c<minC)minC=c;if(c>maxC)maxC=c;
      /* 1. every given matches the solution */
      for(int i=0;i<81;i++) if(puz[i] && puz[i]!=sol[i]){printf("MISMATCH d=%d t=%d i=%d\n",d,t,i);bad++;break;}
      /* 2. puzzle has a unique solution */
      if(!unique(puz)){printf("NOT UNIQUE d=%d t=%d\n",d,t);bad++;}
      /* 3. the stored solution actually solves the puzzle */
      int chk[81];memcpy(chk,puz,sizeof chk);
      int c2c[81];memcpy(c2c,puz,sizeof c2c);
      unsigned rm[9],cm[9],bm[9];masks(c2c,rm,cm,bm);sFound=0;
      if(countSols(c2c,rm,cm,bm,2,0)!=1){bad++;printf("SOLVE FAIL d=%d\n",d);}
      for(int i=0;i<81;i++) if(sSol[i]!=sol[i]){printf("SOLUTION DRIFT d=%d t=%d\n",d,t);bad++;break;}
      (void)chk;
    }
    printf("%-6s clues avg %.1f min %d max %d\n",nm[d],sum/200.0,minC,maxC);
  }
  printf(bad? "FAILURES: %d\n":"ALL CHECKS PASSED\n",bad);
  return bad?1:0;
}
