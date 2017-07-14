## trig.jl
# The benchmark groups below benchmark trig functions in Base. Numeri-
# cal evaluation of trig functions consists of two steps: argument re-
# duction, followed by evaluation of a polynomial on the reduced argu-
# ment. Below, "no reduction" means that the kernel functions are cal-
# led directly, "argument reduction (easy)" means that we are using
# the two coefficient Cody-Waite method, "argument reduction (hard)"
# means that we are using a more precise but more expensive Cody-Waite
# scheme, and "argument reduction (paynehanek)" means that we are us-
# ing the expensive Payne-Hanek scheme for large input values. "(hard)"
# values are either around integer mulitples of pi/2 or for the medium
# size arguments 9pi/4 <= |x| <= 2.0^20π/2. "(paynehanek)" vales are
# |x| >= 2.0^20π/2. The tags "sin_kernel" and "cos_kernel" refers to
# the actual polynomial being used. "z_kernel" evaluates a polynomial
# that approximates z∈{sin, cos} on the interval of x's such that
# |x| <= pi/4.

#######
# sin #
#######

g = addgroup!(SUITE, "sin")

# NaN or Inf
g["NaN", "Float64"]  = @benchmarkable sin($(NaN))
g["Inf", "Float64"]  = @benchmarkable sin($(Inf))
g["-Inf", "Float64"] = @benchmarkable sin($(-Inf))
# -π/4 <= x <= π/4
g["no reduction", "zero", "Float64"] = @benchmarkable sin($(0.0))
g["no reduction", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(pi/6))
g["no reduction", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-pi/6))
# -2π/4 <= x <= 2π/4
g["argument reduction (easy) |x| < 2π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable sin($(2*pi/4-0.1))
g["argument reduction (easy) |x| < 2π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable sin($(-2*pi/4+0.1))
g["argument reduction (hard) |x| < 2π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable sin($(2*pi/4))
g["argument reduction (hard) |x| < 2π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable sin($(-2*pi/4))
# -3π/4 <= x <= 3π/4
g["argument reduction (easy) |x| < 3π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable sin($(3*pi/4-0.1))
g["argument reduction (easy) |x| < 3π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable sin($(-3*pi/4+0.1))
# -4π/4 <= x <= 4π/4
g["argument reduction (easy) |x| < 4π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(pi-0.1))
g["argument reduction (easy) |x| < 4π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-pi+0.1))
g["argument reduction (hard) |x| < 4π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(Float64(pi)))
g["argument reduction (hard) |x| < 4π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(Float64(-pi)))
# -5π/4 <= x <= 5π/4
g["argument reduction (easy) |x| < 5π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(5*pi/4-0.1))
g["argument reduction (easy) |x| < 5π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-5*pi/4+0.1))
# -6π/4 <= x <= 6π/4
g["argument reduction (easy) |x| < 6π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable sin($(6*pi/4-0.1))
g["argument reduction (easy) |x| < 6π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable sin($(-6*pi/4+0.1))
g["argument reduction (hard) |x| < 6π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable sin($(6*pi/4))
g["argument reduction (hard) |x| < 6π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable sin($(-6*pi/4))
# -7π/4 <= x <= 7π/4
g["argument reduction (easy) |x| < 7π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(7*pi/4-0.1))
g["argument reduction (easy) |x| < 7π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-7*pi/4+0.1))
# -8π/4 <= x <= 8π/4
g["argument reduction (easy) |x| < 8π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(2*pi-0.1))
g["argument reduction (easy) |x| < 8π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-2*pi+0.1))
g["argument reduction (hard) |x| < 8π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(2*pi))
g["argument reduction (hard) |x| < 8π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-2*pi))
# -9π/4 <= x <= 9π/4
g["argument reduction (easy) |x| < 9π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(9*pi/4-0.1))
g["argument reduction (easy) |x| < 9π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-9*pi/4+0.1))
# -2.0^20π/2 <= x <= 2.0^20π/2
g["argument reduction (easy) |x| < 2.0^20π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(2.0^10*pi/4-0.1))
g["argument reduction (easy) |x| < 2.0^20π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-2.0^10*pi/4+0.1))
# |x| >= 2.0^20π/2
# idx < 0
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "positive argument", "Float64", "sin_kernel"] = @benchmarkable sin($(2.0^30*pi/4-0.1))
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "negative argument", "Float64", "sin_kernel"] = @benchmarkable sin($(-2.0^30*pi/4+0.1))
# idx > 0
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "positive argument", "Float64", "cos_kernel"] = @benchmarkable sin($(2.0^80*pi/4-1.2))
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "negative argument", "Float64", "cos_kernel"] = @benchmarkable sin($(-2.0^80*pi/4+1.2))

#######
# cos #
#######

g = addgroup!(SUITE, "cos")

# NaN or Inf
g["NaN", "Float64"]  = @benchmarkable cos($(NaN))
g["Inf", "Float64"]  = @benchmarkable cos($(Inf))
g["-Inf", "Float64"] = @benchmarkable cos($(-Inf))
# -π/4 <= x <= π/4
g["no reduction", "zero", "Float64"] = @benchmarkable cos($(0.0))
g["no reduction", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(pi/6))
g["no reduction", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-pi/6))
# -2π/4 <= x <= 2π/4
g["argument reduction (easy) |x| < 2π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable cos($(2*pi/4-0.1))
g["argument reduction (easy) |x| < 2π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable cos($(-2*pi/4+0.1))
g["argument reduction (hard) |x| < 2π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable cos($(2*pi/4))
g["argument reduction (hard) |x| < 2π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable cos($(-2*pi/4))
# -3π/4 <= x <= 3π/4
g["argument reduction (easy) |x| < 3π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable cos($(3*pi/4-0.1))
g["argument reduction (easy) |x| < 3π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable cos($(-3*pi/4+0.1))
# -4π/4 <= x <= 4π/4
g["argument reduction (easy) |x| < 4π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(pi-0.1))
g["argument reduction (easy) |x| < 4π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-pi+0.1))
g["argument reduction (hard) |x| < 4π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(Float64(pi)))
g["argument reduction (hard) |x| < 4π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(Float64(-pi)))
# -5π/4 <= x <= 5π/4
g["argument reduction (easy) |x| < 5π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(5*pi/4-0.1))
g["argument reduction (easy) |x| < 5π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-5*pi/4+0.1))
# -6π/4 <= x <= 6π/4
g["argument reduction (easy) |x| < 6π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable cos($(6*pi/4-0.1))
g["argument reduction (easy) |x| < 6π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable cos($(-6*pi/4+0.1))
g["argument reduction (hard) |x| < 6π/4", "positive argument", "Float64", "sin_kernel"] = @benchmarkable cos($(6*pi/4))
g["argument reduction (hard) |x| < 6π/4", "negative argument", "Float64", "sin_kernel"] = @benchmarkable cos($(-6*pi/4))
# -7π/4 <= x <= 7π/4
g["argument reduction (easy) |x| < 7π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(7*pi/4-0.1))
g["argument reduction (easy) |x| < 7π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-7*pi/4+0.1))
# -8π/4 <= x <= 8π/4
g["argument reduction (easy) |x| < 8π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(2*pi-0.1))
g["argument reduction (easy) |x| < 8π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-2*pi+0.1))
g["argument reduction (hard) |x| < 8π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(2*pi))
g["argument reduction (hard) |x| < 8π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-2*pi))
# -9π/4 <= x <= 9π/4
g["argument reduction (easy) |x| < 9π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(9*pi/4-0.1))
g["argument reduction (easy) |x| < 9π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-9*pi/4+0.1))
# -2.0^20π/2 <= x <= 2.0^20π/2
g["argument reduction (easy) |x| < 2.0^20π/4", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(2.0^10*pi/4-0.1))
g["argument reduction (easy) |x| < 2.0^20π/4", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-2.0^10*pi/4+0.1))
# |x| >= 2.0^20π/2
# idx < 0
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "positive argument", "Float64", "cos_kernel"] = @benchmarkable cos($(2.0^30*pi/4-0.1))
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "negative argument", "Float64", "cos_kernel"] = @benchmarkable cos($(-2.0^30*pi/4+0.1))
# idx > 0
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "positive argument", "Float64", "sin_kernel"] = @benchmarkable cos($(2.0^80*pi/4-1.2))
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "negative argument", "Float64", "sin_kernel"] = @benchmarkable cos($(-2.0^80*pi/4+1.2))

############
# rem_pio2 #
############

g = addgroup!(SUITE, "rem_pio2")
_rem = try
    method_exists(Base.Math.ieee754_rem_pio2, Tuple{Float64})
    Base.Math.ieee754_rem_pio2
catch
    Base.Math.rem_pio2_kernel
end

# -2π/4 <= x <= 2π/4
g["argument reduction (easy) |x| < 2π/4", "positive argument", "Float64"] = @benchmarkable _rem($(2*pi/4-0.1))
g["argument reduction (easy) |x| < 2π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-2*pi/4+0.1))
g["argument reduction (hard) |x| < 2π/4", "positive argument", "Float64"] = @benchmarkable _rem($(2*pi/4))
g["argument reduction (hard) |x| < 2π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-2*pi/4))
# -3π/4 <= x <= 3π/4
g["argument reduction (easy) |x| < 3π/4", "positive argument", "Float64"] = @benchmarkable _rem($(3*pi/4-0.1))
g["argument reduction (easy) |x| < 3π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-3*pi/4+0.1))
# -4π/4 <= x <= 4π/4
g["argument reduction (easy) |x| < 4π/4", "positive argument", "Float64"] = @benchmarkable _rem($(pi-0.1))
g["argument reduction (easy) |x| < 4π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-pi+0.1))
g["argument reduction (hard) |x| < 4π/4", "positive argument", "Float64"] = @benchmarkable _rem($(Float64(pi)))
g["argument reduction (hard) |x| < 4π/4", "negative argument", "Float64"] = @benchmarkable _rem($(Float64(-pi)))
# -5π/4 <= x <= 5π/4
g["argument reduction (easy) |x| < 5π/4", "positive argument", "Float64"] = @benchmarkable _rem($(5*pi/4-0.1))
g["argument reduction (easy) |x| < 5π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-5*pi/4+0.1))
# -6π/4 <= x <= 6π/4
g["argument reduction (easy) |x| < 6π/4", "positive argument", "Float64"] = @benchmarkable _rem($(6*pi/4-0.1))
g["argument reduction (easy) |x| < 6π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-6*pi/4+0.1))
g["argument reduction (hard) |x| < 6π/4", "positive argument", "Float64"] = @benchmarkable _rem($(6*pi/4))
g["argument reduction (hard) |x| < 6π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-6*pi/4))
# -7π/4 <= x <= 7π/4
g["argument reduction (easy) |x| < 7π/4", "positive argument", "Float64"] = @benchmarkable _rem($(7*pi/4-0.1))
g["argument reduction (easy) |x| < 7π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-7*pi/4+0.1))
# -8π/4 <= x <= 8π/4
g["argument reduction (easy) |x| < 8π/4", "positive argument", "Float64"] = @benchmarkable _rem($(2*pi-0.1))
g["argument reduction (easy) |x| < 8π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-2*pi+0.1))
g["argument reduction (hard) |x| < 8π/4", "positive argument", "Float64"] = @benchmarkable _rem($(2*pi))
g["argument reduction (hard) |x| < 8π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-2*pi))
# -9π/4 <= x <= 9π/4
g["argument reduction (easy) |x| < 9π/4", "positive argument", "Float64"] = @benchmarkable _rem($(9*pi/4-0.1))
g["argument reduction (easy) |x| < 9π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-9*pi/4+0.1))
# -2.0^20π/2 <= x <= 2.0^20π/2
g["argument reduction (easy) |x| < 2.0^20π/4", "positive argument", "Float64"] = @benchmarkable _rem($(2.0^10*pi/4-0.1))
g["argument reduction (easy) |x| < 2.0^20π/4", "negative argument", "Float64"] = @benchmarkable _rem($(-2.0^10*pi/4+0.1))
# |x| >= 2.0^20π/2
# idx < 0
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "positive argument", "Float64"] = @benchmarkable _rem($(2.0^30*pi/4-0.1))
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "negative argument", "Float64"] = @benchmarkable _rem($(-2.0^30*pi/4+0.1))
# idx > 0
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "positive argument", "Float64"] = @benchmarkable _rem($(2.0^80*pi/4-1.2))
g["argument reduction (paynehanek) |x| > 2.0^20*π/2", "negative argument", "Float64"] = @benchmarkable _rem($(-2.0^80*pi/4+1.2))
