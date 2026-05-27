// Lean compiler output
// Module: Formalization.Hecke
// Imports: Init Mathlib.NumberTheory.ModularForms.Basic Mathlib.NumberTheory.ModularForms.SlashActions Mathlib.Analysis.Complex.UpperHalfPlane.Basic Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup
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
LEAN_EXPORT lean_object* l_hecke__matrix__1__mat(lean_object*, lean_object*, lean_object*, lean_object*);
extern lean_object* l___private_Mathlib_Data_Real_Basic_0__Real_zero;
LEAN_EXPORT lean_object* l_hecke__matrix__1__mat___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static lean_object* l_hecke__matrix__1__mat___closed__3;
lean_object* l_Int_cast___at_Real_instIntCast___spec__2(lean_object*);
lean_object* l_Nat_cast___at_Real_instNatCast___spec__2(lean_object*);
lean_object* l_Matrix_vecEmpty___boxed(lean_object*, lean_object*);
static lean_object* l_hecke__matrix__1__mat___closed__2;
extern lean_object* l___private_Mathlib_Data_Real_Basic_0__Real_one;
LEAN_EXPORT lean_object* l_hecke__matrix__p__mat___boxed(lean_object*, lean_object*, lean_object*);
static lean_object* l_hecke__matrix__p__mat___closed__1;
static lean_object* l_hecke__matrix__1__mat___closed__4;
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* l_Fin_cases(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_hecke__matrix__p__mat(lean_object*, lean_object*, lean_object*);
lean_object* l_Matrix_vecCons___rarg___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static lean_object* l_hecke__matrix__p__mat___closed__2;
static lean_object* l_hecke__matrix__1__mat___closed__1;
static lean_object* _init_l_hecke__matrix__1__mat___closed__1() {
_start:
{
lean_object* x_1; 
x_1 = lean_alloc_closure((void*)(l_Matrix_vecEmpty___boxed), 2, 1);
lean_closure_set(x_1, 0, lean_box(0));
return x_1;
}
}
static lean_object* _init_l_hecke__matrix__1__mat___closed__2() {
_start:
{
lean_object* x_1; lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_1 = lean_unsigned_to_nat(0u);
x_2 = l___private_Mathlib_Data_Real_Basic_0__Real_one;
x_3 = l_hecke__matrix__1__mat___closed__1;
x_4 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_4, 0, x_1);
lean_closure_set(x_4, 1, x_2);
lean_closure_set(x_4, 2, x_3);
return x_4;
}
}
static lean_object* _init_l_hecke__matrix__1__mat___closed__3() {
_start:
{
lean_object* x_1; lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_1 = lean_unsigned_to_nat(1u);
x_2 = l___private_Mathlib_Data_Real_Basic_0__Real_zero;
x_3 = l_hecke__matrix__1__mat___closed__2;
x_4 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_4, 0, x_1);
lean_closure_set(x_4, 1, x_2);
lean_closure_set(x_4, 2, x_3);
return x_4;
}
}
static lean_object* _init_l_hecke__matrix__1__mat___closed__4() {
_start:
{
lean_object* x_1; lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_1 = lean_unsigned_to_nat(0u);
x_2 = l_hecke__matrix__1__mat___closed__3;
x_3 = l_hecke__matrix__1__mat___closed__1;
x_4 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_4, 0, x_1);
lean_closure_set(x_4, 1, x_2);
lean_closure_set(x_4, 2, x_3);
return x_4;
}
}
LEAN_EXPORT lean_object* l_hecke__matrix__1__mat(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; uint8_t x_12; 
x_5 = l_Int_cast___at_Real_instIntCast___spec__2(x_2);
x_6 = lean_unsigned_to_nat(0u);
x_7 = l_hecke__matrix__1__mat___closed__1;
x_8 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_8, 0, x_6);
lean_closure_set(x_8, 1, x_5);
lean_closure_set(x_8, 2, x_7);
x_9 = lean_unsigned_to_nat(1u);
x_10 = l___private_Mathlib_Data_Real_Basic_0__Real_one;
x_11 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_11, 0, x_9);
lean_closure_set(x_11, 1, x_10);
lean_closure_set(x_11, 2, x_8);
x_12 = lean_nat_dec_eq(x_1, x_6);
if (x_12 == 0)
{
lean_object* x_13; lean_object* x_14; lean_object* x_15; lean_object* x_16; lean_object* x_17; lean_object* x_18; lean_object* x_19; 
x_13 = l_Nat_cast___at_Real_instNatCast___spec__2(x_1);
x_14 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_14, 0, x_6);
lean_closure_set(x_14, 1, x_13);
lean_closure_set(x_14, 2, x_7);
x_15 = l___private_Mathlib_Data_Real_Basic_0__Real_zero;
x_16 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_16, 0, x_9);
lean_closure_set(x_16, 1, x_15);
lean_closure_set(x_16, 2, x_14);
x_17 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_17, 0, x_6);
lean_closure_set(x_17, 1, x_16);
lean_closure_set(x_17, 2, x_7);
x_18 = l_Fin_cases(x_9, lean_box(0), x_11, x_17, x_3);
lean_dec(x_11);
x_19 = lean_apply_1(x_18, x_4);
return x_19;
}
else
{
lean_object* x_20; lean_object* x_21; lean_object* x_22; 
lean_dec(x_1);
x_20 = l_hecke__matrix__1__mat___closed__4;
x_21 = l_Fin_cases(x_9, lean_box(0), x_11, x_20, x_3);
lean_dec(x_11);
x_22 = lean_apply_1(x_21, x_4);
return x_22;
}
}
}
LEAN_EXPORT lean_object* l_hecke__matrix__1__mat___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_hecke__matrix__1__mat(x_1, x_2, x_3, x_4);
lean_dec(x_3);
return x_5;
}
}
static lean_object* _init_l_hecke__matrix__p__mat___closed__1() {
_start:
{
lean_object* x_1; lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_1 = lean_unsigned_to_nat(0u);
x_2 = l___private_Mathlib_Data_Real_Basic_0__Real_zero;
x_3 = l_hecke__matrix__1__mat___closed__1;
x_4 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_4, 0, x_1);
lean_closure_set(x_4, 1, x_2);
lean_closure_set(x_4, 2, x_3);
return x_4;
}
}
static lean_object* _init_l_hecke__matrix__p__mat___closed__2() {
_start:
{
lean_object* x_1; lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_1 = lean_unsigned_to_nat(1u);
x_2 = l___private_Mathlib_Data_Real_Basic_0__Real_one;
x_3 = l_hecke__matrix__p__mat___closed__1;
x_4 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_4, 0, x_1);
lean_closure_set(x_4, 1, x_2);
lean_closure_set(x_4, 2, x_3);
return x_4;
}
}
LEAN_EXPORT lean_object* l_hecke__matrix__p__mat(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; uint8_t x_5; 
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_nat_dec_eq(x_1, x_4);
if (x_5 == 0)
{
lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; 
x_6 = l_Nat_cast___at_Real_instNatCast___spec__2(x_1);
x_7 = lean_unsigned_to_nat(1u);
x_8 = l_hecke__matrix__p__mat___closed__1;
x_9 = lean_alloc_closure((void*)(l_Matrix_vecCons___rarg___boxed), 4, 3);
lean_closure_set(x_9, 0, x_7);
lean_closure_set(x_9, 1, x_6);
lean_closure_set(x_9, 2, x_8);
x_10 = l_hecke__matrix__1__mat___closed__4;
x_11 = l_Fin_cases(x_7, lean_box(0), x_9, x_10, x_2);
lean_dec(x_9);
x_12 = lean_apply_1(x_11, x_3);
return x_12;
}
else
{
lean_object* x_13; lean_object* x_14; lean_object* x_15; lean_object* x_16; lean_object* x_17; 
lean_dec(x_1);
x_13 = lean_unsigned_to_nat(1u);
x_14 = l_hecke__matrix__p__mat___closed__2;
x_15 = l_hecke__matrix__1__mat___closed__4;
x_16 = l_Fin_cases(x_13, lean_box(0), x_14, x_15, x_2);
x_17 = lean_apply_1(x_16, x_3);
return x_17;
}
}
}
LEAN_EXPORT lean_object* l_hecke__matrix__p__mat___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_hecke__matrix__p__mat(x_1, x_2, x_3);
lean_dec(x_2);
return x_4;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_NumberTheory_ModularForms_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_NumberTheory_ModularForms_SlashActions(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Analysis_Complex_UpperHalfPlane_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_GeneralLinearGroup(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_Hecke(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_NumberTheory_ModularForms_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_NumberTheory_ModularForms_SlashActions(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Analysis_Complex_UpperHalfPlane_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_GeneralLinearGroup(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_hecke__matrix__1__mat___closed__1 = _init_l_hecke__matrix__1__mat___closed__1();
lean_mark_persistent(l_hecke__matrix__1__mat___closed__1);
l_hecke__matrix__1__mat___closed__2 = _init_l_hecke__matrix__1__mat___closed__2();
lean_mark_persistent(l_hecke__matrix__1__mat___closed__2);
l_hecke__matrix__1__mat___closed__3 = _init_l_hecke__matrix__1__mat___closed__3();
lean_mark_persistent(l_hecke__matrix__1__mat___closed__3);
l_hecke__matrix__1__mat___closed__4 = _init_l_hecke__matrix__1__mat___closed__4();
lean_mark_persistent(l_hecke__matrix__1__mat___closed__4);
l_hecke__matrix__p__mat___closed__1 = _init_l_hecke__matrix__p__mat___closed__1();
lean_mark_persistent(l_hecke__matrix__p__mat___closed__1);
l_hecke__matrix__p__mat___closed__2 = _init_l_hecke__matrix__p__mat___closed__2();
lean_mark_persistent(l_hecke__matrix__p__mat___closed__2);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
