// Lean compiler output
// Module: Formalization.SchreierAntisymBound
// Imports: Init Mathlib.Data.Matrix.Basic Mathlib.LinearAlgebra.Matrix.Spectrum Mathlib.Analysis.InnerProductSpace.PiL2 Mathlib.Data.Real.Basic Formalization.SchreierSpectral Formalization.SchreierPerronFrobenius
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
static lean_object* l_SchreierSpectral_antisym__ext__r___rarg___closed__2;
static lean_object* l_SchreierSpectral_antisym__ext__r___rarg___closed__1;
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__ext__r(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_tau__op___boxed(lean_object*, lean_object*, lean_object*);
static lean_object* l_SchreierSpectral_antisym__ext__r___rarg___closed__3;
uint8_t l_ZMod_decidableEq(lean_object*, lean_object*, lean_object*);
lean_object* l_tau(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__ext__r___boxed(lean_object*);
lean_object* l_pi(lean_object*, lean_object*);
lean_object* l_Semifield_toCommGroupWithZero___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__lift___boxed(lean_object*, lean_object*, lean_object*);
lean_object* l_ZMod_instField(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__lift(lean_object*, lean_object*, lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__ext__r___rarg(lean_object*, lean_object*);
lean_object* l_Field_toSemifield___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_tau__op(lean_object*, lean_object*, lean_object*);
lean_object* l_Real_definition____x40_Mathlib_Data_Real_Basic___hyg_886_(lean_object*);
lean_object* l_ZMod_val(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_tau__op(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; lean_object* x_5; 
x_4 = l_tau(x_1, x_3);
x_5 = lean_apply_1(x_2, x_4);
return x_5;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_tau__op___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_SchreierSpectral_tau__op(x_1, x_2, x_3);
lean_dec(x_1);
return x_4;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__lift(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; uint8_t x_11; 
x_4 = lean_unsigned_to_nat(1u);
x_5 = lean_nat_sub(x_1, x_4);
x_6 = lean_unsigned_to_nat(2u);
x_7 = lean_nat_pow(x_6, x_5);
lean_dec(x_5);
x_8 = l_ZMod_val(x_7, x_3);
lean_dec(x_7);
x_9 = lean_nat_sub(x_1, x_6);
x_10 = lean_nat_pow(x_6, x_9);
lean_dec(x_9);
x_11 = lean_nat_dec_lt(x_8, x_10);
lean_dec(x_10);
lean_dec(x_8);
if (x_11 == 0)
{
lean_object* x_12; lean_object* x_13; lean_object* x_14; 
x_12 = l_pi(x_1, x_3);
x_13 = lean_apply_1(x_2, x_12);
x_14 = l_Real_definition____x40_Mathlib_Data_Real_Basic___hyg_886_(x_13);
return x_14;
}
else
{
lean_object* x_15; lean_object* x_16; 
x_15 = l_pi(x_1, x_3);
x_16 = lean_apply_1(x_2, x_15);
return x_16;
}
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__lift___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_SchreierSpectral_antisym__lift(x_1, x_2, x_3);
lean_dec(x_1);
return x_4;
}
}
static lean_object* _init_l_SchreierSpectral_antisym__ext__r___rarg___closed__1() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = lean_unsigned_to_nat(2u);
x_2 = l_ZMod_instField(x_1, lean_box(0));
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_antisym__ext__r___rarg___closed__2() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_antisym__ext__r___rarg___closed__1;
x_2 = l_Field_toSemifield___rarg(x_1);
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_antisym__ext__r___rarg___closed__3() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_antisym__ext__r___rarg___closed__2;
x_2 = l_Semifield_toCommGroupWithZero___rarg(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__ext__r___rarg(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; uint8_t x_8; 
x_3 = lean_ctor_get(x_2, 1);
lean_inc(x_3);
x_4 = l_SchreierSpectral_antisym__ext__r___rarg___closed__3;
x_5 = lean_ctor_get(x_4, 0);
lean_inc(x_5);
x_6 = lean_ctor_get(x_5, 1);
lean_inc(x_6);
lean_dec(x_5);
x_7 = lean_unsigned_to_nat(2u);
x_8 = l_ZMod_decidableEq(x_7, x_3, x_6);
lean_dec(x_6);
lean_dec(x_3);
if (x_8 == 0)
{
lean_object* x_9; lean_object* x_10; lean_object* x_11; 
x_9 = lean_ctor_get(x_2, 0);
lean_inc(x_9);
lean_dec(x_2);
x_10 = lean_apply_1(x_1, x_9);
x_11 = l_Real_definition____x40_Mathlib_Data_Real_Basic___hyg_886_(x_10);
return x_11;
}
else
{
lean_object* x_12; lean_object* x_13; 
x_12 = lean_ctor_get(x_2, 0);
lean_inc(x_12);
lean_dec(x_2);
x_13 = lean_apply_1(x_1, x_12);
return x_13;
}
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__ext__r(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_SchreierSpectral_antisym__ext__r___rarg), 2, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisym__ext__r___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_antisym__ext__r(x_1);
lean_dec(x_1);
return x_2;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Matrix_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Analysis_InnerProductSpace_PiL2(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Real_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierSpectral(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierPerronFrobenius(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_SchreierAntisymBound(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Matrix_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Analysis_InnerProductSpace_PiL2(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Real_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierSpectral(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierPerronFrobenius(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_SchreierSpectral_antisym__ext__r___rarg___closed__1 = _init_l_SchreierSpectral_antisym__ext__r___rarg___closed__1();
lean_mark_persistent(l_SchreierSpectral_antisym__ext__r___rarg___closed__1);
l_SchreierSpectral_antisym__ext__r___rarg___closed__2 = _init_l_SchreierSpectral_antisym__ext__r___rarg___closed__2();
lean_mark_persistent(l_SchreierSpectral_antisym__ext__r___rarg___closed__2);
l_SchreierSpectral_antisym__ext__r___rarg___closed__3 = _init_l_SchreierSpectral_antisym__ext__r___rarg___closed__3();
lean_mark_persistent(l_SchreierSpectral_antisym__ext__r___rarg___closed__3);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
