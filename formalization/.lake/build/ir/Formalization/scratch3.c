// Lean compiler output
// Module: Formalization.scratch3
// Imports: Init Mathlib Formalization.MeanErgodic Formalization.L2Mixing
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
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__1___boxed(lean_object*, lean_object*);
lean_object* l_ZMod_commRing(lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_zmod__dist(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin___lambda__1___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__step___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__1(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__2(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__2___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__orbit(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__2___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_zmod__dist___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__step(lean_object*, lean_object*, uint8_t);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__2(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__orbit___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__1___boxed(lean_object*, lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* lean_nat_mod(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__step(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__1(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__step___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin___lambda__1(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_ZMod_val(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__1(lean_object* x_1, lean_object* x_2) {
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
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__2(lean_object* x_1, lean_object* x_2) {
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
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__step(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; uint8_t x_8; 
x_3 = lean_unsigned_to_nat(2u);
x_4 = lean_nat_pow(x_3, x_1);
x_5 = l_ZMod_val(x_4, x_2);
x_6 = lean_nat_mod(x_5, x_3);
lean_dec(x_5);
x_7 = lean_unsigned_to_nat(0u);
x_8 = lean_nat_dec_eq(x_6, x_7);
lean_dec(x_6);
if (x_8 == 0)
{
lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; lean_object* x_15; lean_object* x_16; lean_object* x_17; lean_object* x_18; 
x_9 = l_ZMod_commRing(x_4);
x_10 = lean_ctor_get(x_9, 2);
lean_inc(x_10);
x_11 = l_CommRing_toNonUnitalCommRing___rarg(x_9);
x_12 = lean_ctor_get(x_11, 1);
lean_inc(x_12);
lean_dec(x_11);
x_13 = lean_ctor_get(x_9, 0);
lean_inc(x_13);
lean_dec(x_9);
x_14 = lean_unsigned_to_nat(3u);
x_15 = l_Nat_cast___at_OrbitShadowing_collatz__step___spec__1(x_1, x_14);
x_16 = lean_apply_2(x_12, x_15, x_2);
x_17 = lean_ctor_get(x_13, 1);
lean_inc(x_17);
lean_dec(x_13);
x_18 = lean_apply_2(x_10, x_16, x_17);
return x_18;
}
else
{
lean_object* x_19; lean_object* x_20; lean_object* x_21; lean_object* x_22; lean_object* x_23; lean_object* x_24; 
x_19 = l_ZMod_commRing(x_4);
x_20 = l_CommRing_toNonUnitalCommRing___rarg(x_19);
lean_dec(x_19);
x_21 = lean_ctor_get(x_20, 1);
lean_inc(x_21);
lean_dec(x_20);
x_22 = lean_unsigned_to_nat(3u);
x_23 = l_Nat_cast___at_OrbitShadowing_collatz__step___spec__2(x_1, x_22);
x_24 = lean_apply_2(x_21, x_23, x_2);
return x_24;
}
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_OrbitShadowing_collatz__step___spec__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_collatz__step___spec__2___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_OrbitShadowing_collatz__step___spec__2(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__step___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_OrbitShadowing_collatz__step(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__orbit(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; uint8_t x_5; 
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_nat_dec_eq(x_2, x_4);
if (x_5 == 0)
{
lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; 
x_6 = lean_unsigned_to_nat(1u);
x_7 = lean_nat_sub(x_2, x_6);
x_8 = l_OrbitShadowing_collatz__orbit(x_1, x_7, x_3);
lean_dec(x_7);
x_9 = l_OrbitShadowing_collatz__step(x_1, x_8);
return x_9;
}
else
{
lean_inc(x_3);
return x_3;
}
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_collatz__orbit___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_OrbitShadowing_collatz__orbit(x_1, x_2, x_3);
lean_dec(x_3);
lean_dec(x_2);
lean_dec(x_1);
return x_4;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__1(lean_object* x_1, lean_object* x_2) {
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
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__2(lean_object* x_1, lean_object* x_2) {
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
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__step(lean_object* x_1, lean_object* x_2, uint8_t x_3) {
_start:
{
if (x_3 == 0)
{
lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; lean_object* x_12; lean_object* x_13; lean_object* x_14; lean_object* x_15; 
x_4 = lean_unsigned_to_nat(2u);
x_5 = lean_nat_pow(x_4, x_1);
x_6 = l_ZMod_commRing(x_5);
x_7 = lean_ctor_get(x_6, 2);
lean_inc(x_7);
x_8 = l_CommRing_toNonUnitalCommRing___rarg(x_6);
x_9 = lean_ctor_get(x_8, 1);
lean_inc(x_9);
lean_dec(x_8);
x_10 = lean_ctor_get(x_6, 0);
lean_inc(x_10);
lean_dec(x_6);
x_11 = lean_unsigned_to_nat(3u);
x_12 = l_Nat_cast___at_OrbitShadowing_rw__step___spec__1(x_1, x_11);
x_13 = lean_apply_2(x_9, x_12, x_2);
x_14 = lean_ctor_get(x_10, 1);
lean_inc(x_14);
lean_dec(x_10);
x_15 = lean_apply_2(x_7, x_13, x_14);
return x_15;
}
else
{
lean_object* x_16; lean_object* x_17; lean_object* x_18; lean_object* x_19; lean_object* x_20; lean_object* x_21; lean_object* x_22; lean_object* x_23; 
x_16 = lean_unsigned_to_nat(2u);
x_17 = lean_nat_pow(x_16, x_1);
x_18 = l_ZMod_commRing(x_17);
x_19 = l_CommRing_toNonUnitalCommRing___rarg(x_18);
lean_dec(x_18);
x_20 = lean_ctor_get(x_19, 1);
lean_inc(x_20);
lean_dec(x_19);
x_21 = lean_unsigned_to_nat(3u);
x_22 = l_Nat_cast___at_OrbitShadowing_rw__step___spec__2(x_1, x_21);
x_23 = lean_apply_2(x_20, x_22, x_2);
return x_23;
}
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__1___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_OrbitShadowing_rw__step___spec__1(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_Nat_cast___at_OrbitShadowing_rw__step___spec__2___boxed(lean_object* x_1, lean_object* x_2) {
_start:
{
lean_object* x_3; 
x_3 = l_Nat_cast___at_OrbitShadowing_rw__step___spec__2(x_1, x_2);
lean_dec(x_1);
return x_3;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__step___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
uint8_t x_4; lean_object* x_5; 
x_4 = lean_unbox(x_3);
lean_dec(x_3);
x_5 = l_OrbitShadowing_rw__step(x_1, x_2, x_4);
lean_dec(x_1);
return x_5;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; uint8_t x_6; 
x_5 = lean_unsigned_to_nat(0u);
x_6 = lean_nat_dec_eq(x_2, x_5);
if (x_6 == 0)
{
lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; uint8_t x_11; lean_object* x_12; 
x_7 = lean_unsigned_to_nat(1u);
x_8 = lean_nat_sub(x_2, x_7);
lean_inc(x_3);
x_9 = l_OrbitShadowing_rw__path(x_1, x_8, x_3, x_4);
x_10 = lean_apply_1(x_3, x_8);
x_11 = lean_unbox(x_10);
lean_dec(x_10);
x_12 = l_OrbitShadowing_rw__step(x_1, x_9, x_11);
return x_12;
}
else
{
lean_dec(x_3);
lean_inc(x_4);
return x_4;
}
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_OrbitShadowing_rw__path(x_1, x_2, x_3, x_4);
lean_dec(x_4);
lean_dec(x_2);
lean_dec(x_1);
return x_5;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin___lambda__1(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
uint8_t x_4; 
x_4 = lean_nat_dec_lt(x_3, x_1);
if (x_4 == 0)
{
uint8_t x_5; lean_object* x_6; 
lean_dec(x_3);
lean_dec(x_2);
x_5 = 0;
x_6 = lean_box(x_5);
return x_6;
}
else
{
lean_object* x_7; 
x_7 = lean_apply_1(x_2, x_3);
return x_7;
}
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; lean_object* x_6; 
lean_inc(x_2);
x_5 = lean_alloc_closure((void*)(l_OrbitShadowing_rw__path__fin___lambda__1___boxed), 3, 2);
lean_closure_set(x_5, 0, x_2);
lean_closure_set(x_5, 1, x_3);
x_6 = l_OrbitShadowing_rw__path(x_1, x_2, x_5, x_4);
lean_dec(x_2);
return x_6;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin___lambda__1___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_OrbitShadowing_rw__path__fin___lambda__1(x_1, x_2, x_3);
lean_dec(x_1);
return x_4;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_rw__path__fin___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3, lean_object* x_4) {
_start:
{
lean_object* x_5; 
x_5 = l_OrbitShadowing_rw__path__fin(x_1, x_2, x_3, x_4);
lean_dec(x_4);
lean_dec(x_1);
return x_5;
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_zmod__dist(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; lean_object* x_10; lean_object* x_11; uint8_t x_12; 
x_4 = lean_unsigned_to_nat(2u);
x_5 = lean_nat_pow(x_4, x_1);
lean_inc(x_5);
x_6 = l_ZMod_commRing(x_5);
x_7 = lean_ctor_get(x_6, 2);
lean_inc(x_7);
lean_dec(x_6);
lean_inc(x_7);
lean_inc(x_3);
lean_inc(x_2);
x_8 = lean_apply_2(x_7, x_2, x_3);
x_9 = l_ZMod_val(x_5, x_8);
lean_dec(x_8);
x_10 = lean_apply_2(x_7, x_3, x_2);
x_11 = l_ZMod_val(x_5, x_10);
lean_dec(x_10);
lean_dec(x_5);
x_12 = lean_nat_dec_le(x_9, x_11);
if (x_12 == 0)
{
lean_dec(x_9);
return x_11;
}
else
{
lean_dec(x_11);
return x_9;
}
}
}
LEAN_EXPORT lean_object* l_OrbitShadowing_zmod__dist___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_OrbitShadowing_zmod__dist(x_1, x_2, x_3);
lean_dec(x_1);
return x_4;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_MeanErgodic(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_L2Mixing(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_scratch3(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_MeanErgodic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_L2Mixing(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
