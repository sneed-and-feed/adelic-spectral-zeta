// Lean compiler output
// Module: Formalization.SchreierSpectral
// Imports: Init Mathlib.Data.Matrix.Basic Mathlib.Algebra.Module.Submodule.Basic Mathlib.LinearAlgebra.Matrix.Hermitian Mathlib.LinearAlgebra.Matrix.Spectrum Mathlib.LinearAlgebra.Matrix.Gershgorin Formalization.SchreierConnectivity
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
extern lean_object* l_Rat_addCommMonoid;
LEAN_EXPORT lean_object* l_SchreierSpectral_supportGraph(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1___rarg___boxed(lean_object*);
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__2(lean_object*, lean_object*);
lean_object* l_ZMod_commRing(lean_object*);
lean_object* l_Pi_addMonoid___rarg(lean_object*);
static lean_object* l_SchreierSpectral_symSubspace___closed__1;
LEAN_EXPORT lean_object* l_SchreierSpectral_canonicalLift(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__1___boxed(lean_object*, lean_object*);
uint8_t l_ZMod_decidableEq(lean_object*, lean_object*, lean_object*);
lean_object* l_Semifield_toDivisionSemiring___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_canonicalLift___boxed(lean_object*, lean_object*);
static lean_object* l_SchreierSpectral_sheetSplit___elambda__2___closed__1;
static lean_object* l_SchreierSpectral_symSubspace___closed__2;
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2(lean_object*);
lean_object* l_tau(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1___boxed(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2___boxed(lean_object*);
lean_object* l_pi(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_antisymSubspace(lean_object*, lean_object*);
lean_object* l_Semifield_toCommGroupWithZero___rarg(lean_object*);
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter___rarg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2___rarg___boxed(lean_object*);
lean_object* l_ZMod_instField(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_toBlockIndices(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace___lambda__1___boxed(lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_SchreierSpectral_canonicalLift___spec__1___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter(lean_object*, lean_object*);
lean_object* l_AddMonoid_toAddZeroClass___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace___boxed(lean_object*, lean_object*);
static lean_object* l_SchreierSpectral_sheetSplit___elambda__1___closed__2;
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__1(lean_object*, lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
static lean_object* l_SchreierSpectral_symSubspace___closed__3;
LEAN_EXPORT lean_object* l_Nat_cast___at_SchreierSpectral_canonicalLift___spec__1(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter___rarg(lean_object*, lean_object*, lean_object*);
static lean_object* l_SchreierSpectral_sheetSplit___elambda__1___closed__3;
static lean_object* l_SchreierSpectral_symSubspace___closed__4;
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__2___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace___lambda__1(lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter___rarg(lean_object*, lean_object*, lean_object*);
lean_object* l_Field_toSemifield___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1(lean_object*);
static lean_object* l_SchreierSpectral_sheetSplit___elambda__1___closed__1;
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1___rarg(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_antisymSubspace___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_supportGraph___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___boxed(lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace(lean_object*, lean_object*);
lean_object* l_ZMod_val(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_SchreierSpectral_canonicalLift___spec__1(lean_object* x_1, lean_object* x_2) {
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
LEAN_EXPORT lean_object* l_SchreierSpectral_canonicalLift(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; 
x_3 = lean_unsigned_to_nat(2u);
x_4 = lean_nat_sub(x_1, x_3);
x_5 = lean_nat_pow(x_3, x_4);
lean_dec(x_4);
x_6 = l_ZMod_val(x_5, x_2);
lean_dec(x_2);
lean_dec(x_5);
x_7 = l_Nat_cast___at_SchreierSpectral_canonicalLift___spec__1(x_1, x_6);
return x_7;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_SchreierSpectral_canonicalLift___spec__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_SchreierSpectral_canonicalLift___spec__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_canonicalLift___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_canonicalLift(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
static lean_object* _init_l_SchreierSpectral_sheetSplit___elambda__1___closed__1() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = lean_unsigned_to_nat(2u);
x_2 = l_ZMod_instField(x_1, lean_box(0));
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_sheetSplit___elambda__1___closed__2() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_sheetSplit___elambda__1___closed__1;
x_2 = l_Field_toSemifield___rarg(x_1);
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_sheetSplit___elambda__1___closed__3() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_sheetSplit___elambda__1___closed__2;
x_2 = l_Semifield_toCommGroupWithZero___rarg(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__1(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; uint8_t x_8; 
x_3 = lean_ctor_get(x_2, 1);
lean_inc(x_3);
x_4 = l_SchreierSpectral_sheetSplit___elambda__1___closed__3;
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
x_10 = l_SchreierSpectral_canonicalLift(x_1, x_9);
x_11 = l_tau(x_1, x_10);
return x_11;
}
else
{
lean_object* x_12; lean_object* x_13; 
x_12 = lean_ctor_get(x_2, 0);
lean_inc(x_12);
lean_dec(x_2);
x_13 = l_SchreierSpectral_canonicalLift(x_1, x_12);
return x_13;
}
}
}
static lean_object* _init_l_SchreierSpectral_sheetSplit___elambda__2___closed__1() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_sheetSplit___elambda__1___closed__2;
x_2 = l_Semifield_toDivisionSemiring___rarg(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__2(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; uint8_t x_11; 
lean_inc(x_2);
x_3 = l_pi(x_1, x_2);
x_4 = lean_unsigned_to_nat(1u);
x_5 = lean_nat_sub(x_1, x_4);
x_6 = lean_unsigned_to_nat(2u);
x_7 = lean_nat_pow(x_6, x_5);
lean_dec(x_5);
x_8 = l_ZMod_val(x_7, x_2);
lean_dec(x_2);
lean_dec(x_7);
x_9 = lean_nat_sub(x_1, x_6);
x_10 = lean_nat_pow(x_6, x_9);
lean_dec(x_9);
x_11 = lean_nat_dec_lt(x_8, x_10);
lean_dec(x_10);
lean_dec(x_8);
if (x_11 == 0)
{
lean_object* x_12; lean_object* x_13; lean_object* x_14; lean_object* x_15; 
x_12 = l_SchreierSpectral_sheetSplit___elambda__2___closed__1;
x_13 = lean_ctor_get(x_12, 0);
lean_inc(x_13);
x_14 = lean_ctor_get(x_13, 1);
lean_inc(x_14);
lean_dec(x_13);
x_15 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_15, 0, x_3);
lean_ctor_set(x_15, 1, x_14);
return x_15;
}
else
{
lean_object* x_16; lean_object* x_17; lean_object* x_18; lean_object* x_19; 
x_16 = l_SchreierSpectral_sheetSplit___elambda__1___closed__3;
x_17 = lean_ctor_get(x_16, 0);
lean_inc(x_17);
x_18 = lean_ctor_get(x_17, 1);
lean_inc(x_18);
lean_dec(x_17);
x_19 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_19, 0, x_3);
lean_ctor_set(x_19, 1, x_18);
return x_19;
}
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; 
lean_inc(x_1);
x_3 = lean_alloc_closure((void*)(l_SchreierSpectral_sheetSplit___elambda__2___boxed), 2, 1);
lean_closure_set(x_3, 0, x_1);
x_4 = lean_alloc_closure((void*)(l_SchreierSpectral_sheetSplit___elambda__1___boxed), 2, 1);
lean_closure_set(x_4, 0, x_1);
x_5 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_5, 0, x_3);
lean_ctor_set(x_5, 1, x_4);
return x_5;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_sheetSplit___elambda__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sheetSplit___elambda__2___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_sheetSplit___elambda__2(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace___lambda__1(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_Rat_addCommMonoid;
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_symSubspace___closed__1() {
_start:
{
lean_object* x_1; 
x_1 = lean_alloc_closure((void*)(l_SchreierSpectral_symSubspace___lambda__1___boxed), 1, 0);
return x_1;
}
}
static lean_object* _init_l_SchreierSpectral_symSubspace___closed__2() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_symSubspace___closed__1;
x_2 = l_Pi_addMonoid___rarg(x_1);
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_symSubspace___closed__3() {
_start:
{
lean_object* x_1; lean_object* x_2; 
x_1 = l_SchreierSpectral_symSubspace___closed__2;
x_2 = l_AddMonoid_toAddZeroClass___rarg(x_1);
return x_2;
}
}
static lean_object* _init_l_SchreierSpectral_symSubspace___closed__4() {
_start:
{
lean_object* x_1; 
x_1 = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(x_1, 0, lean_box(0));
return x_1;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_symSubspace___closed__4;
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace___lambda__1___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_symSubspace___lambda__1(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_symSubspace___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_symSubspace(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisymSubspace(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_symSubspace___closed__4;
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_antisymSubspace___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_antisymSubspace(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_toBlockIndices(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_SchreierSpectral_sheetSplit(x_1, lean_box(0));
return x_3;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1___rarg(lean_object* x_1) {
_start:
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; uint8_t x_5; 
x_2 = lean_ctor_get(x_1, 0);
x_3 = lean_ctor_get(x_1, 1);
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_nat_dec_eq(x_3, x_4);
if (x_5 == 0)
{
lean_object* x_6; 
lean_inc(x_2);
x_6 = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(x_6, 0, x_2);
return x_6;
}
else
{
lean_object* x_7; 
lean_inc(x_2);
x_7 = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(x_7, 0, x_2);
return x_7;
}
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_SchreierSpectral_sumProdEquiv___elambda__1___rarg___boxed), 1, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2___rarg(lean_object* x_1) {
_start:
{
if (lean_obj_tag(x_1) == 0)
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; 
x_2 = lean_ctor_get(x_1, 0);
x_3 = l_SchreierSpectral_sheetSplit___elambda__1___closed__3;
x_4 = lean_ctor_get(x_3, 0);
lean_inc(x_4);
x_5 = lean_ctor_get(x_4, 1);
lean_inc(x_5);
lean_dec(x_4);
lean_inc(x_2);
x_6 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_6, 0, x_2);
lean_ctor_set(x_6, 1, x_5);
return x_6;
}
else
{
lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; 
x_7 = lean_ctor_get(x_1, 0);
x_8 = l_SchreierSpectral_sheetSplit___elambda__2___closed__1;
x_9 = lean_ctor_get(x_8, 0);
lean_inc(x_9);
x_10 = lean_ctor_get(x_9, 1);
lean_inc(x_10);
lean_dec(x_9);
lean_inc(x_7);
x_11 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_11, 0, x_7);
lean_ctor_set(x_11, 1, x_10);
return x_11;
}
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_SchreierSpectral_sumProdEquiv___elambda__2___rarg___boxed), 1, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv(lean_object* x_1) {
_start:
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; 
x_2 = lean_alloc_closure((void*)(l_SchreierSpectral_sumProdEquiv___elambda__2___rarg___boxed), 1, 0);
x_3 = lean_alloc_closure((void*)(l_SchreierSpectral_sumProdEquiv___elambda__1___rarg___boxed), 1, 0);
x_4 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_4, 0, x_2);
lean_ctor_set(x_4, 1, x_3);
return x_4;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1___rarg___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_sumProdEquiv___elambda__1___rarg(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__1___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_sumProdEquiv___elambda__1(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2___rarg___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_sumProdEquiv___elambda__2___rarg(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___elambda__2___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_sumProdEquiv___elambda__2(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_sumProdEquiv___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_sumProdEquiv(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter___rarg(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
if (lean_obj_tag(x_1) == 0)
{
lean_object* x_4; lean_object* x_5; 
lean_dec(x_3);
x_4 = lean_ctor_get(x_1, 0);
lean_inc(x_4);
lean_dec(x_1);
x_5 = lean_apply_1(x_2, x_4);
return x_5;
}
else
{
lean_object* x_6; lean_object* x_7; 
lean_dec(x_2);
x_6 = lean_ctor_get(x_1, 0);
lean_inc(x_6);
lean_dec(x_1);
x_7 = lean_apply_1(x_3, x_6);
return x_7;
}
}
}
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = lean_alloc_closure((void*)(l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter___rarg), 3, 0);
return x_3;
}
}
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__1_splitter(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter___rarg(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; uint8_t x_5; 
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_nat_dec_eq(x_1, x_4);
if (x_5 == 0)
{
lean_inc(x_3);
return x_3;
}
else
{
lean_inc(x_2);
return x_2;
}
}
}
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter___rarg___boxed), 3, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter___rarg___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l___private_Formalization_SchreierSpectral_0__SchreierSpectral_sumProdEquiv_match__2_splitter___rarg(x_1, x_2, x_3);
lean_dec(x_3);
lean_dec(x_2);
lean_dec(x_1);
return x_4;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_supportGraph(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4, lean_object* x_5) {
_start:
{
lean_object* x_6; 
x_6 = lean_box(0);
return x_6;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_supportGraph___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4, lean_object* x_5) {
_start:
{
lean_object* x_6; 
x_6 = l_SchreierSpectral_supportGraph(x_1, x_2, x_3, x_4, x_5);
lean_dec(x_4);
lean_dec(x_3);
lean_dec(x_2);
return x_6;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Matrix_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Algebra_Module_Submodule_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_Hermitian(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_Gershgorin(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierConnectivity(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_SchreierSpectral(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Matrix_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Algebra_Module_Submodule_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_Hermitian(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_Gershgorin(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierConnectivity(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_SchreierSpectral_sheetSplit___elambda__1___closed__1 = _init_l_SchreierSpectral_sheetSplit___elambda__1___closed__1();
lean_mark_persistent(l_SchreierSpectral_sheetSplit___elambda__1___closed__1);
l_SchreierSpectral_sheetSplit___elambda__1___closed__2 = _init_l_SchreierSpectral_sheetSplit___elambda__1___closed__2();
lean_mark_persistent(l_SchreierSpectral_sheetSplit___elambda__1___closed__2);
l_SchreierSpectral_sheetSplit___elambda__1___closed__3 = _init_l_SchreierSpectral_sheetSplit___elambda__1___closed__3();
lean_mark_persistent(l_SchreierSpectral_sheetSplit___elambda__1___closed__3);
l_SchreierSpectral_sheetSplit___elambda__2___closed__1 = _init_l_SchreierSpectral_sheetSplit___elambda__2___closed__1();
lean_mark_persistent(l_SchreierSpectral_sheetSplit___elambda__2___closed__1);
l_SchreierSpectral_symSubspace___closed__1 = _init_l_SchreierSpectral_symSubspace___closed__1();
lean_mark_persistent(l_SchreierSpectral_symSubspace___closed__1);
l_SchreierSpectral_symSubspace___closed__2 = _init_l_SchreierSpectral_symSubspace___closed__2();
lean_mark_persistent(l_SchreierSpectral_symSubspace___closed__2);
l_SchreierSpectral_symSubspace___closed__3 = _init_l_SchreierSpectral_symSubspace___closed__3();
lean_mark_persistent(l_SchreierSpectral_symSubspace___closed__3);
l_SchreierSpectral_symSubspace___closed__4 = _init_l_SchreierSpectral_symSubspace___closed__4();
lean_mark_persistent(l_SchreierSpectral_symSubspace___closed__4);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
