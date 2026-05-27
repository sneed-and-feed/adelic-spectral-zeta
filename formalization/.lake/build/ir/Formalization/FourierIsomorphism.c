// Lean compiler output
// Module: Formalization.FourierIsomorphism
// Imports: Init Mathlib.Data.Complex.Basic Mathlib.Data.Complex.Exponential Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds Mathlib.Algebra.Group.AddChar Mathlib.LinearAlgebra.Matrix.Spectrum Mathlib.Analysis.Asymptotics.Asymptotics Formalization.SchreierSpectral Formalization.TrigSum Formalization.FourierChain
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
LEAN_EXPORT lean_object* l_SchreierSpectral_M___boxed(lean_object*);
lean_object* lean_nat_pow(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_M(lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_SchreierSpectral_M(lean_object* x_1) {
_start:
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; lean_object* x_5; 
x_2 = lean_unsigned_to_nat(3u);
x_3 = lean_nat_sub(x_1, x_2);
x_4 = lean_unsigned_to_nat(2u);
x_5 = lean_nat_pow(x_4, x_3);
lean_dec(x_3);
return x_5;
}
}
LEAN_EXPORT lean_object* l_SchreierSpectral_M___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_SchreierSpectral_M(x_1);
lean_dec(x_1);
return x_2;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Complex_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Data_Complex_Exponential(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Analysis_SpecialFunctions_Trigonometric_Basic(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Analysis_SpecialFunctions_Trigonometric_Bounds(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Algebra_Group_AddChar(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(uint8_t builtin, lean_object*);
lean_object* initialize_Mathlib_Analysis_Asymptotics_Asymptotics(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_SchreierSpectral(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_TrigSum(uint8_t builtin, lean_object*);
lean_object* initialize_Formalization_FourierChain(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Formalization_FourierIsomorphism(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Complex_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Data_Complex_Exponential(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Analysis_SpecialFunctions_Trigonometric_Basic(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Analysis_SpecialFunctions_Trigonometric_Bounds(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Algebra_Group_AddChar(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_LinearAlgebra_Matrix_Spectrum(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Mathlib_Analysis_Asymptotics_Asymptotics(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_SchreierSpectral(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_TrigSum(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Formalization_FourierChain(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
