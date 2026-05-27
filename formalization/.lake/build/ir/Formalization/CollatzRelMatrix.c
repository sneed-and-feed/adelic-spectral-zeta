// Lean compiler output
// Module: Formalization.CollatzRelMatrix
// Imports: Init Mathlib Formalization.SchreierSpectral
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
lean_object* l_CommRing_toNonUnitalCommRing___rarg(lean_object*);
lean_object* l_ZMod_commRing(lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_CollatzDirMatrix_tauDir___spec__1(lean_object*, lean_object*);
lean_object* l_NonUnitalNonAssocSemiring_toDistrib___rarg(lean_object*);
lean_object* l_NonUnitalNonAssocCommRing_toNonUnitalNonAssocCommSemiring___rarg(lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_CollatzDirMatrix_tauDir___spec__1___boxed(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_CollatzDirMatrix_tauDir(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_CollatzDirMatrix_tauDir___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_CollatzDirMatrix_tauDir___spec__1(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; 
x_3 = lean_unsigned_to_nat(2u);
x_4 = lean_nat_pow(x_3, x_1);
x_5 = l_ZMod_commRing(x_4);
x_6 = lean_ctor_get(x_5, 0);
lean_inc(x_6);
lean_dec(x_5);
x_7 = lean_ctor_get(x_6, 2);
lean_inc(x_7);
lean_dec(x_6);
x_8 = lean_apply_1(x_7, x_2);
return x_8;
}
}
LEAN_EXPORT lean_object* l_CollatzDirMatrix_tauDir(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; 
x_3 = lean_unsigned_to_nat(2u);
x_4 = lean_nat_pow(x_3, x_1);
x_5 = l_ZMod_commRing(x_4);
x_6 = l_CommRing_toNonUnitalCommRing___rarg(x_5);
lean_dec(x_5);
x_7 = l_NonUnitalNonAssocCommRing_toNonUnitalNonAssocCommSemiring___rarg(x_6);
lean_dec(x_6);
x_8 = l_NonUnitalNonAssocSemiring_toDistrib___rarg(x_7);
lean_dec(x_7);
x_9 = lean_ctor_get(x_8, 1);
lean_inc(x_9);
lean_dec(x_8);
x_10 = lean_unsigned_to_nat(1u);
x_11 = lean_nat_sub(x_1, x_10);
x_12 = lean_nat_pow(x_3, x_11);
lean_dec(x_11);
x_13 = l_Nat_cast___at_CollatzDirMatrix_tauDir___spec__1(x_1, x_12);
x_14 = lean_apply_2(x_9, x_2, x_13);
return x_14;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_CollatzDirMatrix_tauDir___spec__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_CollatzDirMatrix_tauDir___spec__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_CollatzDirMatrix_tauDir___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_CollatzDirMatrix_tauDir(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierSpectral(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_CollatzRelMatrix(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierSpectral(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
