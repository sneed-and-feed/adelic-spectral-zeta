// Lean compiler output
// Module: Formalization.SchreierConnectivity
// Imports: Init Mathlib.Data.ZMod.Basic Mathlib.Combinatorics.SimpleGraph.Basic Mathlib.Combinatorics.SimpleGraph.Connectivity Mathlib.Tactic
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
LEAN_EXPORT lean_object* l_tau__hom___elambda__1___boxed(lean_object*, lean_object*);
lean_object* l_CommRing_toNonUnitalCommRing___rarg(lean_object*);
LEAN_EXPORT lean_object* l_ZMod_castHom___at_pi___spec__1(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_ZMod_unitOfCoprime(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_tau___spec__1(lean_object*, lean_object*);
lean_object* l_Ring_toAddGroupWithOne___rarg(lean_object*);
LEAN_EXPORT lean_object* l_tau__hom(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_G__d___boxed(lean_object*);
lean_object* l_ZMod_commRing(lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_pi___spec__4(lean_object*, lean_object*);
lean_object* l_NonUnitalNonAssocSemiring_toDistrib___rarg(lean_object*);
LEAN_EXPORT lean_object* l_pi___boxed(lean_object*, lean_object*);
lean_object* l_NonUnitalNonAssocCommRing_toNonUnitalNonAssocCommSemiring___rarg(lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_tau___spec__1___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_tau(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_ZMod_cast___at_pi___spec__2(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_pi(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Int_cast___at_pi___spec__3___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_pi___spec__4___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_tau__hom___elambda__1(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_ZMod_castHom___at_pi___spec__1___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_inv3___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Int_cast___at_pi___spec__3(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_G__d(lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_inv3(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_ZMod_cast___at_pi___spec__2___boxed(lean_object*, lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_tau___boxed(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* l_ZMod_val(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_G__d(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_box(0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_G__d___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_G__d(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Int_cast___at_pi___spec__3(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; 
x_3 = lean_unsigned_to_nat(2u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_nat_pow(x_3, x_4);
lean_dec(x_4);
x_6 = l_ZMod_commRing(x_5);
x_7 = lean_ctor_get(x_6, 4);
lean_inc(x_7);
lean_dec(x_6);
x_8 = lean_apply_1(x_7, x_2);
return x_8;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_pi___spec__4(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; 
x_3 = lean_unsigned_to_nat(2u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_nat_pow(x_3, x_4);
lean_dec(x_4);
x_6 = l_ZMod_commRing(x_5);
x_7 = l_Ring_toAddGroupWithOne___rarg(x_6);
x_8 = lean_ctor_get(x_7, 1);
lean_inc(x_8);
lean_dec(x_7);
x_9 = lean_ctor_get(x_8, 0);
lean_inc(x_9);
lean_dec(x_8);
x_10 = lean_apply_1(x_9, x_2);
return x_10;
}
}
LEAN_EXPORT lean_object* l_ZMod_cast___at_pi___spec__2(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; uint8_t x_5; 
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_nat_dec_eq(x_2, x_4);
if (x_5 == 0)
{
lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; 
x_6 = lean_unsigned_to_nat(1u);
x_7 = lean_nat_sub(x_2, x_6);
lean_dec(x_2);
x_8 = lean_nat_add(x_7, x_6);
lean_dec(x_7);
x_9 = l_ZMod_val(x_8, x_3);
lean_dec(x_3);
lean_dec(x_8);
x_10 = l_Nat_cast___at_pi___spec__4(x_1, x_9);
return x_10;
}
else
{
lean_object* x_11; 
lean_dec(x_2);
x_11 = l_Int_cast___at_pi___spec__3(x_1, x_3);
return x_11;
}
}
}
LEAN_EXPORT lean_object* l_ZMod_castHom___at_pi___spec__1(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = lean_alloc_closure((void*)(l_ZMod_cast___at_pi___spec__2___boxed), 3, 2);
lean_closure_set(x_5, 0, x_1);
lean_closure_set(x_5, 1, x_2);
return x_5;
}
}
LEAN_EXPORT lean_object* l_pi(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; 
x_3 = lean_unsigned_to_nat(1u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_unsigned_to_nat(2u);
x_6 = lean_nat_pow(x_5, x_4);
lean_dec(x_4);
x_7 = l_ZMod_cast___at_pi___spec__2(x_1, x_6, x_2);
return x_7;
}
}
LEAN_EXPORT lean_object* l_Int_cast___at_pi___spec__3___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Int_cast___at_pi___spec__3(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_pi___spec__4___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_pi___spec__4(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_ZMod_cast___at_pi___spec__2___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_ZMod_cast___at_pi___spec__2(x_1, x_2, x_3);
lean_dec(x_1);
return x_4;
}
}
LEAN_EXPORT lean_object* l_ZMod_castHom___at_pi___spec__1___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_ZMod_castHom___at_pi___spec__1(x_1, x_2, x_3, x_4);
lean_dec(x_3);
return x_5;
}
}
LEAN_EXPORT lean_object* l_pi___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_pi(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_tau___spec__1(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; 
x_3 = lean_unsigned_to_nat(1u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_unsigned_to_nat(2u);
x_6 = lean_nat_pow(x_5, x_4);
lean_dec(x_4);
x_7 = l_ZMod_commRing(x_6);
x_8 = lean_ctor_get(x_7, 0);
lean_inc(x_8);
lean_dec(x_7);
x_9 = lean_ctor_get(x_8, 2);
lean_inc(x_9);
lean_dec(x_8);
x_10 = lean_apply_1(x_9, x_2);
return x_10;
}
}
LEAN_EXPORT lean_object* l_tau(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; lean_object* x_15; 
x_3 = lean_unsigned_to_nat(1u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_unsigned_to_nat(2u);
x_6 = lean_nat_pow(x_5, x_4);
lean_dec(x_4);
x_7 = l_ZMod_commRing(x_6);
x_8 = l_CommRing_toNonUnitalCommRing___rarg(x_7);
lean_dec(x_7);
x_9 = l_NonUnitalNonAssocCommRing_toNonUnitalNonAssocCommSemiring___rarg(x_8);
lean_dec(x_8);
x_10 = l_NonUnitalNonAssocSemiring_toDistrib___rarg(x_9);
lean_dec(x_9);
x_11 = lean_ctor_get(x_10, 1);
lean_inc(x_11);
lean_dec(x_10);
x_12 = lean_nat_sub(x_1, x_5);
x_13 = lean_nat_pow(x_5, x_12);
lean_dec(x_12);
x_14 = l_Nat_cast___at_tau___spec__1(x_1, x_13);
x_15 = lean_apply_2(x_11, x_2, x_14);
return x_15;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_tau___spec__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_tau___spec__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_tau___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_tau(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_tau__hom___elambda__1(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_tau(x_1, x_2);
return x_3;
}
}
LEAN_EXPORT lean_object* l_tau__hom(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = lean_alloc_closure((void*)(l_tau__hom___elambda__1___boxed), 2, 1);
lean_closure_set(x_3, 0, x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_tau__hom___elambda__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_tau__hom___elambda__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_inv3(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; 
x_3 = lean_unsigned_to_nat(1u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_unsigned_to_nat(2u);
x_6 = lean_nat_pow(x_5, x_4);
lean_dec(x_4);
x_7 = lean_unsigned_to_nat(3u);
x_8 = l_ZMod_unitOfCoprime(x_6, x_7, lean_box(0));
x_9 = lean_ctor_get(x_8, 1);
lean_inc(x_9);
lean_dec(x_8);
return x_9;
}
}
LEAN_EXPORT lean_object* l_inv3___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_inv3(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_ZMod_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Combinatorics_SimpleGraph_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Combinatorics_SimpleGraph_Connectivity(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Tactic(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_SchreierConnectivity(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_ZMod_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Combinatorics_SimpleGraph_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Combinatorics_SimpleGraph_Connectivity(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Tactic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
