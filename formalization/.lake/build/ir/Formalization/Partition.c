// Lean compiler output
// Module: Formalization.Partition
// Imports: Init
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
extern lean_object* l_Int_instInhabited;
static lean_object* l_List_foldl___at_compute__next__p__list___spec__2___closed__3;
static lean_object* l_List_foldl___at_compute__next__p__list___spec__2___closed__1;
static lean_object* l_compute__partitions__list___closed__1;
lean_object* l_List_appendTR___rarg(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_compute__next__p__list___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_List_foldl___at_compute__next__p__list___spec__2___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
lean_object* lean_nat_div(lean_object*, lean_object*);
lean_object* l_List_range(lean_object*);
LEAN_EXPORT lean_object* l_List_foldl___at_compute__next__p__list___spec__2(lean_object*, lean_object*, lean_object*, lean_object*);
static lean_object* l_List_foldl___at_compute__next__p__list___spec__2___closed__2;
LEAN_EXPORT lean_object* l_List_mapTR_loop___at_compute__next__p__list___spec__1(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_p(lean_object*);
LEAN_EXPORT lean_object* l_compute__partitions__list___boxed(lean_object*);
LEAN_EXPORT lean_object* l_compute__next__p__list(lean_object*, lean_object*);
lean_object* l_List_get_x21___rarg(lean_object*, lean_object*, lean_object*);
lean_object* lean_int_mul(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_mod(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_compute__partitions__list(lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* l_List_reverse___rarg(lean_object*);
lean_object* lean_int_add(lean_object*, lean_object*);
lean_object* lean_int_neg(lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_List_mapTR_loop___at_compute__next__p__list___spec__1(lean_object* x_1, lean_object* x_2) {
_start:
{
if (lean_obj_tag(x_1) == 0)
{
lean_object* x_3; 
x_3 = l_List_reverse___rarg(x_2);
return x_3;
}
else
{
uint8_t x_4; 
x_4 = !lean_is_exclusive(x_1);
if (x_4 == 0)
{
lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; 
x_5 = lean_ctor_get(x_1, 0);
x_6 = lean_ctor_get(x_1, 1);
x_7 = lean_unsigned_to_nat(1u);
x_8 = lean_nat_add(x_5, x_7);
lean_dec(x_5);
lean_ctor_set(x_1, 1, x_2);
lean_ctor_set(x_1, 0, x_8);
{
lean_object* _tmp_0 = x_6;
lean_object* _tmp_1 = x_1;
x_1 = _tmp_0;
x_2 = _tmp_1;
}
goto _start;
}
else
{
lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; 
x_10 = lean_ctor_get(x_1, 0);
x_11 = lean_ctor_get(x_1, 1);
lean_inc(x_11);
lean_inc(x_10);
lean_dec(x_1);
x_12 = lean_unsigned_to_nat(1u);
x_13 = lean_nat_add(x_10, x_12);
lean_dec(x_10);
x_14 = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(x_14, 0, x_13);
lean_ctor_set(x_14, 1, x_2);
x_1 = x_11;
x_2 = x_14;
goto _start;
}
}
}
}
static lean_object* _init_l_List_foldl___at_compute__next__p__list___spec__2___closed__1() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = lean_unsigned_to_nat(1u);
x_2 = lean_nat_to_int(x_1);
return x_2;
}
}
static lean_object* _init_l_List_foldl___at_compute__next__p__list___spec__2___closed__2() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_List_foldl___at_compute__next__p__list___spec__2___closed__1;
x_2 = lean_int_neg(x_1);
return x_2;
}
}
static lean_object* _init_l_List_foldl___at_compute__next__p__list___spec__2___closed__3() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = lean_unsigned_to_nat(0u);
x_2 = lean_nat_to_int(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_List_foldl___at_compute__next__p__list___spec__2(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
if (lean_obj_tag(x_4) == 0)
{
return x_3;
}
else
{
lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; lean_object* x_15; lean_object* x_16; lean_object* x_17; uint8_t x_18; uint8_t x_19; uint8_t x_20; 
x_5 = lean_ctor_get(x_4, 0);
x_6 = lean_ctor_get(x_4, 1);
x_7 = lean_unsigned_to_nat(3u);
x_8 = lean_nat_mul(x_7, x_5);
x_9 = lean_unsigned_to_nat(1u);
x_10 = lean_nat_sub(x_8, x_9);
x_11 = lean_nat_mul(x_5, x_10);
lean_dec(x_10);
x_12 = lean_unsigned_to_nat(2u);
x_13 = lean_nat_div(x_11, x_12);
lean_dec(x_11);
x_14 = lean_nat_add(x_8, x_9);
lean_dec(x_8);
x_15 = lean_nat_mul(x_5, x_14);
lean_dec(x_14);
x_16 = lean_nat_div(x_15, x_12);
lean_dec(x_15);
x_17 = lean_nat_mod(x_5, x_12);
x_18 = lean_nat_dec_eq(x_17, x_9);
lean_dec(x_17);
x_19 = lean_nat_dec_le(x_13, x_2);
x_20 = lean_nat_dec_le(x_16, x_2);
if (x_18 == 0)
{
if (x_19 == 0)
{
lean_object* x_21; lean_object* x_22; 
lean_dec(x_13);
x_21 = l_List_foldl___at_compute__next__p__list___spec__2___closed__3;
x_22 = lean_int_add(x_3, x_21);
lean_dec(x_3);
if (x_20 == 0)
{
lean_object* x_23; 
lean_dec(x_16);
x_23 = lean_int_add(x_22, x_21);
lean_dec(x_22);
x_3 = x_23;
x_4 = x_6;
goto _start;
}
else
{
lean_object* x_25; lean_object* x_26; lean_object* x_27; lean_object* x_28; lean_object* x_29; lean_object* x_30; 
x_25 = lean_nat_sub(x_2, x_16);
lean_dec(x_16);
x_26 = l_Int_instInhabited;
x_27 = l_List_get_x21___rarg(x_26, x_1, x_25);
x_28 = l_List_foldl___at_compute__next__p__list___spec__2___closed__2;
x_29 = lean_int_mul(x_28, x_27);
lean_dec(x_27);
x_30 = lean_int_add(x_22, x_29);
lean_dec(x_29);
lean_dec(x_22);
x_3 = x_30;
x_4 = x_6;
goto _start;
}
}
else
{
lean_object* x_32; lean_object* x_33; lean_object* x_34; lean_object* x_35; lean_object* x_36; lean_object* x_37; 
x_32 = lean_nat_sub(x_2, x_13);
lean_dec(x_13);
x_33 = l_Int_instInhabited;
x_34 = l_List_get_x21___rarg(x_33, x_1, x_32);
x_35 = l_List_foldl___at_compute__next__p__list___spec__2___closed__2;
x_36 = lean_int_mul(x_35, x_34);
lean_dec(x_34);
x_37 = lean_int_add(x_3, x_36);
lean_dec(x_36);
lean_dec(x_3);
if (x_20 == 0)
{
lean_object* x_38; lean_object* x_39; 
lean_dec(x_16);
x_38 = l_List_foldl___at_compute__next__p__list___spec__2___closed__3;
x_39 = lean_int_add(x_37, x_38);
lean_dec(x_37);
x_3 = x_39;
x_4 = x_6;
goto _start;
}
else
{
lean_object* x_41; lean_object* x_42; lean_object* x_43; lean_object* x_44; 
x_41 = lean_nat_sub(x_2, x_16);
lean_dec(x_16);
x_42 = l_List_get_x21___rarg(x_33, x_1, x_41);
x_43 = lean_int_mul(x_35, x_42);
lean_dec(x_42);
x_44 = lean_int_add(x_37, x_43);
lean_dec(x_43);
lean_dec(x_37);
x_3 = x_44;
x_4 = x_6;
goto _start;
}
}
}
else
{
if (x_19 == 0)
{
lean_object* x_46; lean_object* x_47; 
lean_dec(x_13);
x_46 = l_List_foldl___at_compute__next__p__list___spec__2___closed__3;
x_47 = lean_int_add(x_3, x_46);
lean_dec(x_3);
if (x_20 == 0)
{
lean_object* x_48; 
lean_dec(x_16);
x_48 = lean_int_add(x_47, x_46);
lean_dec(x_47);
x_3 = x_48;
x_4 = x_6;
goto _start;
}
else
{
lean_object* x_50; lean_object* x_51; lean_object* x_52; lean_object* x_53; lean_object* x_54; lean_object* x_55; 
x_50 = lean_nat_sub(x_2, x_16);
lean_dec(x_16);
x_51 = l_Int_instInhabited;
x_52 = l_List_get_x21___rarg(x_51, x_1, x_50);
x_53 = l_List_foldl___at_compute__next__p__list___spec__2___closed__1;
x_54 = lean_int_mul(x_53, x_52);
lean_dec(x_52);
x_55 = lean_int_add(x_47, x_54);
lean_dec(x_54);
lean_dec(x_47);
x_3 = x_55;
x_4 = x_6;
goto _start;
}
}
else
{
lean_object* x_57; lean_object* x_58; lean_object* x_59; lean_object* x_60; lean_object* x_61; lean_object* x_62; 
x_57 = lean_nat_sub(x_2, x_13);
lean_dec(x_13);
x_58 = l_Int_instInhabited;
x_59 = l_List_get_x21___rarg(x_58, x_1, x_57);
x_60 = l_List_foldl___at_compute__next__p__list___spec__2___closed__1;
x_61 = lean_int_mul(x_60, x_59);
lean_dec(x_59);
x_62 = lean_int_add(x_3, x_61);
lean_dec(x_61);
lean_dec(x_3);
if (x_20 == 0)
{
lean_object* x_63; lean_object* x_64; 
lean_dec(x_16);
x_63 = l_List_foldl___at_compute__next__p__list___spec__2___closed__3;
x_64 = lean_int_add(x_62, x_63);
lean_dec(x_62);
x_3 = x_64;
x_4 = x_6;
goto _start;
}
else
{
lean_object* x_66; lean_object* x_67; lean_object* x_68; lean_object* x_69; 
x_66 = lean_nat_sub(x_2, x_16);
lean_dec(x_16);
x_67 = l_List_get_x21___rarg(x_58, x_1, x_66);
x_68 = lean_int_mul(x_60, x_67);
lean_dec(x_67);
x_69 = lean_int_add(x_62, x_68);
lean_dec(x_68);
lean_dec(x_62);
x_3 = x_69;
x_4 = x_6;
goto _start;
}
}
}
}
}
}
LEAN_EXPORT lean_object* l_compute__next__p__list(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; 
lean_inc(x_2);
x_3 = l_List_range(x_2);
x_4 = lean_box(0);
x_5 = l_List_mapTR_loop___at_compute__next__p__list___spec__1(x_3, x_4);
x_6 = l_List_foldl___at_compute__next__p__list___spec__2___closed__3;
x_7 = l_List_foldl___at_compute__next__p__list___spec__2(x_1, x_2, x_6, x_5);
lean_dec(x_5);
lean_dec(x_2);
return x_7;
}
}
LEAN_EXPORT lean_object* l_List_foldl___at_compute__next__p__list___spec__2___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_List_foldl___at_compute__next__p__list___spec__2(x_1, x_2, x_3, x_4);
lean_dec(x_4);
lean_dec(x_2);
lean_dec(x_1);
return x_5;
}
}
LEAN_EXPORT lean_object* l_compute__next__p__list___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_compute__next__p__list(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
static lean_object* _init_l_compute__partitions__list___closed__1() {
_start:
{
lean_object* x_1; lean_object* x_2; lean_object* x_3; 
x_1 = lean_box(0);
x_2 = l_List_foldl___at_compute__next__p__list___spec__2___closed__1;
x_3 = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(x_3, 0, x_2);
lean_ctor_set(x_3, 1, x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_compute__partitions__list(lean_object* x_1) {
_start:
{
lean_object* x_2; uint8_t x_3; 
x_2 = lean_unsigned_to_nat(0u);
x_3 = lean_nat_dec_eq(x_1, x_2);
if (x_3 == 0)
{
lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; 
x_4 = lean_unsigned_to_nat(1u);
x_5 = lean_nat_sub(x_1, x_4);
x_6 = l_compute__partitions__list(x_5);
x_7 = lean_nat_add(x_5, x_4);
lean_dec(x_5);
x_8 = l_compute__next__p__list(x_6, x_7);
x_9 = lean_box(0);
x_10 = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(x_10, 0, x_8);
lean_ctor_set(x_10, 1, x_9);
x_11 = l_List_appendTR___rarg(x_6, x_10);
return x_11;
}
else
{
lean_object* x_12; 
x_12 = l_compute__partitions__list___closed__1;
return x_12;
}
}
}
LEAN_EXPORT lean_object* l_compute__partitions__list___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_compute__partitions__list(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_p(lean_object* x_1) {
_start:
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_2 = l_compute__partitions__list(x_1);
x_3 = l_Int_instInhabited;
x_4 = l_List_get_x21___rarg(x_3, x_2, x_1);
lean_dec(x_2);
return x_4;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_Partition(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_List_foldl___at_compute__next__p__list___spec__2___closed__1 = _init_l_List_foldl___at_compute__next__p__list___spec__2___closed__1();
lean_mark_persistent(l_List_foldl___at_compute__next__p__list___spec__2___closed__1);
l_List_foldl___at_compute__next__p__list___spec__2___closed__2 = _init_l_List_foldl___at_compute__next__p__list___spec__2___closed__2();
lean_mark_persistent(l_List_foldl___at_compute__next__p__list___spec__2___closed__2);
l_List_foldl___at_compute__next__p__list___spec__2___closed__3 = _init_l_List_foldl___at_compute__next__p__list___spec__2___closed__3();
lean_mark_persistent(l_List_foldl___at_compute__next__p__list___spec__2___closed__3);
l_compute__partitions__list___closed__1 = _init_l_compute__partitions__list___closed__1();
lean_mark_persistent(l_compute__partitions__list___closed__1);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
