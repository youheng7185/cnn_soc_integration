#include "spike_test.h"

#define DHRYSTONE_LOOPS 100

typedef int bool_t;
typedef enum { Ident_1, Ident_2, Ident_3 } Enum_Loc;

typedef struct {
    Enum_Loc Enum_Comp;
    int Int_Comp;
    char Str_Comp[31];
} Record_Loc;

static int Int_Glob;
static int Bool_Glob;
static char Ch_1_Glob;
static char Ch_2_Glob;
static int Arr_1_Glob[50];
static int Arr_2_Glob[50][50];

static int Proc_3(int *Int_Par_Ref) {
    int Int_Loc;
    Enum_Loc Enum_Loc;
    Enum_Loc = *Int_Par_Ref;
    Int_Loc = *Int_Par_Ref + 10;
    return Int_Loc;
}

static int Proc_7(int Int_1_Par, int Int_2_Par) {
    int Int_Loc;
    Int_Loc = Int_1_Par + 2;
    return Int_2_Par + Int_Loc;
}

static int Proc_8(int Arr_1_Par[50], int Arr_2_Par[50][50], int Int_1_Par, int Int_2_Par) {
    int Int_Loc;
    int Int_Index;
    Int_Loc = Int_1_Par + 5;
    Arr_1_Par[Int_Loc] = Int_2_Par;
    Arr_2_Par[Int_Loc][Int_Loc] = Arr_1_Par[Int_Loc];
    return Int_1_Par;
}

static void Proc_6(Enum_Loc Enum_Par, Enum_Loc *Enum_Ref) {
    *Enum_Ref = Enum_Par;
}

static bool_t Func_3(Enum_Loc Enum_Par) {
    Enum_Loc Enum_Loc;
    Enum_Loc = Enum_Par;
    return (Enum_Loc == Ident_3);
}

int main(void) {
    int Int_1_Loc;
    int Int_2_Loc;
    int Int_3_Loc;
    char Ch_Index;
    Enum_Loc Enum_Loc;
    Record_Loc Rec_Loc;
    int i;

    Int_Glob = 0;
    Bool_Glob = 0;
    Ch_1_Glob = 'A';
    Ch_2_Glob = 'B';

    for (i = 0; i < DHRYSTONE_LOOPS; i++) {
        Int_1_Loc = 5;
        Int_2_Loc = 7;
        Int_3_Loc = Int_1_Loc + Int_2_Loc;
        Int_Glob = Int_3_Loc;

        Int_1_Loc = Proc_7(Int_1_Loc, Int_2_Loc);
        Int_3_Loc = Proc_3(&Int_1_Loc);

        if (Int_3_Loc == 15) {
            Bool_Glob = 1;
        } else {
            Bool_Glob = 0;
        }

        Proc_6(Ident_1, &Enum_Loc);

        if (Enum_Loc == Ident_1) {
            Int_Glob = Int_Glob + 1;
        }

        Int_1_Loc = Proc_8(Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_2_Loc);

        if (Bool_Glob) {
            Ch_1_Glob = 'A';
        }

        if (Func_3(Ident_3)) {
            Int_2_Loc = 10;
        } else {
            Int_2_Loc = 20;
        }
    }

    TEST_ASSERT_EQ(Int_Glob, 100 + 5 + 7 + 1);
    PASS();
    return 0;
}