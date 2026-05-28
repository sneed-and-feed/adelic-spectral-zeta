// Lean compiler output
// Module: Formalization.CyclotomicProduct
// Imports: Init Mathlib.Data.ZMod.Basic Mathlib.RingTheory.RootsOfUnity.Basic Mathlib.RingTheory.Polynomial.Cyclotomic.Eval
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
LEAN_EXPORT lean_object* l_Finset_prod___at_W__2___spec__1___rarg___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1___boxed(lean_object*, lean_object*, lean_object*);
lean_object* l_ZMod_commRing(lean_object*);
LEAN_EXPORT lean_object* l_W__1___rarg___lambda__1___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_W__1___rarg(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_W__1(lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2(lean_object*);
LEAN_EXPORT lean_object* l_Finset_prod___at_W__1___spec__1(lean_object*);
LEAN_EXPORT lean_object* l_Finset_prod___at_W__1___spec__1___rarg___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_NonUnitalNonAssocSemiring_toDistrib___rarg(lean_object*);
lean_object* l_Semifield_toDivisionSemiring___rarg(lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg(lean_object*, lean_object*);
lean_object* l_NonUnitalNonAssocCommRing_toNonUnitalNonAssocCommSemiring___rarg(lean_object*);
lean_object* l_Multiset_map___rarg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__2___spec__2___rarg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__2___spec__2(lean_object*);
LEAN_EXPORT lean_object* l_W__1___rarg___lambda__1(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Finset_prod___at_W__2___spec__1___rarg(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__2___spec__2___rarg(lean_object*, lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_W__2(lean_object*);
lean_object* l_Monoid_toMulOneClass___rarg(lean_object*);
LEAN_EXPORT lean_object* l_Finset_prod___at_W__1___spec__1___rarg(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_CommRing_toCommMonoid___rarg(lean_object*);
lean_object* l_List_foldrTR___rarg(lean_object*, lean_object*, lean_object*);
lean_object* l_Field_toSemifield___rarg(lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_W__2___rarg(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_ZMod_val(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Finset_prod___at_W__2___spec__1(lean_object*);
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; lean_object* x_5; lean_object* x_6; 
x_4 = l_Monoid_toMulOneClass___rarg(x_1);
x_5 = lean_ctor_get(x_4, 1);
lean_inc(x_5);
lean_dec(x_4);
x_6 = lean_apply_2(x_5, x_2, x_3);
return x_6;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; 
x_3 = lean_ctor_get(x_1, 0);
x_4 = l_CommRing_toCommMonoid___rarg(x_3);
lean_inc(x_4);
x_5 = lean_alloc_closure((void*)(l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1___boxed), 3, 1);
lean_closure_set(x_5, 0, x_4);
x_6 = lean_ctor_get(x_4, 1);
lean_inc(x_6);
lean_dec(x_4);
x_7 = l_List_foldrTR___rarg(x_5, x_6, x_2);
return x_7;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_Multiset_prod___at_W__1___spec__2___rarg___boxed), 2, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Finset_prod___at_W__1___spec__1___rarg(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; lean_object* x_6; 
lean_dec(x_2);
x_5 = l_Multiset_map___rarg(x_4, x_3);
x_6 = l_Multiset_prod___at_W__1___spec__2___rarg(x_1, x_5);
return x_6;
}
}
LEAN_EXPORT lean_object* l_Finset_prod___at_W__1___spec__1(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_Finset_prod___at_W__1___spec__1___rarg___boxed), 4, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_W__1___rarg___lambda__1(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4, lean_object* x_5) {
_start:
{
lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; lean_object* x_15; lean_object* x_16; lean_object* x_17; lean_object* x_18; lean_object* x_19; lean_object* x_20; lean_object* x_21; lean_object* x_22; 
x_6 = l_CommRing_toNonUnitalCommRing___rarg(x_1);
x_7 = l_NonUnitalNonAssocCommRing_toNonUnitalNonAssocCommSemiring___rarg(x_6);
lean_dec(x_6);
x_8 = l_NonUnitalNonAssocSemiring_toDistrib___rarg(x_7);
lean_dec(x_7);
x_9 = lean_ctor_get(x_8, 1);
lean_inc(x_9);
lean_dec(x_8);
x_10 = l_Field_toSemifield___rarg(x_2);
x_11 = l_Semifield_toDivisionSemiring___rarg(x_10);
x_12 = lean_ctor_get(x_11, 0);
lean_inc(x_12);
lean_dec(x_11);
x_13 = lean_ctor_get(x_12, 1);
lean_inc(x_13);
x_14 = lean_unsigned_to_nat(2u);
x_15 = lean_nat_pow(x_14, x_3);
lean_inc(x_15);
x_16 = l_ZMod_commRing(x_15);
x_17 = lean_ctor_get(x_16, 1);
lean_inc(x_17);
lean_dec(x_16);
x_18 = lean_apply_1(x_17, x_5);
x_19 = l_ZMod_val(x_15, x_18);
lean_dec(x_18);
lean_dec(x_15);
x_20 = lean_ctor_get(x_12, 3);
lean_inc(x_20);
lean_dec(x_12);
x_21 = lean_apply_2(x_20, x_19, x_4);
x_22 = lean_apply_2(x_9, x_13, x_21);
return x_22;
}
}
LEAN_EXPORT lean_object* l_W__1___rarg(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; lean_object* x_6; lean_object* x_7; 
x_5 = lean_ctor_get(x_1, 0);
lean_inc(x_5);
lean_inc(x_2);
lean_inc(x_1);
x_6 = lean_alloc_closure((void*)(l_W__1___rarg___lambda__1___boxed), 5, 4);
lean_closure_set(x_6, 0, x_5);
lean_closure_set(x_6, 1, x_1);
lean_closure_set(x_6, 2, x_2);
lean_closure_set(x_6, 3, x_3);
x_7 = l_Finset_prod___at_W__1___spec__1___rarg(x_1, x_2, x_4, x_6);
lean_dec(x_1);
return x_7;
}
}
LEAN_EXPORT lean_object* l_W__1(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_W__1___rarg), 4, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1(x_1, x_2, x_3);
lean_dec(x_1);
return x_4;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__1___spec__2___rarg___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Multiset_prod___at_W__1___spec__2___rarg(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_Finset_prod___at_W__1___spec__1___rarg___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_Finset_prod___at_W__1___spec__1___rarg(x_1, x_2, x_3, x_4);
lean_dec(x_1);
return x_5;
}
}
LEAN_EXPORT lean_object* l_W__1___rarg___lambda__1___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4, lean_object* x_5) {
_start:
{
lean_object* x_6; 
x_6 = l_W__1___rarg___lambda__1(x_1, x_2, x_3, x_4, x_5);
lean_dec(x_3);
lean_dec(x_2);
lean_dec(x_1);
return x_6;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__2___spec__2___rarg(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; 
x_3 = lean_ctor_get(x_1, 0);
x_4 = l_CommRing_toCommMonoid___rarg(x_3);
lean_inc(x_4);
x_5 = lean_alloc_closure((void*)(l_Multiset_prod___at_W__1___spec__2___rarg___lambda__1___boxed), 3, 1);
lean_closure_set(x_5, 0, x_4);
x_6 = lean_ctor_get(x_4, 1);
lean_inc(x_6);
lean_dec(x_4);
x_7 = l_List_foldrTR___rarg(x_5, x_6, x_2);
return x_7;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__2___spec__2(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_Multiset_prod___at_W__2___spec__2___rarg___boxed), 2, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Finset_prod___at_W__2___spec__1___rarg(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; lean_object* x_6; 
lean_dec(x_2);
x_5 = l_Multiset_map___rarg(x_4, x_3);
x_6 = l_Multiset_prod___at_W__2___spec__2___rarg(x_1, x_5);
return x_6;
}
}
LEAN_EXPORT lean_object* l_Finset_prod___at_W__2___spec__1(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_Finset_prod___at_W__2___spec__1___rarg___boxed), 4, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_W__2___rarg(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; lean_object* x_6; lean_object* x_7; 
x_5 = lean_ctor_get(x_1, 0);
lean_inc(x_5);
lean_inc(x_2);
lean_inc(x_1);
x_6 = lean_alloc_closure((void*)(l_W__1___rarg___lambda__1___boxed), 5, 4);
lean_closure_set(x_6, 0, x_5);
lean_closure_set(x_6, 1, x_1);
lean_closure_set(x_6, 2, x_2);
lean_closure_set(x_6, 3, x_3);
x_7 = l_Finset_prod___at_W__2___spec__1___rarg(x_1, x_2, x_4, x_6);
lean_dec(x_1);
return x_7;
}
}
LEAN_EXPORT lean_object* l_W__2(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_W__2___rarg), 4, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Multiset_prod___at_W__2___spec__2___rarg___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Multiset_prod___at_W__2___spec__2___rarg(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_Finset_prod___at_W__2___spec__1___rarg___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_Finset_prod___at_W__2___spec__1___rarg(x_1, x_2, x_3, x_4);
lean_dec(x_1);
return x_5;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_ZMod_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_RingTheory_RootsOfUnity_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_RingTheory_Polynomial_Cyclotomic_Eval(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_CyclotomicProduct(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_ZMod_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_RingTheory_RootsOfUnity_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_RingTheory_Polynomial_Cyclotomic_Eval(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
