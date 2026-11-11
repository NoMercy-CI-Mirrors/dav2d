/*
 * Copyright © 2018-2026, VideoLAN and dav2d authors
 * Copyright © 2018-2026, Two Orioles, LLC
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include <string.h>

#include "common/frame.h"

#include "src/internal.h"
#include "src/tables.h"

#define CDF1(x) (32768-(x))

#define CDF2(a,b) \
    CDF1(a), CDF1(b)
#define CDF3(a,b,c) \
    CDF1(a), CDF2(b,c)
#define CDF4(a,b,c,d) \
    CDF1(a), CDF3(b,c,d)
#define CDF5(a,b,c,d,e) \
    CDF1(a), CDF4(b,c,d,e)
#define CDF6(a,b,c,d,e,f) \
    CDF1(a), CDF5(b,c,d,e,f)
#define CDF7(a,b,c,d,e,f,g) \
    CDF1(a), CDF6(b,c,d,e,f,g)
#define CDF8(a,b,c,d,e,f,g,h) \
    CDF1(a), CDF7(b,c,d,e,f,g,h)
#define CDF9(a,b,c,d,e,f,g,h,i) \
    CDF1(a), CDF8(b,c,d,e,f,g,h,i)
#define CDF10(a,b,c,d,e,f,g,h,i,j) \
    CDF1(a), CDF9(b,c,d,e,f,g,h,i,j)
#define CDF11(a,b,c,d,e,f,g,h,i,j,k) \
    CDF1(a), CDF10(b,c,d,e,f,g,h,i,j,k)
#define CDF12(a,b,c,d,e,f,g,h,i,j,k,l) \
    CDF1(a), CDF11(b,c,d,e,f,g,h,i,j,k,l)
#define CDF13(a,b,c,d,e,f,g,h,i,j,k,l,m) \
    CDF1(a), CDF12(b,c,d,e,f,g,h,i,j,k,l,m)
#define CDF14(a,b,c,d,e,f,g,h,i,j,k,l,m,n) \
    CDF1(a), CDF13(b,c,d,e,f,g,h,i,j,k,l,m,n)
#define CDF15(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o) \
    CDF1(a), CDF14(b,c,d,e,f,g,h,i,j,k,l,m,n,o)

#define PARA(a, b, c) (((a + 0) << 14) | ((b + 1) << 11) | ((c + 2) << 8))

typedef struct CdfDefaultContext {
    CdfModeContext m;
    CdfMvContext mv;
} CdfDefaultContext;

static const CdfDefaultContext default_cdf = {
    .m  = {
        .rst_switchable = {
            { CDF1(25542), PARA(0, 0, 0) },
            { CDF1(25550), PARA(1, 0, 0) },
        }, .rst_ns_wiener = {
            CDF1(9051), PARA(1, 1, 0)
        }, .rst_pc_wiener = {
            CDF1(12799), PARA(1, 2, 2)
        }, .wiener_ns_len = {
            { CDF1(4898), PARA(0, 1, 1) },
            { CDF1(6088), PARA(1, 2, 1) },
        }, .wiener_ns_sym = {
            CDF1(29286), PARA(0, 3, 2)
        }, .wiener_ns_cf = {
            CDF3(16557, 24352, 29677), PARA(2, 1, 1)
        }, .part_split = {
            {
                { CDF1(28084), PARA(2, 2, 3) },
                { CDF1(23755), PARA(3, 3, 3) },
                { CDF1(23634), PARA(3, 3, 3) },
                { CDF1(19368), PARA(2, 2, 3) },
                { CDF1(24961), PARA(2, 2, 2) },
                { CDF1(14941), PARA(2, 2, 1) },
                { CDF1(16154), PARA(2, 2, 1) },
                { CDF1( 5905), PARA(2, 2, 2) },
                { CDF1(21934), PARA(2, 2, 2) },
                { CDF1(10440), PARA(1, 2, 1) },
                { CDF1(11984), PARA(1, 1, 1) },
                { CDF1( 3474), PARA(2, 2, 2) },
                { CDF1(20492), PARA(2, 3, 1) },
                { CDF1( 6963), PARA(2, 1, 1) },
                { CDF1( 8099), PARA(1, 2, 1) },
                { CDF1( 1529), PARA(2, 2, 2) },
                { CDF1(24117), PARA(3, 3, 0) },
                { CDF1( 7871), PARA(2, 0, 2) },
                { CDF1(23604), PARA(2, 2, 0) },
                { CDF1( 8429), PARA(1, 1, 2) },
                { CDF1(27356), PARA(2, 2, 0) },
                { CDF1(22441), PARA(2, 1, 0) },
                { CDF1( 8897), PARA(1, 1, 1) },
                { CDF1( 6811), PARA(0, 0, 1) },
                { CDF1(17592), PARA(2, 3, 1) },
                { CDF1( 5648), PARA(1, 1, 0) },
                { CDF1( 5339), PARA(1, 2, 1) },
                { CDF1( 1082), PARA(1, 2, 1) },
                { CDF1(26143), PARA(3, 2, 0) },
                { CDF1(11379), PARA(3, 0, 2) },
                { CDF1(20142), PARA(3, 3, 3) },
                { CDF1( 7401), PARA(2, 1, 3) },
                { CDF1(26235), PARA(3, 1, 0) },
                { CDF1(23674), PARA(3, 2, 3) },
                { CDF1(12441), PARA(3, 2, 0) },
                { CDF1(10482), PARA(3, 2, 2) },
                { CDF1(20663), PARA(2, 2, 2) },
                { CDF1( 4192), PARA(1, 2, 0) },
                { CDF1( 5274), PARA(1, 1, 3) },
                { CDF1(  713), PARA(2, 2, 1) },
                { CDF1(28255), PARA(3, 2, 2) },
                { CDF1(27370), PARA(3, 2, 2) },
                { CDF1(23527), PARA(2, 2, 2) },
                { CDF1(20990), PARA(2, 2, 1) },
                { CDF1(26727), PARA(2, 2, 2) },
                { CDF1(21187), PARA(2, 2, 2) },
                { CDF1(25324), PARA(2, 2, 2) },
                { CDF1(17838), PARA(2, 2, 2) },
                { CDF1(26136), PARA(2, 2, 2) },
                { CDF1(16591), PARA(2, 1, 1) },
                { CDF1(19838), PARA(2, 2, 1) },
                { CDF1(10605), PARA(1, 1, 1) },
                { CDF1(22914), PARA(2, 2, 1) },
                { CDF1(12609), PARA(1, 1, 1) },
                { CDF1(11341), PARA(2, 2, 2) },
                { CDF1( 4556), PARA(2, 2, 2) },
                { CDF1(24218), PARA(2, 2, 1) },
                { CDF1(13059), PARA(2, 1, 0) },
                { CDF1(15378), PARA(1, 1, 0) },
                { CDF1( 5858), PARA(1, 1, 0) },
                { CDF1(21644), PARA(1, 1, 0) },
                { CDF1( 7767), PARA(1, 1, 1) },
                { CDF1( 8309), PARA(2, 1, 1) },
                { CDF1( 1687), PARA(2, 2, 2) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(25554), PARA(2, 2, 2) },
                { CDF1(18892), PARA(2, 2, 2) },
                { CDF1(18530), PARA(2, 2, 2) },
                { CDF1(10806), PARA(2, 1, 1) },
                { CDF1(22504), PARA(2, 2, 1) },
                { CDF1(12140), PARA(1, 1, 1) },
                { CDF1(11966), PARA(1, 1, 1) },
                { CDF1( 4984), PARA(1, 1, 2) },
                { CDF1(24460), PARA(1, 1, 1) },
                { CDF1( 8698), PARA(1, 1, 1) },
                { CDF1( 9655), PARA(1, 1, 1) },
                { CDF1( 2563), PARA(1, 1, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(26227), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(17669), PARA(2, 2, 1) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(26179), PARA(2, 2, 1) },
                { CDF1(17889), PARA(2, 2, 1) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(23500), PARA(2, 2, 1) },
                { CDF1(13115), PARA(1, 1, 1) },
                { CDF1(15253), PARA(1, 1, 1) },
                { CDF1( 6458), PARA(0, 1, 2) },
                { CDF1(22566), PARA(1, 1, 1) },
                { CDF1(11497), PARA(1, 1, 0) },
                { CDF1(10045), PARA(1, 1, 1) },
                { CDF1( 3750), PARA(1, 2, 1) },
            },
        }, .part_square = {
            { CDF1(18000), PARA(2, 1, 0) },
            { CDF1(10521), PARA(1, 0, 0) },
            { CDF1(11395), PARA(0, 0, 0) },
            { CDF1( 4419), PARA(1, 1, 0) },
            { CDF1(12996), PARA(3, 0, 2) },
            { CDF1( 8185), PARA(0, 1, 2) },
            { CDF1(10979), PARA(1, 0, 1) },
            { CDF1( 5010), PARA(1, 1, 0) },
        }, .part_dir = {
            {
                { CDF1(14644), PARA(2, 2, 2) },
                { CDF1(10173), PARA(3, 2, 2) },
                { CDF1(18529), PARA(2, 2, 2) },
                { CDF1(16071), PARA(3, 3, 2) },
                { CDF1(20263), PARA(2, 2, 1) },
                { CDF1(12813), PARA(2, 2, 1) },
                { CDF1(26612), PARA(2, 2, 2) },
                { CDF1(23277), PARA(2, 2, 1) },
                { CDF1(10594), PARA(3, 2, 1) },
                { CDF1( 7000), PARA(3, 2, 2) },
                { CDF1(20002), PARA(2, 2, 1) },
                { CDF1(12889), PARA(2, 2, 0) },
                { CDF1(13854), PARA(3, 2, 1) },
                { CDF1(10750), PARA(2, 2, 1) },
                { CDF1(18380), PARA(2, 2, 1) },
                { CDF1(17505), PARA(2, 1, 1) },
                { CDF1(14430), PARA(2, 1, 0) },
                { CDF1(11554), PARA(2, 2, 0) },
                { CDF1(20078), PARA(2, 2, 1) },
                { CDF1(19097), PARA(3, 2, 1) },
                { CDF1(15278), PARA(2, 2, 0) },
                { CDF1(10137), PARA(2, 2, 1) },
                { CDF1(21921), PARA(2, 1, 0) },
                { CDF1(14621), PARA(2, 1, 1) },
                { CDF1(19330), PARA(2, 2, 0) },
                { CDF1(15921), PARA(2, 2, 1) },
                { CDF1(26218), PARA(2, 2, 1) },
                { CDF1(24318), PARA(2, 2, 1) },
                { CDF1(16066), PARA(3, 2, 3) },
                { CDF1( 9225), PARA(2, 2, 0) },
                { CDF1(22849), PARA(1, 1, 1) },
                { CDF1(14817), PARA(2, 0, 1) },
                { CDF1(18543), PARA(3, 2, 2) },
                { CDF1(13210), PARA(2, 0, 2) },
                { CDF1(24367), PARA(1, 1, 0) },
                { CDF1(18417), PARA(1, 2, 2) },
                { CDF1(24701), PARA(2, 1, 1) },
                { CDF1(18911), PARA(2, 1, 0) },
                { CDF1(29590), PARA(2, 2, 1) },
                { CDF1(27778), PARA(2, 1, 0) },
                { CDF1( 3400), PARA(2, 2, 1) },
                { CDF1(  935), PARA(3, 3, 2) },
                { CDF1(10365), PARA(1, 1, 0) },
                { CDF1( 1723), PARA(2, 2, 1) },
            }, {
                { CDF1(15654), PARA(3, 2, 1) },
                { CDF1(13500), PARA(3, 2, 2) },
                { CDF1(19177), PARA(3, 3, 1) },
                { CDF1(14739), PARA(3, 3, 2) },
                { CDF1(18769), PARA(3, 2, 2) },
                { CDF1(13500), PARA(2, 2, 1) },
                { CDF1(23583), PARA(3, 2, 2) },
                { CDF1(20927), PARA(3, 2, 2) },
                { CDF1(15045), PARA(2, 2, 1) },
                { CDF1(10528), PARA(2, 2, 2) },
                { CDF1(22474), PARA(2, 1, 1) },
                { CDF1(14250), PARA(2, 2, 2) },
                { CDF1(16561), PARA(3, 2, 2) },
                { CDF1(11427), PARA(3, 2, 1) },
                { CDF1(21874), PARA(2, 1, 1) },
                { CDF1(16344), PARA(3, 3, 2) },
                { CDF1(21566), PARA(1, 1, 1) },
                { CDF1(13357), PARA(2, 2, 0) },
                { CDF1(27355), PARA(2, 2, 1) },
                { CDF1(24117), PARA(2, 1, 1) },
                { CDF1(10901), PARA(3, 2, 0) },
                { CDF1( 5780), PARA(2, 2, 2) },
                { CDF1(19056), PARA(1, 0, 0) },
                { CDF1( 9141), PARA(2, 2, 1) },
                { CDF1(20436), PARA(2, 1, 0) },
                { CDF1(15693), PARA(1, 1, 0) },
                { CDF1(26536), PARA(2, 1, 1) },
                { CDF1(23667), PARA(1, 1, 1) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(19241), PARA(2, 1, 0) },
                { CDF1(13038), PARA(1, 1, 0) },
                { CDF1(28903), PARA(1, 1, 0) },
                { CDF1(24802), PARA(1, 1, 0) },
                { CDF1( 9097), PARA(1, 1, 0) },
                { CDF1( 2749), PARA(2, 1, 1) },
                { CDF1(15201), PARA(1, 2, 0) },
                { CDF1( 4449), PARA(2, 1, 1) },
            }
        }, .part_ext = {
            {
                { CDF1(31091), PARA(2, 2, 3) },
                { CDF1(29638), PARA(2, 2, 2) },
                { CDF1(28924), PARA(2, 2, 2) },
                { CDF1(28653), PARA(2, 2, 2) },
                { CDF1(30349), PARA(3, 3, 3) },
                { CDF1(28265), PARA(3, 2, 2) },
                { CDF1(27287), PARA(2, 2, 2) },
                { CDF1(27721), PARA(2, 2, 2) },
                { CDF1(29960), PARA(3, 3, 3) },
                { CDF1(28345), PARA(3, 3, 2) },
                { CDF1(27302), PARA(3, 3, 2) },
                { CDF1(27252), PARA(3, 2, 2) },
                { CDF1(30342), PARA(2, 2, 1) },
                { CDF1(27563), PARA(2, 1, 1) },
                { CDF1(26168), PARA(2, 1, 1) },
                { CDF1(23089), PARA(1, 1, 0) },
                { CDF1(30643), PARA(2, 2, 2) },
                { CDF1(28683), PARA(2, 2, 1) },
                { CDF1(28009), PARA(2, 2, 2) },
                { CDF1(26186), PARA(2, 2, 2) },
                { CDF1(29222), PARA(2, 2, 1) },
                { CDF1(25740), PARA(2, 2, 2) },
                { CDF1(24079), PARA(2, 1, 1) },
                { CDF1(19806), PARA(3, 2, 1) },
                { CDF1(29409), PARA(3, 3, 2) },
                { CDF1(26825), PARA(3, 3, 3) },
                { CDF1(25919), PARA(3, 3, 3) },
                { CDF1(24417), PARA(3, 3, 3) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(26866), PARA(1, 1, 2) },
                { CDF1(24499), PARA(1, 2, 2) },
                { CDF1(24732), PARA(1, 1, 1) },
                { CDF1(23387), PARA(1, 2, 2) },
                { CDF1(27477), PARA(1, 1, 2) },
                { CDF1(25837), PARA(1, 1, 1) },
                { CDF1(24621), PARA(1, 1, 1) },
                { CDF1(23604), PARA(2, 1, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(24384), PARA(1, 2, 1) },
                { CDF1(22113), PARA(1, 1, 0) },
                { CDF1(21798), PARA(2, 2, 0) },
                { CDF1(20067), PARA(2, 1, 1) },
                { CDF1(26220), PARA(1, 1, 1) },
                { CDF1(22997), PARA(1, 1, 2) },
                { CDF1(22249), PARA(1, 1, 1) },
                { CDF1(20091), PARA(2, 2, 2) },
            }
        }, .part_4way = {
            {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(25789), PARA(1, 1, 1) },
                { CDF1(25290), PARA(1, 1, 0) },
                { CDF1(24270), PARA(1, 1, 1) },
                { CDF1(22994), PARA(1, 1, 1) },
                { CDF1(25801), PARA(2, 2, 1) },
                { CDF1(25260), PARA(2, 1, 0) },
                { CDF1(24041), PARA(2, 2, 1) },
                { CDF1(24281), PARA(2, 2, 1) },
                { CDF1(23038), PARA(2, 1, 1) },
                { CDF1(19972), PARA(1, 3, 2) },
                { CDF1(19723), PARA(2, 1, 3) },
                { CDF1(17939), PARA(2, 2, 2) },
                { CDF1(15574), PARA(2, 1, 1) },
                { CDF1(13761), PARA(3, 2, 1) },
                { CDF1(12917), PARA(3, 3, 1) },
                { CDF1(11328), PARA(3, 2, 2) },
                { CDF1(17295), PARA(1, 1, 0) },
                { CDF1(14463), PARA(1, 0, 3) },
                { CDF1(14724), PARA(2, 1, 1) },
                { CDF1(11653), PARA(2, 2, 1) },
                { CDF1(13202), PARA(1, 1, 0) },
                { CDF1(10929), PARA(2, 1, 0) },
                { CDF1(10348), PARA(2, 1, 0) },
                { CDF1( 8276), PARA(2, 2, 1) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(24728), PARA(1, 1, 1) },
                { CDF1(22673), PARA(1, 1, 1) },
                { CDF1(21033), PARA(2, 1, 1) },
                { CDF1(20321), PARA(2, 2, 1) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(24631), PARA(0, 3, 0) },
                { CDF1(21363), PARA(2, 3, 2) },
                { CDF1(20201), PARA(2, 3, 2) },
                { CDF1(17529), PARA(3, 1, 0) },
                { CDF1(21042), PARA(2, 2, 3) },
                { CDF1(18640), PARA(3, 1, 2) },
                { CDF1(18183), PARA(3, 3, 1) },
                { CDF1(15590), PARA(3, 2, 1) },
            }
        }, .region_type = {
            { CDF1( 2635), PARA(1, 2, 2) },
            { CDF1(  883), PARA(1, 2, 2) },
            { CDF1(  503), PARA(0, 2, 2) },
            { CDF1(  279), PARA(0, 1, 2) },
        }, .skip_mode = {
            { CDF1(30964), PARA(3, 3, 3) },
            { CDF1(21769), PARA(2, 2, 2) },
            { CDF1(12484), PARA(2, 3, 2) },
        }, .skip_mode_drl_idx = {
            { CDF1(21634), PARA(2, 2, 2) },
            { CDF1(17376), PARA(2, 2, 2) },
            { CDF1(18432), PARA(3, 2, 2) },
        }, .intra = {
            { CDF1( 1522), PARA(2, 2, 1) },
            { CDF1(14381), PARA(2, 2, 2) },
            { CDF1(10455), PARA(1, 2, 2) },
            { CDF1(27796), PARA(2, 2, 2) },
        }, .intrabc = {
            { CDF1(32085), PARA(2, 1, 2) },
            { CDF1(15172), PARA(1, 1, 2) },
            { CDF1( 4503), PARA(2, 2, 2) },
        }, .gdf = {
            CDF1(14593), PARA(1, 1, 0)
        }, .cdef_idx0 = {
            { CDF1(29034), PARA(1, 1, 0) },
            { CDF1(16472), PARA(1, 1, 0) },
            { CDF1( 5751), PARA(1, 1, 0) },
            { CDF1( 3115), PARA(1, 1, 1) },
        }, .cdef_idx = {
            { CDF1(17708), PARA(1, 1, 0) },
            { CDF2(13413, 24899), PARA(1, 1, 0) },
            { CDF3(10588, 19866, 26664), PARA(1, 0, 0) },
            { CDF4(10131, 17874, 23876, 28766), PARA(1, 0, 0) },
            { CDF5( 8363, 15451, 20811, 25453, 29393), PARA(1, 1, 0) },
            { CDF6( 7372, 13867, 18969, 23278, 26977, 30156), PARA(1, 1, 0) },
        }, .ccso = {
            {
                { CDF1(18469), PARA(0, 0, 0) },
                { CDF1( 4949), PARA(1, 0, 0) },
            }, {
                { CDF1(23470), PARA(1, 0, 0) },
                { CDF1( 6666), PARA(1, 0, 0) },
            }, {
                { CDF1(22914), PARA(1, 0, 0) },
                { CDF1( 6993), PARA(1, 0, 0) },
            }
        }, .skip_txfm = {
            { CDF1(25865), PARA(1, 2, 2) },
            { CDF1(14316), PARA(2, 2, 2) },
            { CDF1( 4598), PARA(2, 2, 2) },
            { CDF1(25612), PARA(2, 1, 1) },
            { CDF1(12366), PARA(2, 2, 1) },
            { CDF1( 3320), PARA(3, 3, 2) },
        }, .dpcm = {
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
        }, .dpcm_dir = {
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
        }, .intra_y_set = {
            CDF3(28863, 31022, 31724), PARA(3, 3, 3)
        }, .intra_y_idx0 = {
            { CDF7(15175, 20075, 21728, 24098, 26405, 27655, 28860), PARA(2, 1, 2) },
            { CDF7(10114, 14957, 16815, 19127, 20147, 25583, 27169), PARA(2, 2, 2) },
            { CDF7( 5636,  9004, 10456, 12122, 12744, 20325, 25607), PARA(2, 2, 2) },
        }, .intra_y_idx1 = {
            { CDF5(12743, 18172, 20194, 23648, 26419), PARA(2, 1, 1) },
            { CDF5( 8976, 16084, 20827, 24595, 28496), PARA(3, 2, 2) },
            { CDF5( 8784, 14556, 19710, 24903, 28724), PARA(3, 2, 2) },
        }, .fsc = {
            {
                { CDF1(30503), PARA(2, 2, 3) },
                { CDF1(31244), PARA(2, 2, 3) },
                { CDF1(32254), PARA(3, 2, 3) },
                { CDF1(32324), PARA(3, 3, 3) },
                { CDF1(32582), PARA(3, 3, 3) },
                { CDF1(32691), PARA(3, 3, 3) },
            }, {
                { CDF1(27437), PARA(2, 2, 2) },
                { CDF1(27242), PARA(3, 3, 2) },
                { CDF1(28040), PARA(3, 2, 1) },
                { CDF1(27589), PARA(3, 2, 1) },
                { CDF1(27234), PARA(2, 1, 0) },
                { CDF1(23583), PARA(0, 0, 0) },
            }, {
                { CDF1(26068), PARA(3, 2, 2) },
                { CDF1(22635), PARA(3, 2, 2) },
                { CDF1(22069), PARA(2, 1, 1) },
                { CDF1(19218), PARA(1, 1, 0) },
                { CDF1(13701), PARA(1, 1, 1) },
                { CDF1( 4636), PARA(1, 0, 3) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(32016), PARA(2, 3, 2) },
                { CDF1(32403), PARA(3, 3, 3) },
                { CDF1(32583), PARA(2, 3, 2) },
                { CDF1(32683), PARA(3, 2, 1) },
            },
        }, .mrl_index = {
            { CDF3(29573, 31193, 32023), PARA(3, 2, 3) },
            { CDF3(21812, 27066, 30279), PARA(3, 2, 2) },
            { CDF3(16076, 23806, 28762), PARA(2, 2, 1) },
        }, .multi_mrl = {
            { CDF1(19678), PARA(2, 1, 1) },
            { CDF1(12287), PARA(2, 1, 1) },
            { CDF1( 9574), PARA(2, 1, 1) },
        }, .pal_y = {
            CDF1(30045), PARA(0, 0, 0)
        }, .pal_sz = {
            CDF6( 8779, 15095, 20777, 24903, 27923, 30403), PARA(1, 1, 0)
        }, .dip = {
            { CDF1(11914), PARA(1, 1, 1) },
            { CDF1( 5128), PARA(1, 1, 1) },
            { CDF1( 3555), PARA(1, 1, 1) },
        }, .dip_mode = {
            CDF5( 5753, 15408, 19070, 22631, 27578), PARA(2, 2, 2)
        }, .cfl = {
            { CDF1(20441), PARA(1, 1, 2) },
            { CDF1(11610), PARA(2, 1, 1) },
            { CDF1( 4643), PARA(2, 2, 2) },
        }, .intra_uv_mode = {
            { CDF7( 9363, 20957, 22865, 24753, 26411, 27983, 30428), PARA(1, 1, 1) },
            { CDF7(21282, 23610, 28208, 29311, 30348, 31158, 31491), PARA(1, 1, 2) },
        }, .mhccp = {
            CDF1(15499), PARA(1, 1, 2)
        }, .mhccp_filter_dir = {
            { CDF2(10923, 21845), PARA(2, 2, 2) },
            { CDF2( 8795, 15105), PARA(2, 1, 1) },
            { CDF2(10433, 15974), PARA(1, 1, 0) },
            { CDF2(17085, 21689), PARA(1, 1, 0) },
        }, .cfl_type = {
            CDF1(12507), PARA(1, 1, 2)
        }, .cfl_sign = {
            CDF7( 2421,  4332, 11256, 12766, 21386, 28725, 32087), PARA(0, 0, 0)
        }, .cfl_alpha = {
            { CDF7(21679, 25305, 30646, 31512, 32537, 32646, 32696), PARA(0, 0, 0) },
            { CDF7( 8262, 16302, 24082, 29422, 31398, 32286, 32525), PARA(0, 0, 0) },
            { CDF7(17235, 26166, 30378, 31305, 32373, 32549, 32668), PARA(0, 0, 0) },
            { CDF7(17618, 25732, 27865, 30338, 31125, 31522, 32238), PARA(0, 0, 0) },
            { CDF7(17542, 23066, 27907, 28728, 30702, 31165, 31435), PARA(0, 0, 0) },
            { CDF7(17675, 24802, 30468, 30783, 31841, 32264, 32422), PARA(0, 0, 0) },
        }, .pal_idx_identity = {
            { CDF2(22515, 25751), PARA(1, 2, 2) },
            { CDF2( 4014,  5233), PARA(1, 1, 1) },
            { CDF2( 3548,  4163), PARA(1, 1, 3) },
            { CDF2(12999, 32756), PARA(0, 1, 1) },
        }, .pal_idx = {
            {
                { CDF1(28140), PARA(3, 3, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1( 8582), PARA(2, 1, 1) },
                { CDF1(27413), PARA(1, 1, 0) },
                { CDF1(30429), PARA(3, 3, 3) },
            }, {
                { CDF2(25350, 29026), PARA(3, 3, 2) },
                { CDF2(11363, 25273), PARA(2, 1, 0) },
                { CDF2( 6841, 28579), PARA(2, 2, 1) },
                { CDF2(21350, 26012), PARA(2, 1, 1) },
                { CDF2(30573, 31646), PARA(3, 3, 3) },
            }, {
                { CDF3(23706, 26962, 29060), PARA(2, 2, 2) },
                { CDF3( 9976, 22516, 27382), PARA(2, 2, 1) },
                { CDF3( 6691, 25460, 29234), PARA(2, 1, 1) },
                { CDF3(18909, 23925, 28403), PARA(1, 1, 1) },
                { CDF3(30308, 31076, 31818), PARA(3, 3, 3) },
            }, {
                { CDF4(24116, 26957, 28486, 29941), PARA(2, 2, 2) },
                { CDF4( 9568, 20472, 24294, 28942), PARA(3, 1, 1) },
                { CDF4( 5706, 25243, 28040, 30406), PARA(3, 2, 1) },
                { CDF4(20105, 22982, 27024, 28911), PARA(1, 1, 1) },
                { CDF4(30897, 31342, 31766, 32199), PARA(3, 3, 3) },
            }, {
                { CDF5(20824, 24227, 25926, 27459, 29266), PARA(3, 2, 2) },
                { CDF5( 8141, 18989, 21599, 26182, 28576), PARA(3, 2, 2) },
                { CDF5( 5252, 24340, 26450, 28438, 30625), PARA(3, 2, 2) },
                { CDF5(19519, 22695, 25587, 26972, 28423), PARA(2, 1, 1) },
                { CDF5(30383, 30890, 31247, 31653, 32150), PARA(3, 2, 3) },
            }, {
                { CDF6(21628, 24512, 25873, 27054, 28131, 29539), PARA(3, 1, 2) },
                { CDF6( 8028, 18264, 20613, 25424, 27112, 28906), PARA(3, 3, 2) },
                { CDF6( 6489, 22242, 24461, 26394, 28350, 30510), PARA(3, 2, 2) },
                { CDF6(22048, 24429, 26990, 27944, 28417, 29574), PARA(3, 2, 1) },
                { CDF6(30801, 31205, 31472, 31728, 32005, 32305), PARA(3, 3, 3) },
            }, {
                { CDF7(22471, 25083, 25984, 26893, 27654, 28750, 29903), PARA(3, 3, 3) },
                { CDF7( 7542, 17057, 19151, 23550, 25459, 27066, 28804), PARA(3, 3, 2) },
                { CDF7( 7582, 20437, 22728, 24622, 26515, 28579, 30632), PARA(3, 3, 2) },
                { CDF7(22102, 24144, 26916, 28151, 28846, 29212, 30153), PARA(2, 2, 2) },
                { CDF7(30524, 30887, 31156, 31393, 31626, 31911, 32281), PARA(3, 3, 3) },
            }
        }, .intrabc_mode = {
            CDF1(29993), PARA(2, 1, 1)
        }, .intrabc_precision = {
            CDF1(19778), PARA(1, 1, 1)
        }, .morph_pred = {
            { CDF1(31715), PARA(0, 1, 2) },
            { CDF1(19667), PARA(2, 2, 1) },
            { CDF1(10555), PARA(3, 3, 1) },
        }, .tip = {
            { CDF1(30898), PARA(3, 3, 3) },
            { CDF1(19665), PARA(2, 2, 2) },
            { CDF1( 9477), PARA(2, 3, 2) },
        }, .comp = {
            { CDF1(26924), PARA(2, 3, 2) },
            { CDF1(25000), PARA(2, 2, 1) },
            { CDF1(17949), PARA(2, 2, 1) },
            { CDF1(13581), PARA(2, 1, 1) },
            { CDF1( 7034), PARA(2, 2, 2) },
        }, .single_ref = {
            {
                { CDF1(26469), PARA(2, 2, 2) },
                { CDF1(28870), PARA(1, 1, 2) },
                { CDF1(29662), PARA(2, 2, 1) },
                { CDF1(29867), PARA(2, 1, 1) },
                { CDF1(29772), PARA(2, 1, 1) },
                { CDF1(29776), PARA(1, 2, 1) },
            }, {
                { CDF1(13631), PARA(2, 1, 1) },
                { CDF1(18185), PARA(1, 0, 0) },
                { CDF1(19992), PARA(1, 1, 0) },
                { CDF1(18462), PARA(0, 0, 0) },
                { CDF1(17451), PARA(1, 0, 0) },
                { CDF1(11578), PARA(0, 0, 0) },
            }, {
                { CDF1( 2599), PARA(2, 2, 2) },
                { CDF1( 5203), PARA(1, 1, 1) },
                { CDF1( 5185), PARA(1, 1, 1) },
                { CDF1( 3671), PARA(1, 1, 1) },
                { CDF1( 3954), PARA(2, 1, 1) },
                { CDF1( 1633), PARA(2, 1, 2) },
            },
        }, .comp0_ref = {
            {
                { CDF1( 9272), PARA(1, 1, 0) },
                { CDF1(17175), PARA(0, 0, 0) },
            }, {
                { CDF1( 1385), PARA(2, 2, 2) },
                { CDF1( 4439), PARA(1, 1, 1) },
            }, {
                { CDF1(  521), PARA(2, 2, 2) },
                { CDF1( 1854), PARA(1, 2, 2) },
            }
        }, .comp1_ref = {
            {
                {
                    { CDF1(30729), PARA(3, 2, 2) },
                    { CDF1(29403), PARA(2, 1, 2) },
                    { CDF1(29037), PARA(2, 1, 1) },
                    { CDF1(29355), PARA(1, 1, 1) },
                    { CDF1(28573), PARA(2, 1, 2) },
                    { CDF1(27396), PARA(2, 1, 0) },
                }, {
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(19315), PARA(1, 1, 1) },
                    { CDF1(27821), PARA(2, 1, 1) },
                    { CDF1(27892), PARA(1, 1, 1) },
                    { CDF1(28695), PARA(1, 1, 2) },
                    { CDF1(29637), PARA(0, 2, 1) },
                },
            }, {
                {
                    { CDF1(30432), PARA(2, 2, 2) },
                    { CDF1(20290), PARA(1, 1, 1) },
                    { CDF1(19855), PARA(1, 0, 0) },
                    { CDF1(18567), PARA(0, 0, 0) },
                    { CDF1(18331), PARA(1, 0, 0) },
                    { CDF1(14241), PARA(0, 0, 0) },
                }, {
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1( 5725), PARA(1, 1, 1) },
                    { CDF1(13420), PARA(1, 1, 1) },
                    { CDF1(12780), PARA(1, 1, 0) },
                    { CDF1(10781), PARA(0, 0, 0) },
                    { CDF1( 6424), PARA(0, 0, 0) },
                },
            }, {
                  {
                    { CDF1(11634), PARA(1, 1, 1) },
                    { CDF1(10093), PARA(1, 1, 1) },
                    { CDF1( 6065), PARA(1, 1, 1) },
                    { CDF1( 5408), PARA(1, 1, 1) },
                    { CDF1( 6411), PARA(1, 1, 1) },
                    { CDF1( 4075), PARA(1, 1, 2) },
                }, {
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(  898), PARA(2, 3, 2) },
                    { CDF1( 3127), PARA(2, 2, 1) },
                    { CDF1( 1775), PARA(2, 1, 2) },
                    { CDF1( 1217), PARA(2, 1, 1) },
                    { CDF1(  591), PARA(2, 1, 2) },
                },
            },
        }, .tip_mode = {
            CDF1(22129), PARA(1, 1, 1)
        }, .warp = {
            { CDF1(25999), PARA(2, 2, 1) },
            { CDF1(14478), PARA(2, 1, 0) },
            { CDF1(10868), PARA(2, 1, 1) },
            { CDF1( 5256), PARA(1, 1, 1) },
            { CDF1( 2722), PARA(1, 1, 1) },
        }, .warp_newmv = {
            CDF1(15095), PARA(2, 2, 1)
        }, .inter_mode = {
            { CDF2(10043, 11100), PARA(2, 1, 1) },
            { CDF2(21561, 21758), PARA(2, 2, 1) },
            { CDF2(25411, 25714), PARA(2, 2, 2) },
            { CDF2(14117, 14341), PARA(2, 2, 2) },
            { CDF2(18288, 18577), PARA(2, 2, 2) },
        }, .amvd = {
            {
                { CDF1( 5980), PARA(2, 3, 2) },
                { CDF1( 6091), PARA(2, 3, 2) },
                { CDF1( 6237), PARA(3, 3, 3) },
            }, {
                { CDF1(  861), PARA(1, 1, 2) },
                { CDF1(  847), PARA(0, 2, 2) },
                { CDF1( 1198), PARA(0, 3, 1) },
            }, {
                { CDF1(  456), PARA(0, 2, 3) },
                { CDF1(  431), PARA(0, 3, 3) },
                { CDF1(  849), PARA(0, 3, 3) },
            }, {
                { CDF1(  409), PARA(0, 3, 3) },
                { CDF1(  385), PARA(0, 3, 3) },
                { CDF1(  581), PARA(0, 3, 3) },
            }, {
                { CDF1(16246), PARA(2, 2, 2) },
                { CDF1( 9696), PARA(2, 2, 2) },
                { CDF1( 8791), PARA(2, 2, 2) },
            }, {
                { CDF1(13199), PARA(2, 2, 2) },
                { CDF1(10624), PARA(2, 2, 2) },
                { CDF1( 8586), PARA(2, 2, 1) },
            }, {
                { CDF1( 5112), PARA(2, 2, 1) },
                { CDF1( 3920), PARA(2, 2, 3) },
                { CDF1( 3668), PARA(2, 2, 3) },
            }, {
                { CDF1(12017), PARA(3, 2, 1) },
                { CDF1(10177), PARA(3, 2, 2) },
                { CDF1( 9184), PARA(3, 2, 2) },
            }, {
                { CDF1(12111), PARA(2, 1, 1) },
                { CDF1( 8056), PARA(2, 1, 2) },
                { CDF1( 6641), PARA(1, 2, 0) },
            }
        }, .bawp = {
            { CDF1(26456), PARA(1, 1, 1) },
            { CDF1( 5121), PARA(1, 1, 1) },
        }, .bawp_explicit = {
            { CDF1(26966), PARA(1, 1, 1) },
            { CDF1(15275), PARA(2, 1, 1) },
            { CDF1(14613), PARA(1, 1, 1) },
        }, .bawp_explicit_scale = {
            CDF1(21998), PARA(1, 1, 0)
        }, .warp_extend = {
            { CDF1(20359), PARA(2, 2, 2) },
            { CDF1(20310), PARA(3, 2, 2) },
            { CDF1(21759), PARA(3, 2, 2) },
        }, .warp_causal = {
            { CDF1(14877), PARA(2, 2, 1) },
            { CDF1(12801), PARA(2, 2, 2) },
            { CDF1( 6885), PARA(2, 1, 1) },
            { CDF1( 2987), PARA(1, 1, 2) },
        }, .interintra = {
            { CDF1(20569), PARA(2, 2, 1) },
            { CDF1(17106), PARA(2, 2, 1) },
            { CDF1(20948), PARA(2, 2, 1) },
            { CDF1(25796), PARA(1, 1, 0) },
        }, .interintra_mode = {
            { CDF3( 1819, 16131, 26802), PARA(1, 1, 0) },
            { CDF3( 1442, 15840, 28441), PARA(2, 2, 1) },
            { CDF3( 1995, 15814, 28221), PARA(2, 1, 0) },
            { CDF3( 3564, 15440, 28048), PARA(1, 1, 0) },
        }, .interintra_wedge = {
            CDF1(16758), PARA(2, 2, 2)
        }, .wedge_quad = {
            CDF3( 6511, 18144, 27374), PARA(2, 2, 1)
        }, .wedge_angle = {
            { CDF4(10258, 15276, 19997, 26561), PARA(2, 1, 1) },
            { CDF4(14039, 19183, 26143, 30047), PARA(2, 1, 1) },
            { CDF4(19564, 22099, 25104, 29960), PARA(2, 2, 1) },
            { CDF4(13808, 17950, 25715, 29008), PARA(2, 1, 0) },
        }, .wedge_dist = {
            CDF3( 8203, 16994, 21032), PARA(3, 2, 2)
        }, .wedge_dist2 = {
            CDF2(14463, 19115), PARA(3, 2, 2)
        }, .tip_drl_idx = {
            { CDF1(30662), PARA(2, 2, 2) },
            { CDF1(23823), PARA(2, 1, 1) },
            { CDF1(21676), PARA(2, 1, 1) },
        }, .jmvd_amvd_scale_mode = {
            CDF2(23178, 26812), PARA(2, 2, 2)
        }, .jmvd_scale_mode = {
            CDF4(23180, 24894, 26548, 29872), PARA(2, 2, 1)
        }, .drl_idx = {
            {
                { CDF1(15721), PARA(3, 3, 2) },
                { CDF1(21115), PARA(2, 2, 2) },
                { CDF1(19567), PARA(2, 2, 1) },
                { CDF1(17602), PARA(3, 3, 3) },
                { CDF1(13319), PARA(3, 3, 3) },
            }, {
                { CDF1(18692), PARA(3, 3, 3) },
                { CDF1(19343), PARA(3, 3, 2) },
                { CDF1(18207), PARA(3, 3, 2) },
                { CDF1(17908), PARA(3, 3, 3) },
                { CDF1(18304), PARA(3, 3, 3) },
            }, {
                { CDF1(22157), PARA(3, 3, 2) },
                { CDF1(23233), PARA(3, 3, 2) },
                { CDF1(22782), PARA(3, 3, 2) },
                { CDF1(22353), PARA(3, 3, 3) },
                { CDF1(22457), PARA(3, 3, 3) },
            }
        }, .mvprec_def = {
            { CDF1(20650), PARA(1, 1, 1) },
            { CDF1(15758), PARA(1, 1, 1) },
            { CDF1( 4571), PARA(1, 1, 1) },
        }, .mvprec_rem = {
            {
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(31340, 32505), PARA(3, 2, 3) },
                { CDF2(26039, 32175), PARA(2, 2, 2) },
            }, {
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(32197, 32676), PARA(3, 2, 2) },
                { CDF2(28679, 32626), PARA(2, 2, 2) },
            }
        }, .warp_ref_idx = {
            { CDF1(18903), PARA(2, 2, 2) },
            { CDF1(24500), PARA(3, 3, 2) },
            { CDF1(25360), PARA(3, 2, 2) },
        }, .amvd_joint = {
            CDF3(    4, 17705, 32748), PARA(2, 2, 1)
        }, .amvd_index = {
            { CDF7(10549, 15298, 16241, 22533, 27449, 30520, 32080), PARA(1, 2, 1) },
            { CDF7( 9414, 14965, 15966, 22465, 27468, 30628, 32144), PARA(1, 2, 1) },
        }, .warpmv_with_mvd = {
            CDF1(18452), PARA(2, 2, 1)
        }, .warp_delta_prec = {
            { CDF1(11830), PARA(0, 2, 2) },
            { CDF1(13323), PARA(1, 2, 2) },
            { CDF1(14893), PARA(1, 2, 2) },
            { CDF1(13952), PARA(1, 2, 2) },
            { CDF1(15633), PARA(1, 2, 2) },
            { CDF1(16040), PARA(1, 2, 2) },
            { CDF1(16736), PARA(1, 2, 2) },
            { CDF1(17451), PARA(1, 3, 2) },
            { CDF1(17823), PARA(1, 0, 2) },
            { CDF1(18893), PARA(2, 1, 2) },
            { CDF1(17968), PARA(1, 2, 2) },
            { CDF1(18210), PARA(1, 1, 0) },
            { CDF1(18671), PARA(1, 1, 0) },
            { CDF1(20345), PARA(2, 3, 2) },
            { CDF1(19398), PARA(1, 2, 2) },
            { CDF1(20146), PARA(1, 2, 0) },
            { CDF1(22585), PARA(1, 2, 1) },
            { CDF1(26435), PARA(1, 2, 1) },
            { CDF1(20066), PARA(1, 2, 2) },
            { CDF1(21783), PARA(1, 2, 3) },
            { CDF1(27357), PARA(1, 1, 1) },
            { CDF1(31107), PARA(0, 1, 1) },
        }, .warp_delta_param = {
            {
                { CDF7( 8995, 22970, 25406, 29673, 30295, 31670, 31863), PARA(2, 2, 2) },
                { CDF7(13333, 24012, 26545, 30183, 30839, 31958, 32139), PARA(2, 2, 2) },
            }, {
                { CDF7( 8959, 14388, 19825, 21810, 25035, 28077, 29469), PARA(2, 3, 2) },
                { CDF7( 9199, 14146, 19484, 21591, 24614, 28015, 29538), PARA(2, 2, 2) },
            }
        }, .warp_delta_sign = {
            CDF1(14285), PARA(3, 3, 3)
        }, .warp_interintra = {
            { CDF1(27980), PARA(0, 1, 1) },
            { CDF1(29163), PARA(0, 1, 1) },
            { CDF1(30658), PARA(0, 0, 0) },
        }, .txsz_lossless = {
            {
                { CDF1(16384), PARA(2, 2, 1) },
                { CDF1(16384), PARA(2, 2, 1) },
            }, {
                { CDF1(16384), PARA(3, 2, 2) },
                { CDF1(16384), PARA(3, 2, 2) },
            }, {
                { CDF1(16384), PARA(3, 2, 2) },
                { CDF1(16384), PARA(3, 2, 2) },
            }, {
                { CDF1(16384), PARA(3, 2, 2) },
                { CDF1(16384), PARA(3, 2, 2) },
            },
        }, .tx_split = {
            {
                { CDF1(26330), PARA(1, 1, 2) },
                { CDF1(29620), PARA(2, 2, 2) },
                { CDF1(20420), PARA(1, 1, 2) },
                { CDF1(21694), PARA(1, 1, 1) },
                { CDF1(13317), PARA(1, 1, 1) },
                { CDF1(15391), PARA(1, 1, 1) },
                { CDF1(15952), PARA(1, 1, 1) },
                { CDF1(14736), PARA(1, 1, 1) },
                { CDF1(13810), PARA(2, 1, 2) },
            }, {
                { CDF1(31646), PARA(0, 1, 2) },
                { CDF1(32393), PARA(1, 2, 2) },
                { CDF1(30802), PARA(1, 2, 1) },
                { CDF1(30485), PARA(1, 1, 1) },
                { CDF1(20759), PARA(1, 1, 0) },
                { CDF1(22159), PARA(2, 2, 1) },
                { CDF1(26832), PARA(1, 1, 1) },
                { CDF1(27351), PARA(2, 2, 1) },
                { CDF1(24696), PARA(2, 2, 1) },
            }, {
                { CDF1(29308), PARA(2, 2, 2) },
                { CDF1(32550), PARA(3, 3, 3) },
                { CDF1(27963), PARA(2, 2, 1) },
                { CDF1(27618), PARA(1, 1, 1) },
                { CDF1(22367), PARA(2, 1, 0) },
                { CDF1(23478), PARA(1, 0, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(27990), PARA(2, 2, 2) },
            }
        }, .tx_part_1d = {
            {
                { CDF1(25131), PARA(1, 1, 2) },
                { CDF1(24514), PARA(1, 1, 2) },
            }, {
                { CDF1(19534), PARA(2, 1, 1) },
                { CDF1(18637), PARA(2, 2, 2) },
            }, {
                { CDF1(30226), PARA(0, 2, 2) },
                { CDF1(30703), PARA(1, 1, 3) },
            }
        }, .txtp_lossless = {
            CDF1(16384), PARA(2, 2, 2)
        }, .txtp_long32_dct = {
            { CDF1(   36), PARA(2, 2, 2) },
            { CDF1(  128), PARA(1, 1, 1) },
        }, .txtp_intra_short_1d = {
            { CDF3(10692, 26586, 29231), PARA(1, 1, 1) },
            { CDF3(26700, 32160, 32748), PARA(2, 1, 1) },
            { CDF3(26915, 32411, 32748), PARA(2, 1, 1) },
        }, .txtp_inter_short_1d = {
            {
                { CDF3( 8347, 20254, 24536), PARA(1, 1, 1) },
                { CDF3(15994, 26294, 32748), PARA(2, 2, 1) },
                { CDF3(21212, 27810, 32748), PARA(2, 2, 1) },
            }, {
                { CDF3(21815, 25084, 26230), PARA(0, 0, 0) },
                { CDF3(29354, 31747, 32748), PARA(1, 0, 0) },
                { CDF3(31614, 32529, 32748), PARA(1, 0, 1) },
            }, {
                { CDF3(10501, 20590, 24181), PARA(1, 1, 1) },
                { CDF3(17596, 26388, 32748), PARA(1, 0, 0) },
                { CDF3(15407, 26475, 32732), PARA(0, 0, 2) },
            }
        }, .txtp_ext = {
            { CDF6( 5026, 16816, 19974, 23404, 26845, 30499), PARA(2, 1, 3) },
            { CDF6(14910, 25257, 26964, 29323, 30237, 31535), PARA(2, 2, 2) },
            { CDF6(13759, 26108, 27688, 29793, 30265, 31576), PARA(1, 0, 2) },
        }, .txtp_ext_reduced = {
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
        }, .txtp_inter_tx_set = {
            {
                { CDF1(14122), PARA(1, 2, 2) },
                { CDF1( 8962), PARA(1, 1, 1) },
                { CDF1(20835), PARA(2, 2, 2) },
            }, {
                { CDF1(16423), PARA(1, 2, 1) },
                { CDF1(23446), PARA(2, 2, 2) },
                { CDF1(30720), PARA(2, 2, 3) },
            }, {
                { CDF1(23352), PARA(1, 2, 2) },
                { CDF1(17069), PARA(0, 1, 1) },
                { CDF1(28857), PARA(2, 3, 0) },
            }
        }, .txtp_inter_set0 = {
            {
                { CDF7( 8914, 10732, 12270, 14822, 17128, 19586, 21964), PARA(1, 2, 2) },
                { CDF7( 1160,  1555,  1972,  3414,  3962,  5151,  5908), PARA(1, 1, 1) },
                { CDF7(22819, 24338, 25592, 27001, 28395, 29648, 30990), PARA(1, 2, 2) },
            }, {
                { CDF7( 1140,  1725,  2324, 14653, 19072, 23618, 28109), PARA(1, 1, 1) },
                { CDF7(   58,   261,   587, 32317, 32556, 32626, 32708), PARA(2, 2, 0) },
                { CDF7(17404, 17669, 18403, 24052, 26393, 28506, 30676), PARA(0, 1, 0) },
            },
        }, .txtp_inter_set1 = {
            { CDF7( 3121,  6470,  9191, 12280, 17811, 22588, 27697), PARA(3, 3, 3) },
            { CDF7(  338,   377,   571,   743,  7932, 11860, 17524), PARA(2, 2, 1) },
            { CDF7( 3314,  7625, 10639, 14206, 19363, 23456, 28033), PARA(3, 3, 3) },
        }, .txtp_inter_set2 = {
            { CDF3( 8669, 16533, 24855), PARA(3, 3, 3) },
            { CDF3( 9441, 16413, 25276), PARA(3, 3, 2) },
            { CDF3( 8767, 17611, 24876), PARA(2, 0, 2) },
        }, .txtp_inter_dct_idtx = {
            {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            },
        }, .txtp_inter_dct_idtx_iddct = {
            {
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            }, {
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            }, {
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            }
        }, .stx = {
            {
                { CDF3( 4486, 15589, 26440), PARA(3, 2, 2) },
                { CDF3( 2357,  9504, 16641), PARA(2, 1, 2) },
                { CDF3( 1364,  8034, 14431), PARA(2, 2, 2) },
                { CDF3( 2472,  8725, 13853), PARA(3, 2, 1) },
                { CDF3( 7523, 11681, 14783), PARA(2, 2, 1) },
              },
              {
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) }, // unused?
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) }, // unused?
                { CDF3(10490, 15394, 22206), PARA(1, 1, 1) },
                { CDF3(13967, 16953, 23109), PARA(1, 1, 1) },
                { CDF3(20191, 21727, 25818), PARA(1, 1, 0) },
            },
        }, .stx_set = {
            CDF6(20712, 26263, 30623, 32732, 32736, 32740), PARA(0, 1, 2),
        }, .stx_set_adst = {
            CDF3(15897, 26144, 30010), PARA(2, 1, 2)
        }, .cctx = {
            CDF6(14350, 14836, 16054, 17075, 19408, 28530), PARA(0, 0, 0)
        }, .comp_mode_sameref = {
            { CDF3( 6386, 23344, 23348), PARA(1, 1, 1) },
            { CDF3(10945, 24709, 24714), PARA(1, 1, 1) },
            { CDF3(11517, 25230, 25258), PARA(1, 1, 1) },
            { CDF3( 7563, 22176, 22180), PARA(1, 1, 1) },
            { CDF3( 6629, 20955, 20966), PARA(2, 1, 1) },
        }, .comp_mode_joint = {
            { CDF1(24720), PARA(2, 2, 2) },
            { CDF1(32764), PARA(2, 2, 2) },
        }, .comp_mode = {
            { CDF4(12177, 20001, 23193, 24448), PARA(1, 2, 1) },
            { CDF4(21192, 25117, 27806, 27948), PARA(1, 1, 1) },
            { CDF4(26779, 28724, 30192, 30249), PARA(1, 2, 2) },
            { CDF4(12506, 17871, 21295, 21389), PARA(1, 1, 1) },
            { CDF4(16948, 20335, 22582, 22617), PARA(1, 1, 1) },
        }, .opfl = {
            { CDF1(11582), PARA(1, 1, 1) },
            { CDF1(24076), PARA(1, 2, 1) },
        }, .refine_mv = {
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(20204), PARA(1, 2, 2) },
            { CDF1(17614), PARA(1, 3, 3) },
            { CDF1(24443), PARA(1, 1, 0) },
        }, .comp_type_masked = {
            { CDF1(17510), PARA(1, 2, 1) },
            { CDF1(10382), PARA(2, 2, 2) },
            { CDF1( 8336), PARA(1, 1, 1) },
            { CDF1( 6054), PARA(2, 2, 1) },
            { CDF1( 5764), PARA(2, 1, 2) },
            { CDF1( 7154), PARA(2, 0, 2) },
            { CDF1(15013), PARA(1, 2, 1) },
            { CDF1( 8426), PARA(2, 2, 2) },
            { CDF1( 8278), PARA(2, 2, 1) },
            { CDF1( 4856), PARA(2, 2, 1) },
            { CDF1( 3464), PARA(2, 2, 2) },
            { CDF1( 5295), PARA(2, 2, 2) },
        }, .comp_type_weighted = {
            CDF1(16894), PARA(1, 1, 1)
        }, .cwp_idx = {
            { CDF1(21704), PARA(0, 1, 1) },
            { CDF1(15990), PARA(1, 1, 1) },
            { CDF1(12544), PARA(0, 1, 0) },
            { CDF1(25638), PARA(0, 0, 0) },
        }, .filter = {
            { CDF2(29975, 32748), PARA(1, 2, 2) },
            { CDF2( 2076, 32703), PARA(3, 2, 2) },
            { CDF2(   19,  1768), PARA(2, 3, 2) },
            { CDF2(17314, 27415), PARA(1, 1, 1) },
            { CDF2(31286, 31994), PARA(2, 2, 2) },
            { CDF2( 9581, 32608), PARA(1, 1, 1) },
            { CDF2(  535,  1036), PARA(2, 2, 2) },
            { CDF2(24819, 27722), PARA(1, 1, 1) },
        }, .seg_pred = {
            { CDF1(16384), PARA(2, 2, 2) }, { CDF1(16384), PARA(2, 2, 2) }, { CDF1(16384), PARA(2, 2, 2) },
        }, .seg_id_ext = {
            { CDF1(16384), PARA(2, 2, 2) }, { CDF1(16384), PARA(2, 2, 2) }, { CDF1(16384), PARA(2, 2, 2) },
        }, .seg_id = {
            {
                { CDF7( 5622,  7893, 16093, 18233, 27809, 28373, 32533), PARA(2, 2, 2) },
                { CDF7(14274, 18230, 22557, 24935, 29980, 30851, 32344), PARA(2, 2, 2) },
                { CDF7(27527, 28487, 28723, 28890, 32397, 32647, 32679), PARA(2, 2, 2) },
            }, {
                { CDF7( 4096,  8192, 12288, 16384, 20480, 24576, 28672), PARA(2, 2, 2) },
                { CDF7( 4096,  8192, 12288, 16384, 20480, 24576, 28672), PARA(2, 2, 2) },
                { CDF7( 4096,  8192, 12288, 16384, 20480, 24576, 28672), PARA(2, 2, 2) },
            }
        }, .delta_q = {
            CDF7(16594, 23325, 26424, 28225, 29358, 30099, 30613), PARA(0, 1, 1)
        },
    }, .mv = {
        .shell_set = {
            CDF1(31579), PARA(1, 2, 2)
        }, .shell_lower = {
            { CDF4( 4460, 12999, 22505, 30840), PARA(1, 0, 3) },
            { CDF5( 7519, 18907, 25563, 29875, 31983), PARA(1, 2, 0) },
            { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
            { CDF6( 8680, 13723, 18208, 22686, 26722, 30020), PARA(2, 1, 2) },
            { CDF6( 4324, 15300, 23690, 28697, 31282, 32359), PARA(2, 2, 1) },
            { CDF7( 7497, 17301, 23848, 27438, 29395, 30879, 32003), PARA(1, 1, 1) },
            { CDF7(10667, 20239, 25883, 29670, 31400, 32153, 32579), PARA(2, 2, 2) },
        }, .shell_upper = {
            { CDF5(21329, 30564, 32589, 32649, 32708), PARA(0, 2, 2) },
            { CDF5(24250, 31806, 32676, 32722, 32732), PARA(0, 2, 2) },
            { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
            { CDF6(19978, 30160, 32564, 32732, 32736, 32740), PARA(2, 2, 1) },
            { CDF7(19707, 28414, 31240, 31648, 32692, 32717, 32721), PARA(1, 2, 2) },
            { CDF7(18469, 27427, 31562, 32652, 32724, 32728, 32732), PARA(1, 1, 1) },
            { CDF7(17810, 25196, 29372, 31953, 32564, 32720, 32724), PARA(0, 1, 2) },
        }, .shell_tip = {
            CDF1(16384), PARA(2, 2, 2)
        }, .shell_offset_low = {
            { CDF1(14587), PARA(1, 0, 1) },
            { CDF1(20966), PARA(3, 2, 2) },
        }, .shell_offset_cl2 = {
            CDF1(13189), PARA(2, 2, 2)
        }, .shell_offset_hi = {
            { CDF1(17943), PARA(3, 3, 3) },
            { CDF1(18934), PARA(3, 3, 3) },
            { CDF1(18928), PARA(3, 3, 3) },
            { CDF1(18696), PARA(3, 3, 3) },
            { CDF1(19044), PARA(3, 3, 3) },
            { CDF1(20362), PARA(3, 3, 3) },
            { CDF1(20426), PARA(3, 3, 3) },
            { CDF1(22563), PARA(3, 3, 3) },
            { CDF1(22190), PARA(3, 3, 3) },
            { CDF1(23458), PARA(3, 3, 2) },
            { CDF1(26227), PARA(2, 2, 0) },
            { CDF1(30765), PARA(0, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
        }, .col_component = {
            { CDF1( 5663), PARA(1, 2, 2) },
            { CDF1( 4856), PARA(3, 3, 2) },
        }, .col_index = {
            { CDF1(13445), PARA(2, 2, 1) },
            { CDF1(13541), PARA(2, 2, 1) },
            { CDF1(14045), PARA(2, 2, 1) },
            { CDF1(12888), PARA(1, 1, 1) },
        }
    },
};

static const CdfTxPart2dContext default_tx_part_2d_cdf[2] = {
    [0] = {
        .tx_part_2d = {
            {
                { CDF6(32744, 32748, 32752, 32756, 32760, 32764), PARA(0, 0, 2) },
                { CDF6( 3006, 22888, 27132, 29972, 29976, 32724), PARA(1, 1, 1) },
                { CDF6( 3673,  8849, 27652, 27656, 29944, 29948), PARA(1, 1, 1) },
                { CDF6( 5219, 19419, 28052, 28836, 29528, 31296), PARA(1, 1, 1) },
                { CDF6( 3055, 19649, 22157, 27038, 27466, 31646), PARA(1, 1, 1) },
                { CDF6( 6044, 11255, 26170, 26493, 28585, 29584), PARA(1, 1, 1) },
                { CDF6( 5896, 20361, 25685, 27552, 28695, 31097), PARA(1, 1, 1) },
                { CDF6( 2355, 17601, 21703, 26050, 27881, 31397), PARA(1, 1, 0) },
                { CDF6( 4701, 13502, 24958, 26413, 28166, 30129), PARA(1, 1, 0) },
                { CDF6( 3319, 16449, 21641, 27154, 29260, 31512), PARA(1, 1, 0) },
                { CDF6( 2526, 17088, 19643, 29378, 29382, 32724), PARA(1, 1, 1) },
                { CDF6( 2298,  4406, 23886, 23890, 30148, 30152), PARA(1, 1, 1) },
                { CDF6( 1553, 16160, 18679, 27983, 29592, 32139), PARA(1, 1, 0) },
                { CDF6( 2316,  4714, 22731, 23797, 29514, 30077), PARA(1, 0, 0) },
            }, {
                { CDF6(10790, 22602, 32736, 32740, 32744, 32748), PARA(1, 1, 0) },
                { CDF6(14384, 19116, 26545, 28687, 28691, 32724), PARA(1, 1, 1) },
                { CDF6(13910, 21690, 26343, 26347, 28432, 28436), PARA(1, 1, 1) },
                { CDF6(15891, 21712, 28890, 29571, 30307, 31363), PARA(1, 1, 0) },
                { CDF6(15946, 19447, 20270, 23423, 23858, 31148), PARA(1, 1, 0) },
                { CDF6(16053, 16957, 20312, 20924, 24770, 25959), PARA(1, 1, 0) },
                { CDF6(18479, 23053, 26582, 26966, 27567, 29836), PARA(0, 0, 0) },
                { CDF6( 9312, 11882, 14354, 17792, 19827, 29477), PARA(0, 0, 0) },
                { CDF6( 8490, 10668, 13295, 15353, 19952, 22575), PARA(0, 0, 0) },
                { CDF6( 6404, 12066, 16173, 20041, 24512, 28421), PARA(0, 0, 0) },
                { CDF6(10019, 14455, 17658, 27012, 27016, 32724), PARA(1, 0, 0) },
                { CDF6( 9479, 14904, 19374, 19378, 28027, 28031), PARA(1, 0, 0) },
                { CDF6( 3717,  7198,  8103, 20546, 23558, 31447), PARA(0, 0, 0) },
                { CDF6( 4058,  5429,  8987, 13978, 25126, 26655), PARA(0, 0, 0) },
            }, {
                { CDF6(32434, 32490, 32545, 32601, 32657, 32712), PARA(0, 2, 2) },
                { CDF6( 1491, 14241, 29930, 32517, 32524, 32724), PARA(0, 1, 0) },
                { CDF6( 1719, 16525, 31000, 31004, 32575, 32579), PARA(1, 1, 2) },
                { CDF6( 1645, 16749, 29324, 30425, 32016, 32485), PARA(0, 0, 0) },
                { CDF6( 2908, 15802, 24689, 28470, 32122, 32542), PARA(1, 2, 2) },
                { CDF6( 3470, 17931, 25841, 29589, 31907, 32465), PARA(1, 3, 3) },
                { CDF6( 5638, 19594, 28693, 29977, 30703, 32154), PARA(0, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 2734, 12129, 30342, 31805, 31844, 32724), PARA(0, 2, 2) },
                { CDF6( 3849, 21783, 31043, 31056, 32181, 32193), PARA(0, 3, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
            }
        },
    }, [1] = {
        .tx_part_2d = {
            {
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
            }, {
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
            }, {
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
                { CDF6( 4681,  9362, 14043, 18725, 23406, 28087), PARA(2, 2, 2) },
            }
        },
    },
};

static const CdfCoefContext default_coef_cdf[4] = {
    [0] = {
        .skip = {
            {
                {
                    { CDF1(25759), PARA(1, 1, 1) },
                    { CDF1( 1099), PARA(3, 3, 3) },
                    { CDF1( 2762), PARA(2, 1, 2) },
                    { CDF1( 7944), PARA(1, 2, 1) },
                    { CDF1(16230), PARA(2, 1, 1) },
                    { CDF1(29076), PARA(1, 1, 1) },
                    { CDF1( 8898), PARA(2, 2, 1) },
                    { CDF1(13655), PARA(2, 2, 1) },
                    { CDF1(22348), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(24799), PARA(0, 1, 1) },
                    { CDF1( 3162), PARA(3, 2, 2) },
                    { CDF1( 4813), PARA(2, 2, 2) },
                    { CDF1(13562), PARA(2, 2, 1) },
                    { CDF1(17989), PARA(3, 2, 1) },
                    { CDF1(31799), PARA(2, 2, 2) },
                    { CDF1( 5170), PARA(3, 2, 2) },
                    { CDF1(12844), PARA(2, 2, 1) },
                    { CDF1(22336), PARA(2, 1, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(18946), PARA(0, 0, 0) },
                    { CDF1( 5651), PARA(2, 1, 1) },
                    { CDF1( 6193), PARA(2, 1, 0) },
                    { CDF1(15587), PARA(2, 1, 0) },
                    { CDF1(18312), PARA(3, 3, 1) },
                    { CDF1(31798), PARA(3, 1, 2) },
                    { CDF1( 2961), PARA(2, 2, 2) },
                    { CDF1(11605), PARA(1, 2, 1) },
                    { CDF1(24657), PARA(1, 1, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1( 7809), PARA(0, 0, 0) },
                    { CDF1( 3864), PARA(1, 1, 3) },
                    { CDF1(14130), PARA(1, 3, 2) },
                    { CDF1(16018), PARA(1, 1, 0) },
                    { CDF1(15599), PARA(2, 0, 2) },
                    { CDF1(28161), PARA(1, 1, 0) },
                    { CDF1( 1300), PARA(1, 0, 1) },
                    { CDF1(11703), PARA(0, 1, 0) },
                    { CDF1(24729), PARA(1, 1, 3) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1( 2800), PARA(0, 0, 0) },
                    { CDF1(  159), PARA(1, 1, 0) },
                    { CDF1( 1725), PARA(0, 2, 2) },
                    { CDF1(11138), PARA(0, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(32319), PARA(2, 2, 2) },
                    { CDF1(  456), PARA(0, 0, 3) },
                    { CDF1( 6416), PARA(0, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF1(32764), PARA(2, 2, 2) },
                    { CDF1(10751), PARA(2, 3, 1) },
                    { CDF1(17579), PARA(2, 3, 1) },
                    { CDF1(24060), PARA(3, 3, 2) },
                    { CDF1(28085), PARA(2, 1, 2) },
                    { CDF1(30928), PARA(3, 3, 3) },
                    { CDF1( 5437), PARA(1, 0, 0) },
                    { CDF1(17819), PARA(1, 2, 1) },
                    { CDF1(28074), PARA(2, 1, 3) },
                    { CDF1(30432), PARA(3, 1, 2) },
                }, {
                    { CDF1(32452), PARA(0, 0, 0) },
                    { CDF1(14328), PARA(3, 3, 3) },
                    { CDF1(18927), PARA(3, 3, 3) },
                    { CDF1(22405), PARA(3, 3, 3) },
                    { CDF1(25460), PARA(3, 3, 3) },
                    { CDF1(30634), PARA(3, 2, 2) },
                    { CDF1( 5152), PARA(1, 1, 1) },
                    { CDF1(15362), PARA(1, 1, 1) },
                    { CDF1(24814), PARA(2, 1, 1) },
                    { CDF1(31865), PARA(2, 2, 2) },
                }, {
                    { CDF1(31891), PARA(0, 0, 0) },
                    { CDF1(17014), PARA(3, 3, 3) },
                    { CDF1(19836), PARA(3, 3, 3) },
                    { CDF1(20450), PARA(2, 1, 1) },
                    { CDF1(25131), PARA(2, 2, 1) },
                    { CDF1(31538), PARA(2, 2, 3) },
                    { CDF1( 5465), PARA(1, 2, 2) },
                    { CDF1(17440), PARA(1, 1, 1) },
                    { CDF1(28788), PARA(2, 2, 1) },
                    { CDF1(29135), PARA(1, 0, 0) },
                }, {
                    { CDF1(31092), PARA(0, 0, 0) },
                    { CDF1(11952), PARA(1, 2, 3) },
                    { CDF1( 1928), PARA(2, 2, 2) },
                    { CDF1(19906), PARA(2, 0, 0) },
                    { CDF1(32150), PARA(0, 2, 2) },
                    { CDF1(31347), PARA(0, 2, 0) },
                    { CDF1( 9362), PARA(2, 0, 2) },
                    { CDF1(29127), PARA(0, 2, 2) },
                    { CDF1(32373), PARA(0, 2, 2) },
                    { CDF1(27387), PARA(0, 0, 2) },
                }, {
                    { CDF1(26822), PARA(0, 0, 3) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            },
        }, .eob_bin_16 = {
            { CDF4( 1946,  3059,  6834, 15123), PARA(2, 1, 1) },
            { CDF4(  558,   835,  2739,  6534), PARA(1, 2, 2) },
            { CDF4( 8000, 10366, 14466, 19569), PARA(1, 1, 1) },
        }, .eob_bin_32 = {
            { CDF5( 1203,  1920,  4502, 10281, 17078), PARA(2, 1, 1) },
            { CDF5( 1078,  1340,  2464,  5152, 11416), PARA(2, 1, 2) },
            { CDF5(11670, 14271, 19287, 23919, 27084), PARA(1, 1, 1) },
        }, .eob_bin_64 = {
            { CDF6( 1848,  2357,  4392,  7629, 13328, 21530), PARA(1, 1, 0) },
            { CDF6( 1476,  1703,  2435,  4245,  7520, 14818), PARA(2, 1, 1) },
            { CDF6(13125, 16136, 21482, 26341, 29681, 31034), PARA(1, 1, 1) },
        }, .eob_bin_128 = {
            { CDF7(  336,   988,  2984,  5382,  9800, 16995, 24488), PARA(1, 1, 0) },
            { CDF7( 1506,  2078,  2996,  4361,  7027, 12117, 21037), PARA(2, 1, 1) },
            { CDF7(10069, 12663, 18436, 24325, 28451, 30559, 31560), PARA(1, 1, 1) },
        }, .eob_bin_256 = {
            { CDF7(  321,  2376,  5427,  7836, 12726, 18552, 21084), PARA(1, 1, 0) },
            { CDF7( 1954,  2587,  3867,  5133,  7560, 10574, 14742), PARA(1, 0, 0) },
            { CDF7( 7984, 10878, 15991, 20185, 25357, 29358, 31262), PARA(1, 1, 0) },
        }, .eob_bin_512 = {
            { CDF7(  139,  5954, 13032, 16244, 20068, 24954, 25897), PARA(1, 1, 0) },
            { CDF7( 3412,  3896,  5734,  7524, 10117, 13773, 16441), PARA(0, 0, 0) },
            { CDF7(12810, 16127, 22415, 25016, 27768, 29850, 31372), PARA(1, 1, 0) },
        }, .eob_bin_1024 = {
            { CDF7(  576,  1953,  8086, 14995, 20006, 24682, 25870), PARA(0, 0, 0) },
            { CDF7( 2747,  3019,  3935,  4876,  6051,  8588, 10135), PARA(0, 1, 0) },
            { CDF7(11873, 15379, 25835, 27918, 29093, 30164, 30782), PARA(1, 1, 0) },
        }, .eob_hi_bit = {
            CDF1(16391), PARA(2, 2, 2)
        }, .eob_base_y_tok_hf = {
            {
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(25475, 29789), PARA(3, 2, 2) },
            }, {
                { CDF2(32132, 32609), PARA(0, 2, 2) },
                { CDF2(32294, 32701), PARA(3, 2, 2) },
                { CDF2(31618, 32500), PARA(3, 3, 3) },
            }, {
                { CDF2(32658, 32751), PARA(3, 2, 3) },
                { CDF2(32701, 32753), PARA(3, 3, 3) },
                { CDF2(32675, 32745), PARA(3, 3, 3) },
            }, {
                { CDF2(32658, 32719), PARA(0, 3, 2) },
                { CDF2(32658, 32744), PARA(0, 3, 0) },
                { CDF2(32647, 32756), PARA(1, 1, 3) },
            }, {
                { CDF2(32538, 32711), PARA(2, 2, 2) },
                { CDF2(32138, 32453), PARA(2, 2, 2) },
                { CDF2(32356, 32562), PARA(0, 2, 2) },
            }
        }, .eob_base_y_tok_lf = {
            {
                { CDF4(27486, 31140, 31779, 32064), PARA(2, 1, 0) },
                { CDF4(28263, 31142, 31813, 32057), PARA(2, 1, 1) },
                { CDF4(27578, 30405, 31202, 31448), PARA(2, 1, 1) },
                { CDF4(29800, 32145, 32589, 32665), PARA(3, 3, 3) },
            }, {
                { CDF4(27197, 31209, 31698, 31944), PARA(1, 1, 0) },
                { CDF4(30415, 31987, 32302, 32387), PARA(2, 2, 2) },
                { CDF4(30766, 32160, 32461, 32564), PARA(3, 2, 2) },
                { CDF4(31446, 32510, 32712, 32740), PARA(3, 3, 2) },
            }, {
                { CDF4( 9881, 28329, 30354, 31217), PARA(0, 0, 0) },
                { CDF4(30815, 32135, 32360, 32446), PARA(2, 1, 2) },
                { CDF4(31896, 32058, 32423, 32525), PARA(1, 0, 0) },
                { CDF4(27097, 28987, 31508, 32138), PARA(0, 2, 2) },
            }, {
                { CDF4(   76,  3661, 13759, 21509), PARA(0, 0, 0) },
                { CDF4(31910, 32583, 32688, 32740), PARA(3, 3, 3) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            }, {
                { CDF4(  298,   596,   894,  1192), PARA(0, 2, 2) },
                { CDF4(29008, 30611, 32490, 32683), PARA(2, 2, 3) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            },
        }, .base_y_tok_hf = {
            {
                {
                    { CDF3(12360, 26392, 29943), PARA(1, 2, 1) },
                    { CDF3( 8590, 25353, 30895), PARA(2, 1, 1) },
                }, {
                    { CDF3( 7246, 19496, 26530), PARA(3, 2, 2) },
                    { CDF3( 3468, 16232, 25621), PARA(3, 3, 2) },
                }, {
                    { CDF3( 4008, 12605, 18928), PARA(3, 3, 3) },
                    { CDF3( 1999,  9165, 16685), PARA(3, 3, 3) },
                }, {
                    { CDF3( 3148,  9393, 14900), PARA(3, 3, 3) },
                    { CDF3( 1110,  7696, 14122), PARA(3, 2, 3) },
                }, {
                    { CDF3( 2543,  7526, 12021), PARA(3, 3, 3) },
                    { CDF3( 2561,  5445, 10546), PARA(3, 3, 3) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(28014, 31534, 32060), PARA(2, 1, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(13135, 23487, 28599), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7049, 15368, 20768), PARA(3, 3, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3109,  8054, 12383), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(25298, 32426, 32713), PARA(3, 3, 3) },
                    { CDF3(14651, 31551, 32591), PARA(3, 3, 3) },
                }, {
                    { CDF3(18466, 30483, 32267), PARA(3, 2, 2) },
                    { CDF3(  306, 26643, 31787), PARA(3, 3, 2) },
                }, {
                    { CDF3(12399, 26150, 30691), PARA(3, 3, 2) },
                    { CDF3( 1131, 21210, 29129), PARA(3, 2, 2) },
                }, {
                    { CDF3( 7487, 20115, 26881), PARA(3, 3, 3) },
                    { CDF3(  656, 14639, 24430), PARA(3, 2, 2) },
                }, {
                    { CDF3( 3588, 11042, 17169), PARA(3, 2, 3) },
                    { CDF3(  756,  7796, 14913), PARA(3, 2, 3) },
                }, {
                    { CDF3(26570, 32443, 32691), PARA(3, 2, 3) },
                    { CDF3(17559, 31708, 32628), PARA(3, 2, 3) },
                }, {
                    { CDF3(18312, 30354, 32288), PARA(3, 3, 2) },
                    { CDF3(  581, 26605, 31701), PARA(3, 3, 2) },
                }, {
                    { CDF3(11812, 25791, 30572), PARA(3, 2, 2) },
                    { CDF3( 1073, 20736, 28973), PARA(3, 2, 2) },
                }, {
                    { CDF3( 7165, 19304, 26609), PARA(3, 3, 3) },
                    { CDF3(  971, 14401, 24415), PARA(3, 3, 3) },
                }, {
                    { CDF3( 3978, 12366, 19160), PARA(3, 3, 3) },
                    { CDF3(  935,  8823, 16611), PARA(3, 2, 3) },
                }, {
                    { CDF3(25670, 32230, 32678), PARA(3, 2, 2) },
                    { CDF3(19556, 31721, 32677), PARA(2, 2, 2) },
                }, {
                    { CDF3(17121, 29735, 32054), PARA(3, 2, 2) },
                    { CDF3( 1460, 26595, 31623), PARA(3, 3, 2) },
                }, {
                    { CDF3(11589, 25561, 30426), PARA(3, 3, 2) },
                    { CDF3( 1652, 20606, 28939), PARA(3, 2, 3) },
                }, {
                    { CDF3( 7343, 20631, 27574), PARA(3, 3, 2) },
                    { CDF3(  922, 15328, 25115), PARA(3, 2, 2) },
                }, {
                    { CDF3( 4778, 14146, 21151), PARA(3, 3, 2) },
                    { CDF3(  902,  9679, 18420), PARA(3, 2, 3) },
                }, {
                    { CDF3(30964, 32538, 32693), PARA(2, 1, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(18212, 29081, 31586), PARA(3, 3, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(10647, 22153, 27538), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 6396, 16045, 22849), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3574, 10559, 16078), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(28697, 32692, 32748), PARA(3, 3, 2) },
                    { CDF3(13717, 32316, 32740), PARA(3, 3, 2) },
                }, {
                    { CDF3(24783, 32374, 32712), PARA(3, 3, 2) },
                    { CDF3( 1229, 30871, 32600), PARA(3, 2, 2) },
                }, {
                    { CDF3(19000, 30799, 32442), PARA(3, 2, 2) },
                    { CDF3( 2583, 27380, 31887), PARA(2, 3, 2) },
                }, {
                    { CDF3(10656, 24633, 30053), PARA(3, 2, 2) },
                    { CDF3(  882, 19759, 28348), PARA(3, 2, 2) },
                }, {
                    { CDF3( 4024, 11749, 17822), PARA(3, 2, 2) },
                    { CDF3(  311,  8254, 15425), PARA(3, 2, 2) },
                }, {
                    { CDF3(29761, 32708, 32748), PARA(3, 2, 2) },
                    { CDF3(18251, 32567, 32748), PARA(2, 2, 2) },
                }, {
                    { CDF3(24756, 32428, 32722), PARA(3, 2, 2) },
                    { CDF3( 1802, 30951, 32542), PARA(3, 3, 3) },
                }, {
                    { CDF3(18650, 30593, 32394), PARA(3, 2, 2) },
                    { CDF3( 2883, 27721, 31874), PARA(3, 2, 3) },
                }, {
                    { CDF3(10280, 24576, 29914), PARA(3, 2, 2) },
                    { CDF3(  288, 19075, 28254), PARA(2, 2, 1) },
                }, {
                    { CDF3( 3976, 12847, 19261), PARA(3, 2, 2) },
                    { CDF3(  754,  8850, 16554), PARA(2, 2, 3) },
                }, {
                    { CDF3(30346, 32725, 32748), PARA(3, 2, 2) },
                    { CDF3(24555, 32672, 32748), PARA(2, 1, 2) },
                }, {
                    { CDF3(24866, 32414, 32726), PARA(3, 2, 2) },
                    { CDF3(  857, 31274, 32665), PARA(3, 3, 2) },
                }, {
                    { CDF3(18664, 30690, 32404), PARA(3, 3, 3) },
                    { CDF3( 2459, 27485, 31962), PARA(3, 3, 3) },
                }, {
                    { CDF3(10302, 24628, 30393), PARA(3, 3, 3) },
                    { CDF3(  923, 19581, 28849), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5108, 14969, 22262), PARA(3, 2, 3) },
                    { CDF3(  637, 11172, 20006), PARA(3, 2, 3) },
                }, {
                    { CDF3(32114, 32706, 32748), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(22647, 31591, 32522), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(14439, 26903, 30661), PARA(2, 1, 1) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7410, 19635, 26647), PARA(2, 2, 1) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3267, 10417, 16526), PARA(3, 3, 0) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(29459, 32676, 32741), PARA(1, 2, 1) },
                    { CDF3(12621, 32434, 32748), PARA(3, 1, 3) },
                }, {
                    { CDF3(23667, 32112, 32701), PARA(3, 2, 2) },
                    { CDF3( 5563, 30354, 32581), PARA(3, 2, 2) },
                }, {
                    { CDF3(19383, 30660, 32564), PARA(3, 2, 2) },
                    { CDF3( 3845, 27375, 31697), PARA(3, 3, 2) },
                }, {
                    { CDF3(10075, 24894, 29897), PARA(3, 3, 2) },
                    { CDF3( 2073, 19727, 27880), PARA(3, 2, 3) },
                }, {
                    { CDF3( 3368,  9398, 13892), PARA(3, 1, 1) },
                    { CDF3(  571,  6307, 12048), PARA(3, 1, 1) },
                }, {
                    { CDF3(30541, 32712, 32748), PARA(2, 3, 3) },
                    { CDF3(17105, 32518, 32748), PARA(3, 3, 2) },
                }, {
                    { CDF3(26380, 32437, 32736), PARA(3, 2, 3) },
                    { CDF3( 1892, 31537, 32682), PARA(3, 3, 1) },
                }, {
                    { CDF3(20557, 31281, 32473), PARA(3, 3, 2) },
                    { CDF3( 3148, 28251, 32121), PARA(2, 2, 2) },
                }, {
                    { CDF3(10605, 25976, 30389), PARA(3, 2, 1) },
                    { CDF3( 3627, 20150, 28517), PARA(3, 2, 1) },
                }, {
                    { CDF3( 3792, 11134, 15907), PARA(3, 1, 1) },
                    { CDF3(  517,  7539, 13580), PARA(3, 1, 1) },
                }, {
                    { CDF3(30408, 32748, 32752), PARA(3, 2, 2) },
                    { CDF3(32291, 32705, 32748), PARA(3, 2, 2) },
                }, {
                    { CDF3(25730, 32585, 32739), PARA(3, 3, 2) },
                    { CDF3( 5942, 31616, 32616), PARA(3, 3, 3) },
                }, {
                    { CDF3(20185, 31076, 32464), PARA(3, 2, 3) },
                    { CDF3( 1004, 28344, 32094), PARA(3, 2, 3) },
                }, {
                    { CDF3(11707, 26199, 30689), PARA(3, 3, 3) },
                    { CDF3( 1262, 21328, 29569), PARA(3, 3, 3) },
                }, {
                    { CDF3( 5035, 14930, 21229), PARA(3, 3, 2) },
                    { CDF3(  746, 10699, 18756), PARA(3, 3, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(28383, 32609, 32688), PARA(2, 0, 2) },
                    { CDF3(15428, 32067, 32704), PARA(1, 0, 2) },
                }, {
                    { CDF3(15754, 30788, 32588), PARA(3, 3, 2) },
                    { CDF3( 4880, 29631, 31606), PARA(2, 2, 2) },
                }, {
                    { CDF3(10550, 24328, 32147), PARA(3, 2, 2) },
                    { CDF3( 8738, 22209, 29673), PARA(3, 2, 2) },
                }, {
                    { CDF3( 9695, 22879, 26951), PARA(1, 2, 2) },
                    { CDF3( 1798, 15785, 27773), PARA(3, 2, 2) },
                }, {
                    { CDF3( 3427, 10282, 14127), PARA(3, 3, 3) },
                    { CDF3( 1687,  7815, 14031), PARA(3, 2, 3) },
                }, {
                    { CDF3(31560, 32315, 32617), PARA(0, 3, 2) },
                    { CDF3(12105, 31933, 32351), PARA(3, 2, 2) },
                }, {
                    { CDF3(20436, 29949, 32063), PARA(2, 2, 2) },
                    { CDF3( 6712, 28623, 32571), PARA(1, 2, 2) },
                }, {
                    { CDF3( 9717, 28135, 31186), PARA(2, 3, 2) },
                    { CDF3( 8249, 24519, 30362), PARA(1, 3, 2) },
                }, {
                    { CDF3( 7123, 25288, 28494), PARA(2, 0, 2) },
                    { CDF3(11556, 14880, 27228), PARA(2, 0, 2) },
                }, {
                    { CDF3( 4041, 10893, 15462), PARA(2, 1, 2) },
                    { CDF3(  794, 10029, 17278), PARA(2, 3, 3) },
                }, {
                    { CDF3(28664, 32744, 32748), PARA(2, 2, 2) },
                    { CDF3(31632, 32700, 32740), PARA(2, 3, 2) },
                }, {
                    { CDF3(26708, 32579, 32742), PARA(3, 2, 3) },
                    { CDF3( 6672, 31742, 32705), PARA(3, 3, 3) },
                }, {
                    { CDF3(20833, 31645, 32639), PARA(3, 3, 3) },
                    { CDF3( 1146, 29311, 32329), PARA(3, 3, 3) },
                }, {
                    { CDF3(13676, 28227, 31721), PARA(3, 3, 3) },
                    { CDF3( 1479, 24229, 30975), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5792, 15556, 21640), PARA(3, 3, 1) },
                    { CDF3( 1677, 10836, 19468), PARA(3, 3, 1) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            },
        }, .base_y_tok_lf = {
            {
                {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1828, 16851, 24012, 28649, 30422), PARA(1, 3, 3) },
                    { CDF5(    4,  8171, 22012, 28211, 30477), PARA(3, 2, 3) },
                }, {
                    { CDF5( 6923, 16016, 21706, 27149, 29436), PARA(2, 2, 3) },
                    { CDF5(    4,  7404, 16572, 22804, 28278), PARA(3, 1, 3) },
                }, {
                    { CDF5( 5490,  8820, 15814, 20244, 24021), PARA(3, 3, 0) },
                    { CDF5(    4,  5052, 13398, 18782, 23391), PARA(2, 2, 0) },
                }, {
                    { CDF5( 3032,  8030, 13087, 17462, 21741), PARA(2, 2, 2) },
                    { CDF5(    4,  4819, 10626, 13564, 18007), PARA(2, 3, 1) },
                }, {
                    { CDF5( 2261,  6418,  9159, 11973, 15591), PARA(3, 2, 3) },
                    { CDF5(    5,  3913,  9731, 12580, 13840), PARA(3, 3, 0) },
                }, {
                    { CDF5( 2300,  5287,  8547, 12143, 15837), PARA(3, 3, 2) },
                    { CDF5(    5,  2607,  6044,  8929, 11979), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1698,  5197,  8275, 11449, 12212), PARA(2, 3, 3) },
                    { CDF5(   49,  2125,  4169,  7345, 10592), PARA(2, 2, 2) },
                }, {
                    { CDF5(  588,  2906,  4192,  5998,  7090), PARA(3, 3, 3) },
                    { CDF5( 1289,  1297,  3318,  4626,  5829), PARA(3, 3, 3) },
                }, {
                    { CDF5(12754, 29010, 31539, 32136, 32523), PARA(3, 2, 2) },
                    { CDF5( 5740, 26647, 31969, 32459, 32732), PARA(2, 0, 2) },
                }, {
                    { CDF5( 7974, 23312, 28743, 31187, 32129), PARA(3, 2, 3) },
                    { CDF5(    4, 19122, 28115, 31351, 32328), PARA(3, 3, 2) },
                }, {
                    { CDF5( 6004, 17753, 25489, 28906, 30692), PARA(3, 2, 3) },
                    { CDF5(    4, 11476, 20286, 25973, 29118), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5318, 12906, 20831, 25848, 28911), PARA(3, 3, 3) },
                    { CDF5(    4,  8395, 15889, 22378, 27016), PARA(3, 3, 2) },
                }, {
                    { CDF5( 3337, 10161, 16413, 20903, 24729), PARA(3, 3, 3) },
                    { CDF5(    4,  6231, 13179, 19032, 23124), PARA(3, 2, 3) },
                }, {
                    { CDF5( 2632,  8256, 13389, 18349, 22057), PARA(3, 3, 3) },
                    { CDF5(    4,  5539, 10753, 15541, 19671), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1647,  4981,  8018, 10713, 12930), PARA(3, 2, 3) },
                    { CDF5(  133,  2595,  5758,  9172, 12046), PARA(3, 2, 3) },
                }, {
                    { CDF5(17458, 29871, 32000, 32546, 32702), PARA(3, 3, 3) },
                    { CDF5( 6925, 27088, 31750, 32368, 32706), PARA(3, 3, 3) },
                }, {
                    { CDF5(10512, 24503, 29646, 31529, 32218), PARA(3, 3, 3) },
                    { CDF5(  862, 17944, 27174, 30714, 32074), PARA(3, 3, 2) },
                }, {
                    { CDF5( 6509, 17436, 24062, 28298, 30439), PARA(3, 3, 3) },
                    { CDF5(  730, 11602, 20450, 26039, 29031), PARA(3, 3, 2) },
                }, {
                    { CDF5( 4334, 12843, 19639, 24807, 27809), PARA(3, 3, 2) },
                    { CDF5( 1182,  8304, 16062, 22058, 26408), PARA(3, 3, 3) },
                }, {
                    { CDF5( 2763,  7942, 12551, 16873, 20575), PARA(3, 3, 3) },
                    { CDF5(  588,  5113, 10255, 14725, 18439), PARA(3, 3, 3) },
                }, {
                    { CDF5(25261, 30274, 31401, 31859, 32108), PARA(2, 1, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11341, 22787, 27330, 29329, 30402), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7870, 16597, 22314, 26036, 27646), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9102, 15212, 19596, 22630, 24714), PARA(2, 1, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2627,  7584, 12537, 16148, 19228), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1773,  5159,  8384, 11582, 14326), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1281,  3306,  5564,  7730, 10025), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(28275, 32087, 32554, 32679, 32732), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(13124, 24281, 29249, 31039, 31932), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7252, 15503, 21990, 26021, 28329), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6766, 13251, 18520, 22234, 24944), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2022,  6282, 10559, 13831, 16913), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5( 8794, 30831, 31512, 32035, 32245), PARA(0, 0, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4155, 20109, 27969, 30536, 32143), PARA(2, 2, 2) },
                    { CDF5(    4, 10300, 22300, 28132, 30839), PARA(3, 2, 2) },
                }, {
                    { CDF5(13302, 23761, 27348, 29952, 31476), PARA(2, 2, 1) },
                    { CDF5(    4, 14590, 24086, 28071, 29718), PARA(2, 2, 1) },
                }, {
                    { CDF5( 6132, 14425, 20760, 25122, 27553), PARA(3, 2, 1) },
                    { CDF5(    4,  7592, 16048, 21694, 25655), PARA(3, 1, 1) },
                }, {
                    { CDF5( 3376, 10282, 14415, 19084, 23156), PARA(2, 2, 1) },
                    { CDF5(    4,  5986, 12540, 17467, 21046), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2339,  7935, 12252, 15518, 18022), PARA(3, 2, 2) },
                    { CDF5(    4,  4807,  8560, 13742, 17846), PARA(3, 3, 3) },
                }, {
                    { CDF5( 1008,  5061,  9267, 11938, 15655), PARA(3, 3, 1) },
                    { CDF5( 2687,  2712,  6941, 10360, 13721), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1067,  5070,  8639, 11287, 13789), PARA(3, 2, 2) },
                    { CDF5(    4,  3968,  5983,  9072, 11954), PARA(3, 3, 3) },
                }, {
                    { CDF5(  513,  3188,  4940,  6642,  8326), PARA(3, 3, 3) },
                    { CDF5( 1598,  1604,  3335,  5390,  7186), PARA(3, 3, 3) },
                }, {
                    { CDF5(18364, 30931, 32563, 32686, 32732), PARA(3, 2, 3) },
                    { CDF5(20105, 28028, 32148, 32696, 32722), PARA(3, 2, 1) },
                }, {
                    { CDF5(14335, 27700, 31502, 32326, 32673), PARA(2, 3, 3) },
                    { CDF5(    4, 23820, 30576, 32277, 32675), PARA(3, 2, 2) },
                }, {
                    { CDF5(13107, 25752, 29932, 31638, 32381), PARA(3, 2, 2) },
                    { CDF5(    4, 19582, 27260, 30379, 31695), PARA(3, 3, 2) },
                }, {
                    { CDF5( 6458, 17966, 24490, 28327, 30455), PARA(3, 3, 3) },
                    { CDF5(    4, 12996, 21614, 26979, 29871), PARA(3, 2, 3) },
                }, {
                    { CDF5( 4362, 12372, 18835, 23784, 27252), PARA(3, 3, 3) },
                    { CDF5(    4,  8398, 15799, 21724, 25631), PARA(3, 3, 2) },
                }, {
                    { CDF5( 3430, 10462, 16282, 20919, 24340), PARA(3, 2, 2) },
                    { CDF5(   30,  6110, 12299, 17850, 22504), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1926,  5825,  9243, 12462, 15052), PARA(3, 2, 3) },
                    { CDF5(   72,  3367,  7142, 10595, 13743), PARA(3, 2, 3) },
                }, {
                    { CDF5(24383, 32129, 32637, 32713, 32732), PARA(3, 3, 3) },
                    { CDF5( 9137, 30561, 32521, 32699, 32732), PARA(3, 3, 2) },
                }, {
                    { CDF5(17270, 29740, 32008, 32483, 32655), PARA(3, 3, 3) },
                    { CDF5(    8, 25977, 31428, 32465, 32657), PARA(3, 2, 2) },
                }, {
                    { CDF5(12268, 25877, 30422, 31961, 32485), PARA(3, 3, 2) },
                    { CDF5(   12, 20569, 28767, 31457, 32359), PARA(3, 3, 2) },
                }, {
                    { CDF5( 7294, 18995, 26081, 29672, 31452), PARA(3, 3, 3) },
                    { CDF5(  181, 14139, 23494, 28458, 30918), PARA(3, 3, 3) },
                }, {
                    { CDF5( 3440,  9808, 15386, 19904, 23390), PARA(3, 3, 3) },
                    { CDF5(  139,  6455, 12703, 17797, 21832), PARA(3, 3, 2) },
                }, {
                    { CDF5(28752, 31869, 32320, 32478, 32572), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(15670, 27564, 30368, 31493, 31993), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9799, 20178, 25558, 28413, 30046), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9356, 16500, 21207, 24352, 26419), PARA(2, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2981,  9131, 14182, 18343, 21454), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2154,  6775, 11531, 15084, 18264), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1257,  3940,  6890,  9699, 12030), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(30668, 32581, 32693, 32736, 32740), PARA(2, 1, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(18504, 29402, 31702, 32283, 32519), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(10766, 22532, 27978, 30115, 31262), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 8719, 18462, 24428, 27561, 29580), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3879, 10481, 15972, 19633, 22761), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(18644, 30427, 32255, 32544, 32664), PARA(1, 0, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4549, 25234, 29518, 31595, 31998), PARA(2, 2, 1) },
                    { CDF5(    4, 12584, 25285, 29517, 31566), PARA(3, 2, 1) },
                }, {
                    { CDF5(12259, 24561, 28578, 30638, 31755), PARA(3, 1, 2) },
                    { CDF5(    4, 18211, 26628, 30288, 31028), PARA(1, 2, 2) },
                }, {
                    { CDF5( 5548, 13583, 19991, 25062, 27790), PARA(2, 3, 2) },
                    { CDF5(    4,  8981, 17065, 22847, 26409), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2511,  8771, 13709, 18515, 21631), PARA(3, 3, 2) },
                    { CDF5(    4,  6091, 12402, 16401, 21384), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1456,  6940, 12018, 15507, 18576), PARA(2, 3, 2) },
                    { CDF5( 3828,  4004,  7860, 12305, 16184), PARA(3, 3, 1) },
                }, {
                    { CDF5( 1456,  5488,  8386, 12251, 14583), PARA(3, 3, 2) },
                    { CDF5(    5,  3667,  7540, 10600, 13938), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2172,  4278,  6935, 10386, 13380), PARA(3, 3, 3) },
                    { CDF5(    6,  2661,  6993,  9316, 12044), PARA(3, 3, 2) },
                }, {
                    { CDF5(  854,  2756,  4422,  6402,  8143), PARA(3, 2, 2) },
                    { CDF5(    4,  1978,  3940,  6072,  7460), PARA(3, 3, 3) },
                }, {
                    { CDF5(27597, 32474, 32665, 32730, 32734), PARA(2, 3, 1) },
                    { CDF5(24628, 29500, 31920, 32665, 32732), PARA(2, 2, 0) },
                }, {
                    { CDF5(16858, 28844, 31500, 32377, 32690), PARA(3, 3, 2) },
                    { CDF5(    4, 27050, 31611, 32598, 32708), PARA(2, 2, 1) },
                }, {
                    { CDF5(17412, 28372, 31092, 32127, 32538), PARA(3, 2, 2) },
                    { CDF5(    4, 23035, 29401, 31561, 32362), PARA(2, 2, 1) },
                }, {
                    { CDF5( 6754, 18144, 24912, 28603, 30596), PARA(3, 2, 2) },
                    { CDF5(    4, 15859, 24392, 28503, 30570), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4015, 12511, 19603, 24562, 27900), PARA(3, 1, 2) },
                    { CDF5(    4,  9194, 17016, 22337, 26137), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3458, 10380, 16144, 21113, 24683), PARA(3, 3, 2) },
                    { CDF5(    5,  6767, 13223, 18657, 22519), PARA(2, 3, 2) },
                }, {
                    { CDF5( 1682,  5432,  8769, 12173, 14844), PARA(3, 3, 3) },
                    { CDF5(    7,  3903,  7423, 10655, 13533), PARA(3, 3, 3) },
                }, {
                    { CDF5(28336, 32620, 32715, 32736, 32740), PARA(3, 1, 2) },
                    { CDF5( 9058, 31414, 32677, 32736, 32740), PARA(2, 2, 2) },
                }, {
                    { CDF5(23033, 31648, 32521, 32700, 32732), PARA(3, 2, 2) },
                    { CDF5(   75, 29218, 32255, 32646, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(17992, 29745, 32048, 32579, 32724), PARA(3, 2, 2) },
                    { CDF5(   95, 26324, 31408, 32426, 32663), PARA(3, 3, 2) },
                }, {
                    { CDF5( 9671, 22972, 28881, 31303, 32233), PARA(3, 3, 3) },
                    { CDF5(  132, 18991, 27475, 30900, 32140), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3245, 10146, 15682, 20055, 23306), PARA(3, 3, 2) },
                    { CDF5(  715,  6956, 13155, 18158, 21881), PARA(3, 2, 3) },
                }, {
                    { CDF5(30282, 32463, 32643, 32689, 32720), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(18363, 29970, 31740, 32329, 32529), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11103, 21929, 26883, 29338, 30615), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(10010, 15981, 20125, 22717, 24545), PARA(1, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2197,  6613, 12544, 16341, 19413), PARA(1, 1, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(  977,  5129,  8874, 12334, 16079), PARA(2, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1326,  3745,  5773,  7906, 10325), PARA(1, 0, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(31687, 32702, 32738, 32742, 32746), PARA(2, 1, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(23101, 31425, 32294, 32485, 32560), PARA(3, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(14043, 26486, 29937, 30917, 31636), PARA(2, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11590, 21553, 26089, 28623, 29781), PARA(1, 1, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3345,  9687, 15060, 19237, 21946), PARA(1, 1, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(17981, 30263, 31343, 31835, 32228), PARA(0, 2, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(  541, 19909, 25694, 31571, 32707), PARA(0, 1, 1) },
                    { CDF5(    5,  3008, 18509, 26661, 30500), PARA(2, 1, 1) },
                }, {
                    { CDF5( 6280, 16644, 22197, 27386, 30311), PARA(1, 1, 1) },
                    { CDF5( 3289,  9702, 18719, 20867, 24166), PARA(1, 3, 0) },
                }, {
                    { CDF5( 2433,  8354, 15330, 20115, 23238), PARA(2, 2, 0) },
                    { CDF5(   21,  9300, 13157, 16064, 22107), PARA(2, 1, 0) },
                }, {
                    { CDF5( 3059,  5529, 10689, 14670, 16660), PARA(3, 0, 0) },
                    { CDF5(   36,  4415,  9690, 12203, 15756), PARA(2, 0, 2) },
                }, {
                    { CDF5( 2528,  7188, 10559, 12046, 15715), PARA(3, 3, 2) },
                    { CDF5(  228,  1917,  4701,  8762, 12870), PARA(2, 3, 0) },
                }, {
                    { CDF5( 1318,  4984,  6874, 11801, 12832), PARA(3, 0, 2) },
                    { CDF5(  772,  1543,  4630,  8014, 10032), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1741,  4692,  6205,  8476, 10822), PARA(3, 0, 2) },
                    { CDF5(  287,  1649,  4446,  6812,  8891), PARA(2, 0, 2) },
                }, {
                    { CDF5(  819,  2068,  3940,  5617,  6164), PARA(3, 3, 3) },
                    { CDF5(   20,  1444,  2749,  3441,  5300), PARA(3, 3, 0) },
                }, {
                    { CDF5(22627, 30107, 31954, 32695, 32732), PARA(2, 1, 1) },
                    { CDF5( 9634, 23470, 31648, 32544, 32656), PARA(1, 3, 2) },
                }, {
                    { CDF5(14808, 27300, 31048, 32355, 32547), PARA(1, 1, 1) },
                    { CDF5(    4, 26706, 31394, 32590, 32717), PARA(2, 3, 1) },
                }, {
                    { CDF5(14111, 25840, 29676, 31196, 32100), PARA(2, 2, 0) },
                    { CDF5( 2240, 18421, 26730, 29569, 30965), PARA(2, 1, 2) },
                }, {
                    { CDF5( 3320, 16652, 23243, 27800, 29610), PARA(2, 1, 1) },
                    { CDF5( 3241, 11944, 18304, 22700, 26752), PARA(2, 2, 3) },
                }, {
                    { CDF5( 2775, 10402, 16795, 21420, 24155), PARA(3, 1, 0) },
                    { CDF5(   42,  7547, 13763, 18308, 22325), PARA(3, 1, 3) },
                }, {
                    { CDF5( 1526,  9483, 15296, 20232, 22733), PARA(2, 1, 0) },
                    { CDF5( 3770,  6135, 11174, 17138, 20531), PARA(3, 3, 3) },
                }, {
                    { CDF5( 1566,  4208,  7493,  9981, 11307), PARA(3, 2, 2) },
                    { CDF5(   10,  2707,  5347,  8016, 11209), PARA(3, 3, 1) },
                }, {
                    { CDF5(29051, 32611, 32732, 32736, 32740), PARA(3, 1, 1) },
                    { CDF5(11740, 31606, 32673, 32736, 32740), PARA(2, 3, 2) },
                }, {
                    { CDF5(23082, 31405, 32517, 32736, 32740), PARA(2, 3, 2) },
                    { CDF5( 1955, 29285, 32394, 32685, 32732), PARA(2, 3, 2) },
                }, {
                    { CDF5(16727, 28474, 31461, 32407, 32710), PARA(3, 2, 2) },
                    { CDF5( 1043, 24584, 30321, 31899, 32456), PARA(3, 2, 2) },
                }, {
                    { CDF5( 7685, 20689, 27553, 30514, 31627), PARA(3, 3, 2) },
                    { CDF5(  312, 15641, 24900, 29282, 31344), PARA(3, 2, 3) },
                }, {
                    { CDF5( 2935,  8636, 13745, 17661, 20515), PARA(3, 2, 1) },
                    { CDF5(   22,  6005, 11121, 15180, 18215), PARA(3, 1, 1) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(  607,  3034,  7889, 15777, 23666), PARA(3, 2, 2) },
                    { CDF5(  546,  1092,  5461,  8738, 19661), PARA(3, 2, 2) },
                }, {
                    { CDF5(  482,  9638, 11083, 11565, 13493), PARA(3, 2, 2) },
                    { CDF5(  840,  2101,  3781, 12603, 16384), PARA(0, 2, 2) },
                }, {
                    { CDF5(  273,  7646,  7919, 10377, 13653), PARA(0, 2, 2) },
                    { CDF5(  390,   975,  1560, 11703, 15409), PARA(0, 2, 2) },
                }, {
                    { CDF5(  819,  1365,  2185,  5734,  6554), PARA(0, 2, 2) },
                    { CDF5(  356,   534,   890,  1603,  7480), PARA(0, 2, 2) },
                }, {
                    { CDF5(  426,  2128,  4256,  5532,  6383), PARA(0, 2, 2) },
                    { CDF5(  226,   452,  1130,  3390,  4520), PARA(0, 2, 2) },
                }, {
                    { CDF5(  936,  2185,  3433,  4057,  5305), PARA(2, 2, 2) },
                    { CDF5(  213,   426,   851,  1702,  1915), PARA(0, 2, 2) },
                }, {
                    { CDF5( 1130,  6780, 11299, 13559, 15819), PARA(2, 2, 2) },
                    { CDF5(  840,  1260,  1680,  2521,  3361), PARA(0, 2, 2) },
                }, {
                    { CDF5(  840,  2521,  2941,  3781,  6722), PARA(3, 2, 2) },
                    { CDF5(  607,   910,  1820,  2427,  2731), PARA(1, 2, 2) },
                }, {
                    { CDF5( 2760,  9884, 19144, 26446, 28761), PARA(3, 2, 2) },
                    { CDF5( 6378,  8797, 14295, 25731, 30349), PARA(0, 2, 2) },
                }, {
                    { CDF5( 1022,  5182, 10071, 14523, 20142), PARA(2, 0, 2) },
                    { CDF5( 1625,  5578, 14671, 19283, 23851), PARA(1, 3, 2) },
                }, {
                    { CDF5( 1493, 14043, 16621, 19742, 20896), PARA(1, 3, 2) },
                    { CDF5(   79,  5792, 10632, 14519, 17217), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1896,  5958, 11645, 14353, 16249), PARA(2, 2, 2) },
                    { CDF5(  973,  3244,  6164,  8111, 11031), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2777,  4999,  8331, 10552, 13329), PARA(3, 2, 2) },
                    { CDF5(  799,  2398,  5195,  7593, 11189), PARA(1, 2, 2) },
                }, {
                    { CDF5( 1771,  5314,  8856, 12399, 15056), PARA(3, 2, 2) },
                    { CDF5( 2048,  6144, 14336, 16384, 18432), PARA(0, 2, 2) },
                }, {
                    { CDF5(  509,  3735,  7980, 10017, 11715), PARA(3, 2, 2) },
                    { CDF5(  537,  2149,  5551,  6088,  8416), PARA(3, 2, 2) },
                }, {
                    { CDF5(24857, 32089, 32690, 32716, 32732), PARA(2, 2, 2) },
                    { CDF5(10411, 28445, 32559, 32722, 32732), PARA(2, 3, 3) },
                }, {
                    { CDF5(15845, 30289, 32552, 32660, 32732), PARA(1, 3, 2) },
                    { CDF5( 7773, 29346, 31862, 32519, 32732), PARA(1, 3, 2) },
                }, {
                    { CDF5( 9766, 24287, 28720, 30969, 32382), PARA(3, 1, 0) },
                    { CDF5(  585, 20320, 29044, 32023, 32449), PARA(1, 2, 3) },
                }, {
                    { CDF5( 7627, 18644, 24717, 29519, 31779), PARA(2, 2, 2) },
                    { CDF5( 2718, 15100, 26426, 29748, 31560), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2451,  8257, 11869, 16556, 19523), PARA(2, 0, 0) },
                    { CDF5(  256,  4651, 10581, 13824, 16341), PARA(3, 3, 0) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            },
        }, .dc_sign = {
            {
                { CDF1(15831), PARA(3, 3, 3) },
                { CDF1(13632), PARA(3, 2, 2) },
                { CDF1(19041), PARA(3, 2, 2) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }
        }, .br_y_tok_hf = {
            { CDF3(22305, 28743, 30345), PARA(2, 1, 1) },
            { CDF3(22663, 29948, 31320), PARA(3, 2, 3) },
            { CDF3(19776, 28658, 30435), PARA(3, 2, 3) },
            { CDF3(15436, 25313, 28181), PARA(3, 2, 3) },
            { CDF3(11214, 20671, 24854), PARA(3, 2, 3) },
            { CDF3( 8548, 16982, 21766), PARA(3, 2, 3) },
            { CDF3( 5729, 11993, 17176), PARA(3, 2, 3) },
        }, .br_y_tok_lf = {
            { CDF3( 7943, 14193, 20775), PARA(1, 1, 0) },
            { CDF3(14297, 22400, 26238), PARA(3, 3, 1) },
            { CDF3(10557, 18683, 22550), PARA(3, 3, 2) },
            { CDF3( 8289, 16068, 18454), PARA(3, 3, 0) },
            { CDF3( 5258, 10730, 13709), PARA(3, 3, 2) },
            { CDF3( 3933,  8166, 10680), PARA(3, 3, 2) },
            { CDF3( 2465,  5325,  6625), PARA(3, 3, 2) },
            { CDF3(10865, 16430, 19691), PARA(2, 1, 1) },
            { CDF3(14571, 22733, 26106), PARA(2, 3, 2) },
            { CDF3(14072, 23021, 25971), PARA(3, 2, 2) },
            { CDF3(11558, 20253, 23235), PARA(3, 2, 3) },
            { CDF3( 8603, 16200, 19466), PARA(3, 3, 3) },
            { CDF3( 6641, 13086, 16612), PARA(3, 2, 3) },
            { CDF3( 4240,  9043, 11946), PARA(3, 3, 3) },
        }, .ph_dc_y_tok = {
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
        }, .bob_base_y_tok = {
            {
                { CDF2( 9917, 17060), PARA(3, 3, 2) },
                { CDF2(13841, 21928), PARA(3, 3, 1) },
                { CDF2(11228, 19107), PARA(3, 3, 2) },
            }, {
                { CDF2(11194, 18097), PARA(2, 3, 2) },
                { CDF2(13829, 21552), PARA(3, 3, 1) },
                { CDF2(15625, 22723), PARA(2, 2, 1) },
            }, {
                { CDF2(10164, 15059), PARA(2, 2, 1) },
                { CDF2(11087, 15990), PARA(2, 2, 2) },
                { CDF2(12184, 18484), PARA(1, 1, 1) },
            },
        }, .br_y_tok_idtx = {
            {
                { CDF3(10358, 16536, 21006), PARA(2, 3, 2) },
                { CDF3(10820, 18219, 22881), PARA(3, 3, 1) },
                { CDF3(10100, 15687, 20193), PARA(3, 2, 2) },
                { CDF3(10388, 15552, 19869), PARA(3, 2, 2) },
                { CDF3( 7467, 14671, 18379), PARA(3, 3, 2) },
                { CDF3( 5068,  8607, 12235), PARA(2, 3, 2) },
                { CDF3( 3545,  6569,  9269), PARA(3, 3, 3) },
            }, {
                { CDF3(10846, 17226, 21443), PARA(2, 2, 2) },
                { CDF3(13398, 20355, 24290), PARA(2, 3, 2) },
                { CDF3(11910, 18796, 23075), PARA(2, 2, 1) },
                { CDF3(12559, 18882, 23077), PARA(3, 2, 1) },
                { CDF3( 8733, 17495, 21561), PARA(3, 3, 2) },
                { CDF3( 4080,  7646, 11249), PARA(2, 1, 2) },
                { CDF3( 3404,  6120,  8842), PARA(3, 2, 2) },
            }, {
                { CDF3( 7328, 12456, 16707), PARA(3, 3, 1) },
                { CDF3( 8772, 14457, 18914), PARA(2, 2, 0) },
                { CDF3( 8195, 13709, 17968), PARA(2, 2, 0) },
                { CDF3(10966, 15804, 19497), PARA(2, 1, 0) },
                { CDF3( 5374, 13909, 17992), PARA(2, 1, 0) },
                { CDF3( 2314,  4570,  7480), PARA(1, 1, 1) },
                { CDF3( 1645,  3387,  5133), PARA(3, 2, 1) },
            },
        }, .base_y_tok_idtx = {
            {
                { CDF3(28343, 29890, 30977), PARA(3, 3, 3) },
                { CDF3(20601, 26193, 28764), PARA(3, 3, 3) },
                { CDF3(19490, 23791, 27048), PARA(3, 2, 2) },
                { CDF3(16423, 19493, 22007), PARA(3, 2, 3) },
                { CDF3(12176, 17688, 21070), PARA(2, 2, 1) },
                { CDF3(11254, 15066, 18960), PARA(2, 2, 1) },
                { CDF3( 7135,  9594, 11748), PARA(2, 2, 1) },
            }, {
                { CDF3(30897, 31794, 32178), PARA(3, 3, 3) },
                { CDF3(20986, 28222, 30421), PARA(2, 3, 2) },
                { CDF3(18659, 24176, 27934), PARA(2, 2, 2) },
                { CDF3(15633, 18666, 21224), PARA(2, 2, 3) },
                { CDF3( 9693, 15878, 20636), PARA(2, 2, 1) },
                { CDF3(10083, 14089, 18515), PARA(2, 1, 1) },
                { CDF3( 6265,  8352, 10523), PARA(2, 2, 1) },
            }, {
                { CDF3(32379, 32564, 32633), PARA(3, 2, 2) },
                { CDF3(22177, 29474, 30765), PARA(2, 2, 1) },
                { CDF3(18538, 23452, 26801), PARA(2, 2, 1) },
                { CDF3(14706, 16590, 18239), PARA(3, 2, 2) },
                { CDF3( 6954, 12300, 15663), PARA(2, 1, 0) },
                { CDF3( 5210,  7282, 11087), PARA(2, 1, 1) },
                { CDF3( 2614,  3781,  4955), PARA(3, 2, 2) },
            },
        }, .sign_idtx = {
            {
                { CDF1(15560), PARA(3, 3, 3) },
                { CDF1(24775), PARA(3, 3, 3) },
                { CDF1( 7540), PARA(3, 3, 3) },
                { CDF1(27844), PARA(2, 2, 2) },
                { CDF1( 3545), PARA(3, 2, 2) },
                { CDF1(28880), PARA(3, 1, 0) },
                { CDF1( 4886), PARA(3, 1, 2) },
                { CDF1(32178), PARA(2, 1, 1) },
                { CDF1( 1204), PARA(3, 2, 2) },
            }, {
                { CDF1(14810), PARA(2, 2, 3) },
                { CDF1(26650), PARA(3, 2, 2) },
                { CDF1( 5063), PARA(3, 3, 2) },
                { CDF1(29212), PARA(2, 3, 2) },
                { CDF1( 1994), PARA(3, 2, 3) },
                { CDF1(29106), PARA(3, 3, 2) },
                { CDF1( 3267), PARA(3, 3, 2) },
                { CDF1(32118), PARA(2, 2, 2) },
                { CDF1(  537), PARA(3, 3, 3) },
            }, {
                { CDF1(11533), PARA(1, 1, 1) },
                { CDF1(28709), PARA(3, 2, 1) },
                { CDF1( 2095), PARA(3, 3, 2) },
                { CDF1(31598), PARA(3, 3, 2) },
                { CDF1(  331), PARA(3, 3, 3) },
                { CDF1(31760), PARA(3, 3, 1) },
                { CDF1(  319), PARA(3, 2, 3) },
                { CDF1(32511), PARA(3, 2, 3) },
                { CDF1(   60), PARA(1, 3, 3) },
            },
        }, .skip_v = {
            { CDF1( 1439), PARA(3, 2, 3) },
            { CDF1( 6191), PARA(2, 2, 2) },
            { CDF1(14610), PARA(2, 2, 1) },
            { CDF1(  180), PARA(0, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1( 7648), PARA(3, 3, 2) },
            { CDF1(16148), PARA(3, 3, 2) },
            { CDF1(24565), PARA(3, 3, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
        }, .eob_base_uv_tok_hf = {
            { CDF2(31214, 32437), PARA(3, 3, 3) },
            { CDF2(31888, 32447), PARA(3, 2, 3) },
            { CDF2(30612, 32073), PARA(3, 3, 3) },
        }, .base_uv_tok_hf = {
            { CDF3(26904, 32102, 32598), PARA(2, 2, 2) },
            { CDF3(15749, 28898, 31610), PARA(3, 3, 2) },
            { CDF3( 9106, 21329, 26962), PARA(3, 3, 2) },
            { CDF3( 4828, 12923, 18983), PARA(3, 2, 2) },
            { CDF3(27779, 32406, 32689), PARA(3, 3, 2) },
            { CDF3(17414, 30077, 32025), PARA(3, 3, 2) },
            { CDF3( 9228, 22296, 27767), PARA(3, 1, 1) },
            { CDF3( 4564, 12734, 19144), PARA(3, 3, 2) },
            { CDF3(29238, 32489, 32693), PARA(3, 1, 2) },
            { CDF3(19819, 30853, 32222), PARA(1, 2, 2) },
            { CDF3( 9314, 19318, 25346), PARA(2, 1, 1) },
            { CDF3( 3060, 10265, 16088), PARA(2, 1, 2) },
        }, .br_uv_tok_hf = {
            { CDF3(20014, 26541, 29552), PARA(2, 1, 0) },
            { CDF3(20674, 27680, 30329), PARA(3, 2, 3) },
            { CDF3(16228, 24293, 28314), PARA(3, 2, 2) },
            { CDF3( 9580, 16283, 20959), PARA(3, 2, 2) },
        }, .eob_base_uv_tok_lf = {
            { CDF4(28950, 31443, 32009, 32257), PARA(3, 2, 2) },
            { CDF4(29916, 31919, 32224, 32441), PARA(2, 1, 1) },
            { CDF4(28902, 30805, 31579, 31816), PARA(2, 2, 0) },
        }, .base_uv_tok_lf = {
            { CDF5(14076, 26464, 29938, 31308, 31828), PARA(2, 1, 1) },
            { CDF5( 7520, 21227, 27766, 30312, 31477), PARA(3, 2, 2) },
            { CDF5( 4377, 13290, 19811, 24220, 27064), PARA(3, 3, 2) },
            { CDF5( 1682,  5139,  8601, 11973, 15046), PARA(3, 3, 2) },
            { CDF5(15235, 28605, 31367, 32151, 32451), PARA(2, 1, 1) },
            { CDF5(10256, 24586, 29775, 31465, 32137), PARA(3, 3, 3) },
            { CDF5( 5918, 15629, 22317, 26602, 29101), PARA(3, 3, 2) },
            { CDF5( 2015,  5704,  9835, 13705, 17299), PARA(3, 2, 1) },
            { CDF5(26420, 31955, 32312, 32430, 32526), PARA(3, 2, 2) },
            { CDF5(16374, 29560, 31531, 32023, 32291), PARA(1, 1, 2) },
            { CDF5( 7197, 15954, 20986, 24934, 27737), PARA(2, 1, 1) },
            { CDF5( 4820,  9488, 11701, 14065, 16248), PARA(2, 0, 1) },
        }
    }, [1] = {
        .skip = {
            {
                {
                    { CDF1(30296), PARA(2, 1, 2) },
                    { CDF1( 2871), PARA(3, 2, 2) },
                    { CDF1( 5650), PARA(3, 2, 1) },
                    { CDF1(13405), PARA(1, 2, 1) },
                    { CDF1(19531), PARA(2, 2, 1) },
                    { CDF1(30186), PARA(2, 1, 2) },
                    { CDF1( 8778), PARA(1, 1, 1) },
                    { CDF1(17506), PARA(2, 2, 2) },
                    { CDF1(26467), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(31530), PARA(1, 1, 2) },
                    { CDF1( 2361), PARA(3, 2, 3) },
                    { CDF1( 4301), PARA(3, 2, 2) },
                    { CDF1(14660), PARA(1, 1, 1) },
                    { CDF1(19138), PARA(2, 1, 1) },
                    { CDF1(31475), PARA(2, 1, 2) },
                    { CDF1( 5031), PARA(2, 2, 2) },
                    { CDF1(16054), PARA(1, 1, 1) },
                    { CDF1(27047), PARA(2, 1, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(31362), PARA(1, 2, 2) },
                    { CDF1( 2991), PARA(3, 2, 2) },
                    { CDF1( 6803), PARA(2, 2, 1) },
                    { CDF1(19942), PARA(1, 1, 0) },
                    { CDF1(22017), PARA(2, 1, 1) },
                    { CDF1(32325), PARA(2, 1, 2) },
                    { CDF1( 5502), PARA(2, 2, 2) },
                    { CDF1(17059), PARA(1, 1, 1) },
                    { CDF1(27657), PARA(1, 1, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(27230), PARA(0, 0, 0) },
                    { CDF1(  604), PARA(3, 1, 2) },
                    { CDF1( 4108), PARA(2, 2, 2) },
                    { CDF1(15740), PARA(0, 0, 0) },
                    { CDF1(18869), PARA(1, 2, 0) },
                    { CDF1(32126), PARA(1, 1, 0) },
                    { CDF1( 4208), PARA(1, 1, 1) },
                    { CDF1(18962), PARA(1, 1, 0) },
                    { CDF1(28315), PARA(1, 1, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(23062), PARA(0, 0, 0) },
                    { CDF1(  740), PARA(1, 1, 3) },
                    { CDF1( 9511), PARA(1, 3, 0) },
                    { CDF1(22294), PARA(0, 0, 0) },
                    { CDF1(21507), PARA(3, 3, 3) },
                    { CDF1(31946), PARA(0, 1, 0) },
                    { CDF1( 2406), PARA(0, 0, 0) },
                    { CDF1(18145), PARA(1, 1, 1) },
                    { CDF1(24883), PARA(1, 1, 3) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF1(32764), PARA(2, 2, 2) },
                    { CDF1(10589), PARA(3, 3, 1) },
                    { CDF1(17200), PARA(2, 1, 0) },
                    { CDF1(20721), PARA(2, 2, 1) },
                    { CDF1(23311), PARA(2, 1, 1) },
                    { CDF1(28906), PARA(2, 1, 2) },
                    { CDF1( 4037), PARA(1, 2, 1) },
                    { CDF1(14946), PARA(1, 2, 1) },
                    { CDF1(24129), PARA(2, 2, 2) },
                    { CDF1(32128), PARA(3, 2, 3) },
                }, {
                    { CDF1(32577), PARA(1, 1, 1) },
                    { CDF1(13622), PARA(3, 3, 3) },
                    { CDF1(16203), PARA(3, 3, 2) },
                    { CDF1(19412), PARA(3, 3, 2) },
                    { CDF1(23766), PARA(3, 2, 2) },
                    { CDF1(29589), PARA(2, 2, 3) },
                    { CDF1( 2774), PARA(1, 2, 1) },
                    { CDF1(14855), PARA(1, 2, 1) },
                    { CDF1(24976), PARA(2, 2, 2) },
                    { CDF1(31738), PARA(3, 2, 2) },
                }, {
                    { CDF1(32415), PARA(0, 0, 0) },
                    { CDF1(15422), PARA(3, 3, 3) },
                    { CDF1(18741), PARA(3, 3, 1) },
                    { CDF1(20940), PARA(3, 2, 2) },
                    { CDF1(25667), PARA(3, 2, 1) },
                    { CDF1(31116), PARA(2, 2, 2) },
                    { CDF1( 3281), PARA(1, 1, 1) },
                    { CDF1(17757), PARA(1, 1, 1) },
                    { CDF1(27707), PARA(2, 2, 1) },
                    { CDF1(29599), PARA(2, 1, 0) },
                }, {
                    { CDF1(32182), PARA(0, 0, 0) },
                    { CDF1(13890), PARA(3, 3, 2) },
                    { CDF1(17539), PARA(2, 3, 3) },
                    { CDF1(21145), PARA(2, 3, 2) },
                    { CDF1(26833), PARA(3, 3, 3) },
                    { CDF1(31582), PARA(2, 2, 1) },
                    { CDF1( 4193), PARA(1, 2, 0) },
                    { CDF1(21696), PARA(1, 1, 0) },
                    { CDF1(29128), PARA(2, 1, 1) },
                    { CDF1(26841), PARA(0, 0, 0) },
                }, {
                    { CDF1(31681), PARA(0, 0, 0) },
                    { CDF1( 9846), PARA(1, 1, 0) },
                    { CDF1(21469), PARA(1, 1, 0) },
                    { CDF1(24254), PARA(2, 1, 0) },
                    { CDF1(29068), PARA(3, 3, 0) },
                    { CDF1(31736), PARA(1, 1, 0) },
                    { CDF1( 8875), PARA(0, 0, 0) },
                    { CDF1(25927), PARA(0, 0, 2) },
                    { CDF1(29086), PARA(0, 0, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            },
        }, .eob_bin_16 = {
            { CDF4( 1839,  2995,  6796, 15126), PARA(1, 1, 2) },
            { CDF4( 1354,  1787,  4813,  9327), PARA(1, 1, 2) },
            { CDF4( 8298, 11869, 17297, 24569), PARA(1, 1, 2) },
        }, .eob_bin_32 = {
            { CDF5( 1143,  1778,  3854,  8166, 13337), PARA(1, 1, 1) },
            { CDF5( 1109,  1433,  2804,  5652, 11224), PARA(1, 1, 1) },
            { CDF5( 8685, 11412, 16486, 22345, 27930), PARA(1, 1, 1) },
        }, .eob_bin_64 = {
            { CDF6(  939,  1381,  3142,  6536, 13617, 21799), PARA(1, 1, 1) },
            { CDF6( 1338,  1662,  2777,  5268,  9184, 15736), PARA(1, 1, 1) },
            { CDF6( 9398, 11810, 17045, 22537, 27448, 30795), PARA(1, 1, 1) },
        }, .eob_bin_128 = {
            { CDF7(  654,  1068,  2257,  5580, 12362, 21455, 26067), PARA(1, 1, 0) },
            { CDF7( 1852,  2243,  3554,  5549,  9085, 14604, 21559), PARA(1, 1, 0) },
            { CDF7( 9713, 12146, 17484, 22818, 27372, 30388, 31811), PARA(1, 1, 1) },
        }, .eob_bin_256 = {
            { CDF7(  790,  1184,  2218,  5022, 11432, 20289, 23689), PARA(0, 1, 0) },
            { CDF7( 2998,  3363,  4528,  6371,  9250, 13525, 18730), PARA(1, 1, 0) },
            { CDF7( 9611, 12008, 17284, 22532, 26744, 29711, 31730), PARA(1, 1, 1) },
        }, .eob_bin_512 = {
            { CDF7( 1311,  2019,  3578,  6876, 13781, 23541, 24922), PARA(0, 0, 0) },
            { CDF7( 5415,  5926,  7647, 10113, 13081, 17084, 20509), PARA(0, 1, 0) },
            { CDF7( 9906, 12482, 17574, 22657, 27655, 30234, 31821), PARA(1, 1, 0) },
        }, .eob_bin_1024 = {
            { CDF7(  634,  1777,  3873,  6293, 12653, 23825, 24712), PARA(0, 1, 0) },
            { CDF7( 4894,  5819,  8219, 11022, 14406, 18919, 21479), PARA(0, 1, 0) },
            { CDF7( 9216, 12549, 17630, 21723, 25862, 28760, 30440), PARA(1, 0, 0) },
        }, .eob_hi_bit = {
            CDF1(18326), PARA(2, 2, 2)
        }, .eob_base_y_tok_hf = {
            {
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(26028, 30728), PARA(2, 2, 3) },
            }, {
                { CDF2(31077, 32105), PARA(3, 0, 2) },
                { CDF2(31889, 32651), PARA(3, 3, 3) },
                { CDF2(31276, 32538), PARA(3, 3, 3) },
            }, {
                { CDF2(32624, 32752), PARA(3, 3, 3) },
                { CDF2(32688, 32756), PARA(3, 3, 3) },
                { CDF2(32695, 32756), PARA(3, 3, 3) },
            }, {
                { CDF2(32677, 32743), PARA(0, 3, 3) },
                { CDF2(32051, 32739), PARA(2, 1, 0) },
                { CDF2(32291, 32748), PARA(1, 1, 0) },
            }, {
                { CDF2(32710, 32756), PARA(3, 2, 3) },
                { CDF2(32700, 32756), PARA(2, 0, 3) },
                { CDF2(24989, 32282), PARA(0, 0, 0) },
            }
        }, .eob_base_y_tok_lf = {
            {
                { CDF4(28595, 31926, 32420, 32582), PARA(3, 3, 1) },
                { CDF4(28506, 31820, 32509, 32686), PARA(2, 2, 2) },
                { CDF4(28680, 31966, 32503, 32626), PARA(2, 2, 2) },
                { CDF4(27591, 32110, 32578, 32712), PARA(3, 2, 2) },
            }, {
                { CDF4(28550, 32010, 32465, 32593), PARA(2, 2, 1) },
                { CDF4(31254, 32502, 32660, 32713), PARA(3, 2, 2) },
                { CDF4(31600, 32549, 32688, 32735), PARA(3, 2, 2) },
                { CDF4(31747, 32600, 32712, 32740), PARA(3, 2, 3) },
            }, {
                { CDF4(27239, 31085, 31883, 32247), PARA(2, 1, 0) },
                { CDF4(31836, 32524, 32640, 32686), PARA(2, 2, 2) },
                { CDF4(32293, 32547, 32627, 32711), PARA(1, 3, 3) },
                { CDF4(24966, 28087, 29127, 31988), PARA(0, 2, 2) },
            }, {
                { CDF4(22871, 30729, 31682, 32000), PARA(1, 0, 0) },
                { CDF4(32054, 32674, 32735, 32740), PARA(3, 3, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            }, {
                { CDF4( 7975, 22586, 27023, 29960), PARA(0, 0, 0) },
                { CDF4(31368, 32346, 32628, 32738), PARA(2, 1, 1) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            },
        }, .base_y_tok_hf = {
            {
                {
                    { CDF3(12507, 26077, 30060), PARA(1, 1, 2) },
                    { CDF3( 7550, 25098, 30550), PARA(1, 1, 2) },
                }, {
                    { CDF3( 8009, 20715, 27321), PARA(2, 2, 3) },
                    { CDF3( 3223, 17464, 26650), PARA(2, 2, 3) },
                }, {
                    { CDF3( 4305, 13150, 20144), PARA(3, 3, 3) },
                    { CDF3( 1952, 10128, 18324), PARA(2, 2, 3) },
                }, {
                    { CDF3( 3098,  9586, 15580), PARA(3, 3, 3) },
                    { CDF3( 1089,  7195, 13810), PARA(3, 3, 3) },
                }, {
                    { CDF3( 1728,  6104, 10373), PARA(3, 3, 3) },
                    { CDF3( 1235,  4736,  9683), PARA(3, 3, 3) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(27562, 31970, 32298), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(11965, 23262, 28482), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 6254, 14791, 20469), PARA(3, 2, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 1646,  6619, 10696), PARA(3, 3, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(25334, 31967, 32621), PARA(3, 3, 2) },
                    { CDF3(15582, 31040, 32462), PARA(3, 2, 3) },
                }, {
                    { CDF3(18907, 30472, 32314), PARA(3, 3, 2) },
                    { CDF3(  953, 26945, 31805), PARA(3, 2, 2) },
                }, {
                    { CDF3(13516, 26908, 30904), PARA(3, 2, 2) },
                    { CDF3( 1549, 21936, 29542), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8297, 20991, 27437), PARA(3, 2, 3) },
                    { CDF3(  557, 15598, 25261), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3980, 11626, 17598), PARA(2, 2, 3) },
                    { CDF3(  918,  8073, 15400), PARA(2, 2, 3) },
                }, {
                    { CDF3(26391, 32035, 32595), PARA(3, 2, 2) },
                    { CDF3(17672, 31342, 32493), PARA(2, 2, 2) },
                }, {
                    { CDF3(19580, 30651, 32319), PARA(3, 2, 2) },
                    { CDF3(  589, 27593, 31900), PARA(3, 2, 2) },
                }, {
                    { CDF3(13734, 27193, 31043), PARA(2, 2, 2) },
                    { CDF3( 1624, 22701, 29917), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8311, 21239, 27850), PARA(2, 2, 3) },
                    { CDF3(  510, 15971, 25802), PARA(2, 2, 2) },
                }, {
                    { CDF3( 4217, 12744, 19511), PARA(2, 2, 3) },
                    { CDF3(  717,  9081, 16951), PARA(2, 2, 3) },
                }, {
                    { CDF3(25094, 32069, 32616), PARA(2, 1, 2) },
                    { CDF3(17839, 31778, 32640), PARA(2, 1, 2) },
                }, {
                    { CDF3(19672, 30814, 32312), PARA(3, 2, 2) },
                    { CDF3( 2025, 28482, 32043), PARA(3, 2, 2) },
                }, {
                    { CDF3(14800, 28188, 31442), PARA(2, 2, 2) },
                    { CDF3( 1221, 24055, 30573), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8995, 22820, 28992), PARA(2, 2, 3) },
                    { CDF3( 1167, 17916, 27275), PARA(2, 2, 3) },
                }, {
                    { CDF3( 4844, 14798, 22123), PARA(3, 2, 3) },
                    { CDF3(  839, 10591, 19419), PARA(2, 2, 3) },
                }, {
                    { CDF3(30845, 32589, 32713), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(19409, 29802, 31864), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(11114, 22871, 27848), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 6092, 16202, 22429), PARA(2, 1, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3247,  9679, 15027), PARA(3, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(27264, 32622, 32748), PARA(3, 2, 2) },
                    { CDF3(13182, 32042, 32728), PARA(3, 2, 2) },
                }, {
                    { CDF3(22849, 32019, 32682), PARA(3, 2, 2) },
                    { CDF3(  491, 29944, 32540), PARA(3, 2, 2) },
                }, {
                    { CDF3(17618, 30067, 32261), PARA(3, 2, 2) },
                    { CDF3( 1861, 25960, 31490), PARA(3, 2, 2) },
                }, {
                    { CDF3(10036, 24382, 29998), PARA(3, 2, 2) },
                    { CDF3( 1347, 18931, 28166), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5051, 14703, 21347), PARA(3, 2, 2) },
                    { CDF3(  259, 10600, 19087), PARA(2, 2, 2) },
                }, {
                    { CDF3(29595, 32710, 32748), PARA(3, 2, 2) },
                    { CDF3(19929, 32553, 32748), PARA(2, 2, 2) },
                }, {
                    { CDF3(24721, 32388, 32722), PARA(3, 2, 2) },
                    { CDF3( 1482, 30913, 32625), PARA(3, 2, 2) },
                }, {
                    { CDF3(18729, 30720, 32485), PARA(2, 2, 2) },
                    { CDF3( 1645, 27442, 31977), PARA(2, 2, 2) },
                }, {
                    { CDF3(10807, 25638, 30749), PARA(3, 2, 2) },
                    { CDF3( 1150, 20387, 29227), PARA(2, 2, 3) },
                }, {
                    { CDF3( 5546, 16487, 23567), PARA(2, 2, 2) },
                    { CDF3(  403, 12249, 21372), PARA(2, 2, 2) },
                }, {
                    { CDF3(30695, 32738, 32748), PARA(3, 1, 2) },
                    { CDF3(25061, 32689, 32748), PARA(2, 2, 2) },
                }, {
                    { CDF3(26547, 32580, 32747), PARA(3, 2, 2) },
                    { CDF3( 1334, 31785, 32708), PARA(3, 2, 2) },
                }, {
                    { CDF3(20996, 31697, 32662), PARA(2, 2, 2) },
                    { CDF3( 3682, 29397, 32392), PARA(3, 2, 3) },
                }, {
                    { CDF3(13209, 28091, 31805), PARA(2, 2, 3) },
                    { CDF3(  840, 23372, 30922), PARA(2, 2, 3) },
                }, {
                    { CDF3( 7389, 20059, 27005), PARA(2, 2, 2) },
                    { CDF3(  332, 15296, 25093), PARA(2, 2, 2) },
                }, {
                    { CDF3(32282, 32726, 32748), PARA(2, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(23211, 31638, 32504), PARA(3, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(13980, 26668, 30388), PARA(2, 2, 1) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7795, 19288, 25941), PARA(2, 1, 1) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3877, 11700, 17890), PARA(2, 2, 1) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(28880, 32680, 32748), PARA(2, 2, 2) },
                    { CDF3(12427, 32347, 32748), PARA(3, 3, 2) },
                }, {
                    { CDF3(24025, 32081, 32704), PARA(3, 2, 2) },
                    { CDF3( 2065, 30727, 32657), PARA(3, 2, 1) },
                }, {
                    { CDF3(19872, 30769, 32395), PARA(2, 2, 2) },
                    { CDF3( 1210, 27547, 31961), PARA(3, 2, 1) },
                }, {
                    { CDF3(10410, 24769, 29817), PARA(2, 2, 1) },
                    { CDF3( 2247, 19228, 27805), PARA(2, 2, 1) },
                }, {
                    { CDF3( 3997, 11545, 16952), PARA(3, 2, 2) },
                    { CDF3(  146,  7698, 14688), PARA(2, 2, 1) },
                }, {
                    { CDF3(30905, 32733, 32748), PARA(3, 2, 2) },
                    { CDF3(18768, 32634, 32748), PARA(3, 2, 1) },
                }, {
                    { CDF3(26894, 32528, 32731), PARA(3, 2, 1) },
                    { CDF3( 1978, 31675, 32684), PARA(3, 2, 1) },
                }, {
                    { CDF3(20750, 31222, 32412), PARA(2, 2, 1) },
                    { CDF3( 3259, 28753, 32073), PARA(2, 2, 1) },
                }, {
                    { CDF3(10948, 25238, 30225), PARA(2, 2, 2) },
                    { CDF3(  733, 20129, 28689), PARA(2, 2, 1) },
                }, {
                    { CDF3( 3995, 12602, 18654), PARA(2, 2, 2) },
                    { CDF3(  997,  9216, 16560), PARA(3, 2, 2) },
                }, {
                    { CDF3(31712, 32750, 32754), PARA(3, 2, 2) },
                    { CDF3(31152, 32718, 32748), PARA(3, 2, 2) },
                }, {
                    { CDF3(28091, 32642, 32748), PARA(3, 2, 2) },
                    { CDF3( 5217, 32006, 32702), PARA(3, 2, 3) },
                }, {
                    { CDF3(22886, 31816, 32647), PARA(2, 2, 2) },
                    { CDF3( 2358, 29840, 32394), PARA(3, 2, 2) },
                }, {
                    { CDF3(13616, 27730, 31451), PARA(2, 2, 2) },
                    { CDF3( 1022, 23059, 30343), PARA(2, 2, 2) },
                }, {
                    { CDF3( 6026, 17154, 23829), PARA(3, 2, 2) },
                    { CDF3(  837, 12628, 21443), PARA(3, 3, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(27869, 32588, 32732), PARA(2, 2, 1) },
                    { CDF3(11934, 31678, 32720), PARA(3, 2, 3) },
                }, {
                    { CDF3(20773, 31428, 32627), PARA(3, 2, 2) },
                    { CDF3(  813, 29336, 32408), PARA(2, 2, 2) },
                }, {
                    { CDF3(16679, 28979, 31835), PARA(2, 1, 1) },
                    { CDF3( 2825, 24549, 30651), PARA(2, 2, 1) },
                }, {
                    { CDF3( 8393, 21384, 27275), PARA(2, 2, 1) },
                    { CDF3(   95, 15687, 24751), PARA(2, 1, 1) },
                }, {
                    { CDF3( 3024,  8983, 13215), PARA(3, 2, 2) },
                    { CDF3(  476,  5931, 11675), PARA(3, 3, 2) },
                }, {
                    { CDF3(29793, 32715, 32748), PARA(1, 1, 1) },
                    { CDF3(15137, 32136, 32735), PARA(2, 2, 2) },
                }, {
                    { CDF3(23697, 31828, 32635), PARA(2, 2, 1) },
                    { CDF3( 1247, 29941, 32474), PARA(1, 1, 1) },
                }, {
                    { CDF3(15925, 28680, 31655), PARA(2, 1, 1) },
                    { CDF3( 2639, 25018, 30693), PARA(2, 1, 1) },
                }, {
                    { CDF3( 8039, 21380, 27690), PARA(3, 1, 2) },
                    { CDF3( 2054, 16597, 25993), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3566, 10567, 15908), PARA(3, 3, 2) },
                    { CDF3(  229,  7289, 14138), PARA(2, 2, 1) },
                }, {
                    { CDF3(31282, 32752, 32756), PARA(3, 2, 2) },
                    { CDF3(32072, 32728, 32748), PARA(3, 3, 2) },
                }, {
                    { CDF3(26939, 32527, 32733), PARA(3, 2, 2) },
                    { CDF3( 6585, 31625, 32669), PARA(3, 2, 3) },
                }, {
                    { CDF3(19878, 30839, 32397), PARA(3, 2, 3) },
                    { CDF3( 1559, 27814, 31953), PARA(3, 2, 3) },
                }, {
                    { CDF3(11443, 25746, 30681), PARA(3, 2, 3) },
                    { CDF3(  474, 20515, 28997), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5430, 15504, 22268), PARA(3, 3, 3) },
                    { CDF3(  484, 11281, 19715), PARA(3, 3, 3) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            },
        }, .base_y_tok_lf = {
            {
                {
                    { CDF5( 2114, 21141, 25369, 30654, 32239), PARA(2, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(  549, 13587, 23108, 28767, 30410), PARA(2, 0, 2) },
                    { CDF5(    4,  5842, 19871, 26925, 30302), PARA(2, 2, 1) },
                }, {
                    { CDF5( 4153, 12881, 20886, 25152, 28465), PARA(2, 1, 2) },
                    { CDF5(    4,  9887, 17074, 23240, 26922), PARA(2, 2, 1) },
                }, {
                    { CDF5( 3509,  9661, 15222, 20437, 24828), PARA(2, 2, 3) },
                    { CDF5(    4,  5559, 13171, 19109, 22949), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2887,  7713, 11843, 15697, 19332), PARA(2, 3, 3) },
                    { CDF5(    4,  5122,  9599, 14742, 18968), PARA(3, 2, 1) },
                }, {
                    { CDF5( 2828,  6215, 10303, 13224, 16380), PARA(2, 3, 3) },
                    { CDF5(    4,  2931,  7161, 10506, 14230), PARA(2, 3, 3) },
                }, {
                    { CDF5( 1614,  5662,  8479, 11366, 13422), PARA(2, 3, 3) },
                    { CDF5(    4,  1770,  4011,  7227,  9349), PARA(2, 3, 0) },
                }, {
                    { CDF5( 1307,  3944,  6304,  9227, 11645), PARA(3, 1, 3) },
                    { CDF5(    4,  2665,  4779,  7323,  9602), PARA(3, 3, 3) },
                }, {
                    { CDF5( 1058,  2942,  4397,  5803,  6862), PARA(3, 2, 3) },
                    { CDF5(    8,  1344,  2527,  4536,  6155), PARA(3, 2, 3) },
                }, {
                    { CDF5(13961, 27727, 31548, 32432, 32640), PARA(1, 1, 2) },
                    { CDF5( 2708, 23637, 31303, 32335, 32585), PARA(2, 2, 1) },
                }, {
                    { CDF5( 8468, 21640, 27998, 30901, 32015), PARA(3, 3, 2) },
                    { CDF5(    4, 16662, 26837, 30837, 32112), PARA(3, 3, 2) },
                }, {
                    { CDF5( 6388, 17049, 24419, 28383, 30593), PARA(3, 3, 2) },
                    { CDF5(    4, 12537, 21264, 26680, 30075), PARA(2, 1, 2) },
                }, {
                    { CDF5( 4692, 13240, 20421, 25309, 28482), PARA(3, 2, 3) },
                    { CDF5(    4,  9230, 16499, 22332, 26503), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3442, 10509, 16259, 21231, 24617), PARA(2, 2, 2) },
                    { CDF5(    4,  6258, 12848, 18162, 22620), PARA(3, 3, 2) },
                }, {
                    { CDF5( 2789,  8106, 13273, 17690, 21420), PARA(3, 2, 3) },
                    { CDF5(    4,  5418, 10448, 15448, 19662), PARA(3, 1, 3) },
                }, {
                    { CDF5( 1801,  4801,  7786, 10991, 13154), PARA(3, 3, 3) },
                    { CDF5(   25,  3162,  6409,  9255, 12072), PARA(2, 2, 3) },
                }, {
                    { CDF5(18092, 29844, 32040, 32571, 32719), PARA(3, 2, 2) },
                    { CDF5( 9164, 26106, 31175, 32321, 32602), PARA(3, 2, 3) },
                }, {
                    { CDF5(11343, 24700, 29814, 31603, 32215), PARA(3, 3, 3) },
                    { CDF5(   22, 18800, 27925, 31139, 32203), PARA(3, 3, 2) },
                }, {
                    { CDF5( 6970, 17708, 24782, 28661, 30778), PARA(3, 3, 3) },
                    { CDF5(   38, 12260, 21656, 27173, 30241), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4769, 13169, 19793, 24809, 28254), PARA(3, 2, 3) },
                    { CDF5(  145,  8816, 16919, 22877, 26986), PARA(3, 2, 3) },
                }, {
                    { CDF5( 2805,  8155, 12943, 17359, 21110), PARA(3, 2, 3) },
                    { CDF5(  566,  5051, 10431, 15290, 19445), PARA(3, 2, 3) },
                }, {
                    { CDF5(21153, 29831, 31499, 32049, 32276), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11827, 24672, 29069, 30619, 31334), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6970, 16794, 23049, 26961, 28915), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6107, 13557, 19154, 23110, 25619), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2702,  7985, 12910, 17340, 20552), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1993,  5600,  9439, 13043, 16257), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1269,  3987,  6708,  9519, 11780), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(26630, 32076, 32532, 32672, 32731), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(13939, 25333, 29988, 31536, 32142), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6772, 15540, 22058, 26174, 28801), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5996, 13722, 19150, 22923, 25872), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2372,  6802, 11003, 14855, 18017), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(17303, 31326, 31526, 32376, 32710), PARA(2, 0, 1) },
                    { CDF5(  260, 16384, 22105, 27307, 28867), PARA(0, 3, 3) },
                }, {
                    { CDF5( 1845, 17089, 26116, 30050, 31620), PARA(3, 2, 2) },
                    { CDF5(    4,  7809, 21186, 27970, 30787), PARA(3, 2, 2) },
                }, {
                    { CDF5( 9621, 20802, 26452, 29388, 31088), PARA(2, 2, 2) },
                    { CDF5(    4, 15476, 24099, 28279, 30173), PARA(2, 2, 1) },
                }, {
                    { CDF5( 5542, 13743, 19899, 24736, 27946), PARA(3, 2, 2) },
                    { CDF5(    4,  8467, 16948, 22772, 26471), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3700, 10363, 15560, 20281, 23726), PARA(3, 2, 2) },
                    { CDF5(    4,  6038, 11885, 17198, 21363), PARA(2, 3, 2) },
                }, {
                    { CDF5( 2418,  7197, 12060, 15605, 19277), PARA(3, 3, 3) },
                    { CDF5(    4,  4658,  9217, 13468, 17379), PARA(3, 2, 3) },
                }, {
                    { CDF5( 1804,  6314,  9128, 12718, 15539), PARA(3, 3, 1) },
                    { CDF5( 1372,  1648,  6025,  9656, 13223), PARA(3, 2, 3) },
                }, {
                    { CDF5( 1735,  4846,  7989, 10786, 13487), PARA(3, 2, 3) },
                    { CDF5(    4,  3323,  6453,  9627, 12335), PARA(3, 3, 3) },
                }, {
                    { CDF5( 1072,  3013,  4878,  6783,  8518), PARA(3, 3, 3) },
                    { CDF5(   10,  1926,  3795,  5732,  7600), PARA(3, 3, 3) },
                }, {
                    { CDF5(18024, 30489, 32251, 32626, 32732), PARA(3, 3, 2) },
                    { CDF5(19896, 24724, 31657, 32534, 32732), PARA(2, 1, 2) },
                }, {
                    { CDF5(11660, 26630, 30824, 32187, 32598), PARA(3, 2, 2) },
                    { CDF5(    4, 21429, 29602, 31983, 32544), PARA(2, 2, 2) },
                }, {
                    { CDF5(12486, 24964, 29580, 31503, 32248), PARA(2, 3, 2) },
                    { CDF5(    4, 19295, 27630, 30822, 31918), PARA(2, 2, 1) },
                }, {
                    { CDF5( 6927, 17619, 24441, 28334, 30439), PARA(3, 2, 3) },
                    { CDF5(    4, 12994, 22001, 27172, 29927), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4541, 12600, 19151, 24114, 27363), PARA(3, 3, 3) },
                    { CDF5(    4,  8631, 16251, 21921, 25807), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3464,  9852, 15685, 20588, 24106), PARA(3, 2, 3) },
                    { CDF5(    4,  6580, 12812, 18079, 22278), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2085,  5889,  9302, 12624, 15262), PARA(3, 3, 3) },
                    { CDF5(   69,  3305,  6891, 10477, 13651), PARA(3, 2, 3) },
                }, {
                    { CDF5(23748, 31870, 32594, 32721, 32732), PARA(3, 3, 2) },
                    { CDF5(10783, 29998, 32378, 32682, 32732), PARA(3, 2, 3) },
                }, {
                    { CDF5(17733, 30083, 32212, 32605, 32725), PARA(3, 2, 2) },
                    { CDF5(  187, 25993, 31535, 32484, 32683), PARA(3, 2, 2) },
                }, {
                    { CDF5(12827, 26254, 30707, 32112, 32556), PARA(3, 2, 2) },
                    { CDF5(   92, 21424, 29165, 31621, 32404), PARA(3, 2, 2) },
                }, {
                    { CDF5( 7651, 19635, 26664, 30009, 31616), PARA(3, 2, 3) },
                    { CDF5(   27, 14981, 24532, 29277, 31387), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3603, 10277, 15911, 20395, 23870), PARA(3, 2, 3) },
                    { CDF5(  350,  6796, 13207, 18418, 22380), PARA(2, 2, 3) },
                }, {
                    { CDF5(28587, 32126, 32526, 32643, 32695), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(16637, 28727, 31322, 32097, 32381), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9765, 21318, 26832, 29587, 30810), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6949, 15290, 21217, 24889, 27171), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3604, 10158, 15795, 20231, 23348), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2312,  7277, 11902, 16059, 19358), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1616,  4713,  7922, 10951, 13675), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(30272, 32591, 32703, 32736, 32740), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(19778, 30226, 32065, 32498, 32646), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11082, 23345, 28543, 30633, 31593), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7718, 18010, 24057, 27609, 29598), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3560, 10218, 15775, 20026, 23024), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(22472, 31406, 32415, 32617, 32686), PARA(1, 0, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4579, 20789, 27200, 30357, 31565), PARA(2, 2, 2) },
                    { CDF5(    4, 12804, 24534, 29241, 31305), PARA(2, 1, 0) },
                }, {
                    { CDF5(10553, 22962, 27982, 30214, 31394), PARA(2, 2, 1) },
                    { CDF5(    4, 17230, 25117, 28842, 30403), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5244, 13272, 19764, 24354, 27332), PARA(2, 3, 2) },
                    { CDF5(    4,  8510, 16126, 21941, 25809), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3263,  9944, 15196, 19855, 22889), PARA(3, 2, 3) },
                    { CDF5(    4,  6173, 11683, 16946, 21240), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1953,  7145, 11524, 15201, 18227), PARA(2, 1, 2) },
                    { CDF5(  290,  4454,  9436, 13541, 17364), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1722,  5876,  9313, 13099, 15693), PARA(3, 2, 2) },
                    { CDF5(    4,  3730,  7620, 11131, 14444), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1665,  4813,  7575, 10457, 12877), PARA(2, 2, 2) },
                    { CDF5(    4,  3095,  6224,  9491, 12462), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1050,  3459,  5369,  7424,  9155), PARA(3, 3, 3) },
                    { CDF5(  125,  1583,  3405,  5421,  7274), PARA(2, 3, 2) },
                }, {
                    { CDF5(25676, 31984, 32605, 32712, 32732), PARA(3, 2, 2) },
                    { CDF5(22804, 26009, 31701, 32573, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(13894, 27451, 31145, 32228, 32639), PARA(2, 3, 2) },
                    { CDF5(    4, 23912, 30395, 32138, 32610), PARA(3, 2, 2) },
                }, {
                    { CDF5(14722, 26873, 30554, 31901, 32382), PARA(3, 1, 1) },
                    { CDF5(    4, 19859, 27062, 30489, 31792), PARA(2, 1, 1) },
                }, {
                    { CDF5( 6399, 16967, 23871, 27811, 30028), PARA(3, 2, 3) },
                    { CDF5(    4, 13114, 21748, 26707, 29694), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4205, 12741, 19447, 23962, 26806), PARA(3, 2, 1) },
                    { CDF5(    4,  8506, 15656, 21414, 25696), PARA(3, 2, 3) },
                }, {
                    { CDF5( 3566, 10323, 16256, 20824, 24096), PARA(3, 2, 2) },
                    { CDF5(    4,  6984, 13002, 18282, 22495), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1775,  5940,  9908, 13605, 16182), PARA(2, 2, 2) },
                    { CDF5(   33,  4084,  7837, 11117, 14306), PARA(3, 1, 2) },
                }, {
                    { CDF5(26506, 32458, 32715, 32736, 32740), PARA(3, 3, 2) },
                    { CDF5( 8374, 30740, 32600, 32729, 32733), PARA(3, 3, 3) },
                }, {
                    { CDF5(20516, 31118, 32508, 32699, 32732), PARA(3, 2, 2) },
                    { CDF5(    9, 27963, 32073, 32637, 32732), PARA(3, 2, 2) },
                }, {
                    { CDF5(15612, 28327, 31610, 32454, 32687), PARA(3, 1, 2) },
                    { CDF5(   26, 24066, 30443, 32138, 32600), PARA(3, 1, 2) },
                }, {
                    { CDF5( 8459, 21222, 27807, 30732, 31943), PARA(3, 2, 3) },
                    { CDF5(   26, 16663, 26041, 30121, 31822), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4168, 12043, 18257, 22879, 26034), PARA(3, 2, 2) },
                    { CDF5(   44,  8409, 15622, 20993, 24796), PARA(2, 2, 2) },
                }, {
                    { CDF5(30650, 32519, 32673, 32723, 32732), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(17529, 29628, 31828, 32359, 32545), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(10542, 21115, 26318, 29161, 30805), PARA(2, 1, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(10247, 15768, 19711, 22296, 24028), PARA(1, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2397,  7449, 12493, 16590, 19724), PARA(0, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1869,  5577,  9489, 12835, 15631), PARA(0, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1228,  3968,  6037,  8766, 10801), PARA(0, 1, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(31955, 32716, 32740, 32744, 32748), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(22693, 31709, 32467, 32593, 32659), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(14735, 26877, 30393, 31770, 32325), PARA(2, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9390, 20635, 25906, 28733, 30212), PARA(2, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4403, 11798, 18101, 22593, 25468), PARA(2, 1, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(17498, 29424, 31225, 31893, 32132), PARA(0, 0, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4465, 19403, 25248, 29392, 31099), PARA(2, 1, 0) },
                    { CDF5(    4, 11650, 23783, 29177, 30996), PARA(2, 1, 0) },
                }, {
                    { CDF5( 9152, 21002, 26411, 29197, 30838), PARA(2, 1, 1) },
                    { CDF5(  387, 15169, 23639, 27517, 29225), PARA(2, 1, 0) },
                }, {
                    { CDF5( 4263, 12796, 18125, 23216, 25968), PARA(3, 2, 1) },
                    { CDF5(    4,  8811, 16017, 21391, 24903), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2963,  7692, 13120, 17437, 20742), PARA(3, 2, 2) },
                    { CDF5(    4,  5759, 11337, 16128, 19807), PARA(3, 2, 3) },
                }, {
                    { CDF5( 2381,  7283, 11060, 13175, 15657), PARA(3, 2, 3) },
                    { CDF5(   30,  3641,  7204, 11473, 15621), PARA(3, 2, 1) },
                }, {
                    { CDF5( 1314,  5852,  7870, 11057, 13558), PARA(3, 2, 2) },
                    { CDF5( 1846,  2126,  5191,  9398, 12426), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1838,  5614,  8157, 11023, 13394), PARA(3, 3, 3) },
                    { CDF5(  711,   875,  4561,  6006,  8631), PARA(1, 1, 1) },
                }, {
                    { CDF5( 1166,  3234,  5698,  8017,  9616), PARA(3, 3, 3) },
                    { CDF5(   25,  1054,  2149,  3082,  4062), PARA(2, 2, 2) },
                }, {
                    { CDF5(26289, 31974, 32589, 32707, 32732), PARA(2, 1, 1) },
                    { CDF5(15601, 27297, 32026, 32579, 32732), PARA(1, 1, 2) },
                }, {
                    { CDF5(14722, 28032, 31407, 32465, 32660), PARA(3, 3, 0) },
                    { CDF5(    4, 25486, 30863, 32285, 32652), PARA(3, 1, 1) },
                }, {
                    { CDF5(14143, 25751, 29446, 31254, 32093), PARA(3, 2, 2) },
                    { CDF5(   54, 19128, 26757, 29947, 31382), PARA(2, 2, 1) },
                }, {
                    { CDF5( 5488, 15901, 22490, 26764, 29217), PARA(3, 2, 2) },
                    { CDF5(   61, 12497, 20739, 25857, 28681), PARA(2, 1, 1) },
                }, {
                    { CDF5( 4022, 11170, 17442, 21682, 24925), PARA(3, 2, 2) },
                    { CDF5(    4,  7890, 14887, 20318, 24465), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3011,  9192, 14601, 19495, 22381), PARA(2, 2, 2) },
                    { CDF5(  328,  6291, 12024, 16828, 20336), PARA(2, 2, 1) },
                }, {
                    { CDF5( 1563,  4884,  8005, 10967, 13252), PARA(3, 3, 2) },
                    { CDF5(   14,  3264,  6674,  9678, 12501), PARA(3, 3, 2) },
                }, {
                    { CDF5(28318, 32551, 32737, 32741, 32745), PARA(3, 2, 2) },
                    { CDF5( 8123, 31532, 32680, 32736, 32740), PARA(3, 2, 1) },
                }, {
                    { CDF5(21238, 31149, 32509, 32707, 32732), PARA(3, 2, 2) },
                    { CDF5(  138, 28353, 32132, 32659, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(16317, 28616, 31700, 32471, 32706), PARA(2, 2, 1) },
                    { CDF5(  645, 23978, 30123, 31941, 32494), PARA(3, 1, 3) },
                }, {
                    { CDF5( 8177, 21167, 27635, 30495, 31817), PARA(3, 3, 3) },
                    { CDF5(  240, 16105, 25295, 29540, 31448), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3393,  9936, 15268, 19487, 22467), PARA(3, 2, 1) },
                    { CDF5(  100,  7031, 13173, 17962, 21368), PARA(2, 2, 1) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(14193, 27782, 31321, 32004, 32607), PARA(0, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1210, 13319, 22982, 27380, 30780), PARA(1, 0, 0) },
                    { CDF5(    4,  7290, 20938, 26753, 30532), PARA(1, 1, 0) },
                }, {
                    { CDF5( 6129, 19017, 24319, 27326, 29222), PARA(1, 1, 0) },
                    { CDF5(  108, 12264, 17594, 22318, 25161), PARA(0, 1, 0) },
                }, {
                    { CDF5( 3672, 16362, 17673, 20077, 22838), PARA(1, 2, 1) },
                    { CDF5( 1389,  4066, 11635, 17622, 22074), PARA(2, 1, 0) },
                }, {
                    { CDF5( 2395,  9381, 12019, 14390, 17169), PARA(1, 3, 2) },
                    { CDF5(  123,  3545,  5521, 12207, 15924), PARA(1, 1, 3) },
                }, {
                    { CDF5( 2084,  5758,  9241, 11873, 14327), PARA(3, 3, 3) },
                    { CDF5(   14,  4141,  8239, 10165, 13119), PARA(3, 3, 3) },
                }, {
                    { CDF5( 1510,  4925,  7765, 10264, 12295), PARA(2, 3, 3) },
                    { CDF5(  424,  2326,  5212,  9049, 12105), PARA(3, 3, 3) },
                }, {
                    { CDF5( 1310,  4491,  6944,  9377, 11560), PARA(2, 3, 0) },
                    { CDF5(  796,  2092,  4230,  6299,  9460), PARA(2, 3, 3) },
                }, {
                    { CDF5(  575,  2082,  3357,  4723,  5504), PARA(3, 3, 3) },
                    { CDF5(  407,  1183,  2575,  3784,  5063), PARA(3, 3, 2) },
                }, {
                    { CDF5(21859, 29753, 31615, 32585, 32702), PARA(1, 1, 1) },
                    { CDF5( 3511, 29157, 31832, 32567, 32701), PARA(0, 3, 2) },
                }, {
                    { CDF5(13469, 26644, 30586, 31697, 32163), PARA(1, 2, 0) },
                    { CDF5(   43, 24491, 30511, 31649, 32156), PARA(1, 1, 0) },
                }, {
                    { CDF5(11517, 23927, 28667, 30593, 31651), PARA(2, 2, 1) },
                    { CDF5(   25, 17446, 24435, 28271, 30325), PARA(2, 1, 1) },
                }, {
                    { CDF5( 6058, 16232, 22050, 26218, 27912), PARA(2, 2, 1) },
                    { CDF5(  168,  8904, 17397, 23318, 27175), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3216,  9575, 15671, 19813, 23338), PARA(3, 2, 1) },
                    { CDF5(   65,  6797, 12411, 18393, 22224), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2705,  8581, 12260, 16653, 20249), PARA(3, 3, 2) },
                    { CDF5(  396,  5255, 11135, 16441, 20215), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1193,  3568,  6140,  8638, 10114), PARA(3, 3, 3) },
                    { CDF5(   11,  2647,  5137,  7270,  9301), PARA(3, 2, 2) },
                }, {
                    { CDF5(27677, 32597, 32738, 32742, 32746), PARA(1, 2, 1) },
                    { CDF5( 9101, 31116, 32717, 32736, 32740), PARA(2, 2, 0) },
                }, {
                    { CDF5(17896, 30207, 32257, 32653, 32732), PARA(3, 2, 2) },
                    { CDF5(  325, 26949, 31766, 32617, 32732), PARA(2, 3, 1) },
                }, {
                    { CDF5(13007, 26339, 30456, 31958, 32494), PARA(3, 2, 2) },
                    { CDF5(  638, 21532, 29168, 31580, 32346), PARA(3, 1, 2) },
                }, {
                    { CDF5( 6432, 18636, 25684, 29741, 31417), PARA(2, 2, 2) },
                    { CDF5(  399, 14022, 22914, 27926, 30488), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2460,  7366, 11813, 15406, 18038), PARA(3, 3, 2) },
                    { CDF5(  141,  5139,  9696, 13649, 16881), PARA(3, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            },
        }, .dc_sign = {
            {
                { CDF1(16540), PARA(3, 3, 3) },
                { CDF1(14804), PARA(3, 3, 3) },
                { CDF1(18312), PARA(3, 3, 3) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }
        }, .br_y_tok_hf = {
            { CDF3(24190, 30560, 31576), PARA(1, 1, 2) },
            { CDF3(24366, 30921, 31758), PARA(3, 2, 3) },
            { CDF3(21555, 29858, 31096), PARA(2, 2, 3) },
            { CDF3(16661, 26574, 28953), PARA(3, 2, 3) },
            { CDF3(11988, 21738, 25479), PARA(3, 3, 3) },
            { CDF3( 8920, 17446, 22214), PARA(3, 3, 3) },
            { CDF3( 5802, 12294, 17499), PARA(3, 2, 3) },
        }, .br_y_tok_lf = {
            { CDF3(11992, 17977, 23847), PARA(1, 0, 0) },
            { CDF3(14229, 22329, 26075), PARA(3, 3, 2) },
            { CDF3(11443, 20390, 22820), PARA(3, 2, 1) },
            { CDF3( 8397, 16223, 19264), PARA(3, 3, 2) },
            { CDF3( 5827, 11883, 14653), PARA(3, 3, 2) },
            { CDF3( 4416,  9159, 11664), PARA(3, 3, 2) },
            { CDF3( 2812,  6024,  7386), PARA(3, 3, 3) },
            { CDF3(16755, 23759, 26700), PARA(2, 1, 2) },
            { CDF3(17293, 25940, 28518), PARA(3, 3, 3) },
            { CDF3(15547, 25297, 27304), PARA(3, 3, 3) },
            { CDF3(12584, 22225, 24378), PARA(3, 3, 3) },
            { CDF3( 9185, 17517, 19977), PARA(3, 3, 3) },
            { CDF3( 7015, 13961, 16744), PARA(3, 3, 3) },
            { CDF3( 4509,  9609, 11858), PARA(3, 3, 3) },
        }, .ph_dc_y_tok = {
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
        }, .bob_base_y_tok = {
            {
                { CDF2(16673, 23002), PARA(3, 2, 2) },
                { CDF2(19890, 25933), PARA(3, 3, 2) },
                { CDF2(18355, 25595), PARA(3, 2, 2) },
            }, {
                { CDF2(19619, 25865), PARA(2, 2, 2) },
                { CDF2(22421, 27836), PARA(2, 2, 2) },
                { CDF2(22018, 27887), PARA(2, 2, 2) },
            }, {
                { CDF2(22395, 27670), PARA(1, 1, 1) },
                { CDF2(24275, 28656), PARA(1, 1, 1) },
                { CDF2(22595, 28026), PARA(2, 2, 1) },
            },
        }, .br_y_tok_idtx = {
            {
                { CDF3(11825, 18784, 22974), PARA(2, 2, 2) },
                { CDF3(10844, 17662, 22290), PARA(2, 2, 2) },
                { CDF3(10616, 16959, 21303), PARA(3, 3, 2) },
                { CDF3(11817, 17622, 21664), PARA(3, 3, 2) },
                { CDF3( 8267, 15623, 19902), PARA(3, 3, 2) },
                { CDF3( 5350,  9801, 14462), PARA(2, 1, 2) },
                { CDF3( 3443,  6585,  9559), PARA(3, 2, 2) },
            }, {
                { CDF3(13939, 20762, 24451), PARA(1, 1, 1) },
                { CDF3(16243, 23219, 26714), PARA(1, 1, 1) },
                { CDF3(15074, 22210, 25984), PARA(2, 1, 1) },
                { CDF3(16107, 22725, 26296), PARA(2, 1, 1) },
                { CDF3(10893, 20273, 24826), PARA(2, 1, 1) },
                { CDF3( 5645, 10671, 15100), PARA(1, 1, 2) },
                { CDF3( 4335,  8679, 12492), PARA(1, 1, 1) },
            }, {
                { CDF3(14250, 21163, 24941), PARA(1, 0, 0) },
                { CDF3(17217, 23934, 27433), PARA(1, 1, 0) },
                { CDF3(17090, 23993, 27574), PARA(1, 0, 0) },
                { CDF3(19725, 25425, 28697), PARA(1, 0, 0) },
                { CDF3(12700, 23765, 28251), PARA(1, 0, 0) },
                { CDF3( 6542, 11855, 17108), PARA(1, 0, 0) },
                { CDF3( 5101, 10468, 15443), PARA(1, 0, 0) },
            },
        }, .base_y_tok_idtx = {
            {
                { CDF3(28035, 30893, 31756), PARA(3, 2, 3) },
                { CDF3(18097, 26957, 29476), PARA(3, 2, 2) },
                { CDF3(15075, 22557, 26893), PARA(2, 2, 2) },
                { CDF3(11632, 16975, 20254), PARA(2, 2, 2) },
                { CDF3( 5659, 12007, 16445), PARA(2, 2, 2) },
                { CDF3( 3855,  7854, 12411), PARA(2, 2, 1) },
                { CDF3( 2360,  4192,  5868), PARA(2, 2, 2) },
            }, {
                { CDF3(31009, 32323, 32574), PARA(3, 2, 3) },
                { CDF3(21342, 29678, 31451), PARA(3, 2, 3) },
                { CDF3(16940, 25075, 29268), PARA(2, 2, 2) },
                { CDF3(12426, 17800, 21533), PARA(2, 2, 2) },
                { CDF3( 6079, 13099, 18572), PARA(2, 2, 1) },
                { CDF3( 4249,  8763, 13561), PARA(2, 1, 1) },
                { CDF3( 2473,  4631,  6923), PARA(2, 1, 2) },
            }, {
                { CDF3(32079, 32614, 32706), PARA(3, 2, 2) },
                { CDF3(22634, 30655, 31942), PARA(2, 2, 2) },
                { CDF3(16704, 25079, 29917), PARA(1, 1, 1) },
                { CDF3(12795, 17039, 20729), PARA(2, 1, 1) },
                { CDF3( 5362, 11212, 18340), PARA(1, 0, 0) },
                { CDF3( 3513,  6916, 12694), PARA(1, 1, 1) },
                { CDF3( 1883,  3540,  5856), PARA(2, 1, 1) },
            },
        }, .sign_idtx = {
            {
                { CDF1(17010), PARA(2, 2, 2) },
                { CDF1(25832), PARA(2, 2, 2) },
                { CDF1( 7718), PARA(2, 2, 3) },
                { CDF1(29537), PARA(2, 2, 1) },
                { CDF1( 8925), PARA(1, 1, 1) },
                { CDF1(30595), PARA(3, 2, 2) },
                { CDF1( 4677), PARA(3, 3, 2) },
                { CDF1(32471), PARA(3, 3, 2) },
                { CDF1( 3023), PARA(2, 2, 1) },
            }, {
                { CDF1(17528), PARA(1, 2, 2) },
                { CDF1(27808), PARA(2, 2, 2) },
                { CDF1( 6222), PARA(2, 2, 2) },
                { CDF1(29747), PARA(2, 2, 1) },
                { CDF1( 2848), PARA(1, 1, 1) },
                { CDF1(31635), PARA(3, 2, 2) },
                { CDF1( 2513), PARA(3, 2, 2) },
                { CDF1(32514), PARA(3, 2, 2) },
                { CDF1(  474), PARA(2, 3, 3) },
            }, {
                { CDF1(19157), PARA(1, 1, 1) },
                { CDF1(30551), PARA(1, 1, 1) },
                { CDF1( 2788), PARA(1, 1, 1) },
                { CDF1(30752), PARA(1, 0, 0) },
                { CDF1(  701), PARA(1, 2, 1) },
                { CDF1(32565), PARA(2, 3, 2) },
                { CDF1(  359), PARA(2, 1, 3) },
                { CDF1(32515), PARA(3, 0, 0) },
                { CDF1(  223), PARA(1, 0, 0) },
            },
        }, .skip_v = {
            { CDF1( 1341), PARA(3, 3, 3) },
            { CDF1( 7768), PARA(3, 2, 2) },
            { CDF1(16044), PARA(2, 2, 1) },
            { CDF1(  104), PARA(0, 0, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1(16384), PARA(2, 2, 2) },
            { CDF1( 8426), PARA(2, 2, 2) },
            { CDF1(16919), PARA(2, 2, 2) },
            { CDF1(25248), PARA(2, 2, 2) },
            { CDF1( 8448), PARA(0, 2, 2) },
            { CDF1(27163), PARA(0, 2, 2) },
            { CDF1(27594), PARA(0, 2, 2) },
        }, .eob_base_uv_tok_hf = {
            { CDF2(31595, 32587), PARA(3, 3, 3) },
            { CDF2(32266, 32710), PARA(3, 3, 3) },
            { CDF2(32287, 32698), PARA(3, 3, 3) },
        }, .base_uv_tok_hf = {
            { CDF3(26264, 32282, 32667), PARA(3, 2, 2) },
            { CDF3(16468, 29532, 31912), PARA(3, 2, 3) },
            { CDF3( 8915, 21647, 27531), PARA(2, 2, 2) },
            { CDF3( 4341, 12415, 18782), PARA(3, 2, 2) },
            { CDF3(27171, 32473, 32714), PARA(3, 3, 2) },
            { CDF3(18547, 30679, 32297), PARA(3, 2, 2) },
            { CDF3( 9723, 23037, 28561), PARA(2, 2, 2) },
            { CDF3( 4310, 12399, 18745), PARA(3, 2, 2) },
            { CDF3(29747, 32607, 32733), PARA(3, 2, 2) },
            { CDF3(21347, 31575, 32509), PARA(3, 3, 2) },
            { CDF3(10548, 22298, 28335), PARA(3, 1, 2) },
            { CDF3( 2124,  9709, 17598), PARA(3, 3, 2) },
        }, .br_uv_tok_hf = {
            { CDF3(24442, 29827, 31535), PARA(3, 2, 2) },
            { CDF3(22490, 28954, 31256), PARA(3, 3, 3) },
            { CDF3(17882, 25670, 29377), PARA(3, 3, 3) },
            { CDF3(10664, 17735, 22437), PARA(3, 2, 2) },
        }, .eob_base_uv_tok_lf = {
            { CDF4(29843, 32183, 32562, 32675), PARA(3, 2, 2) },
            { CDF4(29975, 31731, 32100, 32264), PARA(2, 0, 0) },
            { CDF4(30096, 31949, 32460, 32611), PARA(1, 2, 0) },
        }, .base_uv_tok_lf = {
            { CDF5(15362, 27650, 30927, 32014, 32397), PARA(2, 1, 1) },
            { CDF5( 9556, 22999, 28733, 31004, 31942), PARA(3, 2, 2) },
            { CDF5( 5238, 14626, 21567, 26015, 28727), PARA(3, 2, 3) },
            { CDF5( 2196,  6512, 10780, 14847, 18294), PARA(3, 3, 3) },
            { CDF5(15569, 28727, 31706, 32423, 32650), PARA(2, 2, 2) },
            { CDF5(11506, 25824, 30517, 31948, 32443), PARA(3, 2, 2) },
            { CDF5( 6211, 16772, 23701, 27732, 29961), PARA(3, 3, 2) },
            { CDF5( 2461,  7239, 11755, 15869, 19210), PARA(3, 3, 2) },
            { CDF5(26951, 32136, 32556, 32654, 32696), PARA(3, 2, 2) },
            { CDF5(17691, 30215, 31944, 32399, 32550), PARA(3, 2, 2) },
            { CDF5( 9349, 19307, 25385, 29027, 30821), PARA(2, 1, 1) },
            { CDF5( 8528, 15111, 18457, 21676, 23767), PARA(1, 0, 0) },
        }
    }, [2] = {
        .skip = {
            {
                {
                    { CDF1(28021), PARA(2, 2, 3) },
                    { CDF1( 4675), PARA(3, 2, 2) },
                    { CDF1( 6407), PARA(3, 2, 2) },
                    { CDF1(12870), PARA(2, 2, 2) },
                    { CDF1(18069), PARA(2, 2, 1) },
                    { CDF1(26728), PARA(1, 1, 2) },
                    { CDF1( 4204), PARA(2, 1, 1) },
                    { CDF1(11853), PARA(3, 2, 2) },
                    { CDF1(19479), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(30300), PARA(2, 2, 2) },
                    { CDF1( 4727), PARA(2, 2, 3) },
                    { CDF1( 5333), PARA(3, 2, 2) },
                    { CDF1(13460), PARA(2, 1, 1) },
                    { CDF1(17424), PARA(2, 1, 1) },
                    { CDF1(28814), PARA(1, 1, 2) },
                    { CDF1( 4777), PARA(2, 2, 2) },
                    { CDF1(12522), PARA(2, 2, 2) },
                    { CDF1(20439), PARA(2, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(31298), PARA(1, 2, 2) },
                    { CDF1( 6336), PARA(2, 2, 2) },
                    { CDF1( 7488), PARA(3, 2, 1) },
                    { CDF1(19193), PARA(1, 1, 1) },
                    { CDF1(21405), PARA(1, 1, 1) },
                    { CDF1(31491), PARA(2, 1, 2) },
                    { CDF1( 5723), PARA(2, 2, 2) },
                    { CDF1(15055), PARA(2, 2, 1) },
                    { CDF1(23518), PARA(2, 2, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(31807), PARA(0, 1, 1) },
                    { CDF1( 1393), PARA(3, 2, 2) },
                    { CDF1( 3549), PARA(2, 2, 0) },
                    { CDF1(18574), PARA(1, 1, 0) },
                    { CDF1(19795), PARA(1, 1, 0) },
                    { CDF1(31792), PARA(1, 0, 1) },
                    { CDF1( 5941), PARA(1, 1, 1) },
                    { CDF1(16460), PARA(1, 1, 0) },
                    { CDF1(25194), PARA(1, 1, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(32278), PARA(0, 0, 1) },
                    { CDF1( 2582), PARA(1, 1, 1) },
                    { CDF1(13992), PARA(1, 1, 1) },
                    { CDF1(25993), PARA(1, 1, 0) },
                    { CDF1(26283), PARA(3, 2, 0) },
                    { CDF1(32056), PARA(2, 2, 2) },
                    { CDF1( 6989), PARA(1, 1, 0) },
                    { CDF1(17824), PARA(1, 1, 0) },
                    { CDF1(24231), PARA(1, 1, 0) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF1(32764), PARA(2, 2, 2) },
                    { CDF1( 9384), PARA(3, 3, 1) },
                    { CDF1(12245), PARA(2, 1, 0) },
                    { CDF1(14958), PARA(3, 2, 2) },
                    { CDF1(18080), PARA(1, 1, 2) },
                    { CDF1(23099), PARA(1, 1, 2) },
                    { CDF1( 2191), PARA(3, 3, 2) },
                    { CDF1( 9674), PARA(2, 2, 1) },
                    { CDF1(17537), PARA(2, 2, 1) },
                    { CDF1(32587), PARA(3, 3, 2) },
                }, {
                    { CDF1(32729), PARA(2, 3, 3) },
                    { CDF1(12523), PARA(3, 3, 3) },
                    { CDF1(13844), PARA(3, 3, 3) },
                    { CDF1(16079), PARA(3, 3, 3) },
                    { CDF1(21004), PARA(3, 3, 2) },
                    { CDF1(25973), PARA(2, 2, 2) },
                    { CDF1( 1860), PARA(2, 3, 2) },
                    { CDF1( 9626), PARA(2, 2, 1) },
                    { CDF1(18115), PARA(2, 2, 1) },
                    { CDF1(31918), PARA(1, 2, 2) },
                }, {
                    { CDF1(32727), PARA(1, 3, 3) },
                    { CDF1(14244), PARA(3, 3, 3) },
                    { CDF1(15808), PARA(3, 3, 1) },
                    { CDF1(18087), PARA(3, 2, 2) },
                    { CDF1(23066), PARA(3, 3, 2) },
                    { CDF1(27617), PARA(2, 2, 2) },
                    { CDF1( 1932), PARA(2, 2, 2) },
                    { CDF1(12274), PARA(2, 2, 1) },
                    { CDF1(23957), PARA(2, 1, 1) },
                    { CDF1(30007), PARA(2, 1, 0) },
                }, {
                    { CDF1(32605), PARA(0, 1, 1) },
                    { CDF1(14434), PARA(3, 3, 0) },
                    { CDF1(21625), PARA(3, 2, 3) },
                    { CDF1(21326), PARA(2, 2, 0) },
                    { CDF1(25757), PARA(2, 1, 2) },
                    { CDF1(30059), PARA(2, 1, 3) },
                    { CDF1( 2485), PARA(1, 2, 1) },
                    { CDF1(15041), PARA(2, 1, 1) },
                    { CDF1(26473), PARA(2, 1, 2) },
                    { CDF1(25895), PARA(0, 0, 3) },
                }, {
                    { CDF1(32562), PARA(0, 1, 1) },
                    { CDF1(15140), PARA(2, 1, 0) },
                    { CDF1(23809), PARA(2, 1, 0) },
                    { CDF1(26086), PARA(1, 1, 1) },
                    { CDF1(29383), PARA(2, 2, 0) },
                    { CDF1(31155), PARA(2, 3, 1) },
                    { CDF1( 4393), PARA(0, 2, 1) },
                    { CDF1(17678), PARA(1, 1, 3) },
                    { CDF1(25607), PARA(0, 1, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            },
        }, .eob_bin_16 = {
            { CDF4( 3946,  6406, 13325, 26004), PARA(1, 1, 2) },
            { CDF4( 2616,  3402,  7857, 13406), PARA(1, 1, 2) },
            { CDF4(13678, 17362, 23556, 28557), PARA(1, 1, 2) },
        }, .eob_bin_32 = {
            { CDF5( 3277,  4780,  9255, 16544, 21853), PARA(1, 1, 1) },
            { CDF5( 1655,  2364,  4679, 10029, 18955), PARA(1, 2, 1) },
            { CDF5(15549, 19007, 24651, 29173, 31742), PARA(2, 1, 1) },
        }, .eob_bin_64 = {
            { CDF6( 2024,  3239,  6969, 13073, 21617, 27643), PARA(1, 1, 1) },
            { CDF6( 1514,  1937,  3810,  7727, 13471, 23183), PARA(1, 1, 1) },
            { CDF6(14959, 18244, 24321, 29177, 31773, 32497), PARA(2, 2, 1) },
        }, .eob_bin_128 = {
            { CDF7( 1672,  2600,  5666, 11986, 21596, 28733, 30851), PARA(1, 1, 1) },
            { CDF7( 2101,  2605,  4469,  8056, 13125, 19491, 26379), PARA(1, 1, 1) },
            { CDF7(15041, 18279, 24430, 28935, 31545, 32439, 32672), PARA(2, 1, 1) },
        }, .eob_bin_256 = {
            { CDF7( 1556,  2520,  5142, 10585, 19507, 28407, 30571), PARA(1, 1, 0) },
            { CDF7( 3608,  4081,  5802,  8998, 13007, 18326, 23738), PARA(1, 1, 0) },
            { CDF7(14007, 17061, 22822, 27233, 30196, 31899, 32583), PARA(2, 1, 1) },
        }, .eob_bin_512 = {
            { CDF7( 1654,  2720,  5317, 10565, 19306, 29790, 30875), PARA(1, 1, 0) },
            { CDF7( 7237,  7980, 10164, 13730, 18015, 23652, 27137), PARA(1, 1, 0) },
            { CDF7(14503, 17149, 22592, 27035, 30013, 31699, 32526), PARA(2, 1, 0) },
        }, .eob_bin_1024 = {
            { CDF7( 2101,  3304,  6486, 12539, 21781, 30341, 30738), PARA(1, 1, 0) },
            { CDF7(11349, 12231, 14967, 18532, 22406, 26663, 28302), PARA(0, 1, 0) },
            { CDF7(15081, 17873, 23055, 27251, 30053, 31491, 32305), PARA(1, 1, 0) },
        }, .eob_hi_bit = {
            CDF1(19673), PARA(3, 2, 3)
        }, .eob_base_y_tok_hf = {
            {
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(28958, 32194), PARA(3, 3, 3) },
            }, {
                { CDF2(32132, 32735), PARA(1, 2, 2) },
                { CDF2(32555, 32745), PARA(3, 3, 3) },
                { CDF2(32458, 32729), PARA(3, 3, 3) },
            }, {
                { CDF2(32617, 32754), PARA(3, 3, 3) },
                { CDF2(32699, 32756), PARA(3, 3, 3) },
                { CDF2(32695, 32756), PARA(3, 3, 3) },
            }, {
                { CDF2(32684, 32756), PARA(3, 3, 3) },
                { CDF2(32552, 32756), PARA(2, 0, 2) },
                { CDF2(32589, 32756), PARA(3, 2, 2) },
            }, {
                { CDF2(32687, 32756), PARA(3, 3, 3) },
                { CDF2(32716, 32756), PARA(3, 3, 1) },
                { CDF2(31504, 32715), PARA(0, 1, 1) },
            }
        }, .eob_base_y_tok_lf = {
            {
                { CDF4(29573, 32066, 32477, 32625), PARA(3, 2, 1) },
                { CDF4(28827, 32168, 32643, 32735), PARA(3, 3, 2) },
                { CDF4(29362, 32299, 32653, 32722), PARA(3, 2, 2) },
                { CDF4(29765, 32457, 32711, 32740), PARA(3, 3, 2) },
            }, {
                { CDF4(29324, 32291, 32617, 32714), PARA(2, 2, 2) },
                { CDF4(31938, 32652, 32728, 32740), PARA(3, 2, 2) },
                { CDF4(31949, 32673, 32738, 32742), PARA(3, 2, 2) },
                { CDF4(31802, 32666, 32744, 32748), PARA(3, 2, 3) },
            }, {
                { CDF4(28567, 31870, 32438, 32629), PARA(2, 1, 1) },
                { CDF4(32100, 32663, 32732, 32740), PARA(3, 2, 2) },
                { CDF4(32648, 32724, 32744, 32748), PARA(3, 1, 3) },
                { CDF4(25565, 32000, 32473, 32709), PARA(0, 0, 2) },
            }, {
                { CDF4(26412, 30605, 31764, 32230), PARA(1, 0, 0) },
                { CDF4(32167, 32698, 32744, 32748), PARA(3, 3, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            }, {
                { CDF4(24457, 29221, 30907, 31726), PARA(0, 0, 0) },
                { CDF4(32052, 32690, 32737, 32741), PARA(3, 3, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            },
        }, .base_y_tok_hf = {
            {
                {
                    { CDF3(16644, 29920, 32210), PARA(2, 2, 2) },
                    { CDF3( 8472, 27835, 32053), PARA(2, 1, 3) },
                }, {
                    { CDF3(12684, 27992, 31958), PARA(2, 3, 2) },
                    { CDF3( 1352, 23985, 31355), PARA(2, 2, 2) },
                }, {
                    { CDF3( 6935, 20786, 28614), PARA(3, 3, 2) },
                    { CDF3( 1491, 14175, 25464), PARA(2, 3, 3) },
                }, {
                    { CDF3( 4284, 13084, 20147), PARA(3, 3, 3) },
                    { CDF3(  506,  8831, 17788), PARA(3, 3, 2) },
                }, {
                    { CDF3( 2473, 16075, 19166), PARA(3, 3, 2) },
                    { CDF3( 2070,  4484,  8278), PARA(1, 3, 0) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(31137, 32587, 32685), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(13651, 25517, 30395), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7870, 18277, 25280), PARA(3, 2, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 3433,  9986, 16852), PARA(2, 3, 0) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(25281, 32546, 32739), PARA(3, 3, 2) },
                    { CDF3(13926, 31641, 32699), PARA(3, 2, 2) },
                }, {
                    { CDF3(19473, 31423, 32614), PARA(3, 3, 2) },
                    { CDF3(   98, 28106, 32308), PARA(3, 3, 2) },
                }, {
                    { CDF3(14245, 28210, 31761), PARA(3, 2, 3) },
                    { CDF3(  186, 23144, 30686), PARA(3, 2, 2) },
                }, {
                    { CDF3( 8755, 22554, 29121), PARA(3, 2, 3) },
                    { CDF3(  312, 17032, 27163), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5207, 15042, 22350), PARA(3, 2, 3) },
                    { CDF3(  383, 10485, 19689), PARA(3, 2, 3) },
                }, {
                    { CDF3(27697, 32637, 32746), PARA(3, 3, 2) },
                    { CDF3(19828, 32280, 32729), PARA(2, 2, 2) },
                }, {
                    { CDF3(20895, 31709, 32601), PARA(3, 3, 3) },
                    { CDF3(  706, 29097, 32430), PARA(3, 2, 2) },
                }, {
                    { CDF3(14671, 28816, 32008), PARA(2, 2, 3) },
                    { CDF3(  547, 23747, 31087), PARA(3, 2, 2) },
                }, {
                    { CDF3( 8923, 23097, 29710), PARA(3, 3, 3) },
                    { CDF3(  217, 17350, 27724), PARA(3, 2, 2) },
                }, {
                    { CDF3( 5346, 16046, 24143), PARA(3, 2, 3) },
                    { CDF3(  362, 12099, 22064), PARA(3, 2, 3) },
                }, {
                    { CDF3(26664, 32524, 32729), PARA(2, 2, 2) },
                    { CDF3(19929, 32241, 32732), PARA(2, 1, 2) },
                }, {
                    { CDF3(20429, 31546, 32587), PARA(3, 2, 3) },
                    { CDF3(  871, 29224, 32427), PARA(3, 2, 2) },
                }, {
                    { CDF3(15091, 29302, 32181), PARA(3, 3, 3) },
                    { CDF3(  420, 24224, 31315), PARA(3, 2, 2) },
                }, {
                    { CDF3( 9650, 24609, 30553), PARA(3, 3, 3) },
                    { CDF3(  716, 18899, 28798), PARA(3, 2, 3) },
                }, {
                    { CDF3( 6228, 18247, 26011), PARA(3, 3, 3) },
                    { CDF3(  488, 12960, 23566), PARA(3, 3, 3) },
                }, {
                    { CDF3(31458, 32658, 32742), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(20693, 30846, 32296), PARA(3, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(12771, 25313, 29851), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7602, 19024, 25601), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 4692, 14076, 20351), PARA(2, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(26646, 32618, 32748), PARA(3, 2, 2) },
                    { CDF3(12985, 32023, 32728), PARA(3, 2, 2) },
                }, {
                    { CDF3(21678, 31945, 32675), PARA(3, 3, 3) },
                    { CDF3(   46, 29649, 32565), PARA(2, 2, 2) },
                }, {
                    { CDF3(16813, 29938, 32304), PARA(3, 2, 2) },
                    { CDF3(  734, 25488, 31518), PARA(2, 2, 2) },
                }, {
                    { CDF3(10047, 24573, 30320), PARA(3, 2, 3) },
                    { CDF3(  680, 18741, 28408), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5428, 16010, 23347), PARA(3, 2, 2) },
                    { CDF3(  282, 11635, 21016), PARA(3, 2, 3) },
                }, {
                    { CDF3(29492, 32711, 32748), PARA(3, 3, 2) },
                    { CDF3(22856, 32581, 32748), PARA(3, 3, 2) },
                }, {
                    { CDF3(23814, 32473, 32732), PARA(3, 2, 2) },
                    { CDF3(  505, 30842, 32654), PARA(3, 2, 2) },
                }, {
                    { CDF3(17970, 30664, 32542), PARA(2, 2, 2) },
                    { CDF3(  591, 26988, 31983), PARA(2, 2, 2) },
                }, {
                    { CDF3(10731, 25646, 30915), PARA(3, 2, 2) },
                    { CDF3(  716, 19981, 29261), PARA(3, 2, 3) },
                }, {
                    { CDF3( 5897, 17573, 25080), PARA(3, 2, 2) },
                    { CDF3(  178, 12954, 22725), PARA(3, 3, 2) },
                }, {
                    { CDF3(30940, 32740, 32748), PARA(2, 2, 2) },
                    { CDF3(27493, 32693, 32748), PARA(2, 1, 2) },
                }, {
                    { CDF3(25557, 32571, 32738), PARA(3, 3, 2) },
                    { CDF3( 1156, 31536, 32692), PARA(3, 3, 2) },
                }, {
                    { CDF3(19676, 31438, 32631), PARA(3, 2, 2) },
                    { CDF3( 1853, 28395, 32266), PARA(3, 2, 3) },
                }, {
                    { CDF3(12168, 27322, 31648), PARA(3, 3, 3) },
                    { CDF3(  374, 21862, 30426), PARA(3, 2, 3) },
                }, {
                    { CDF3( 6908, 19494, 27071), PARA(3, 2, 3) },
                    { CDF3(  113, 14821, 25176), PARA(3, 3, 2) },
                }, {
                    { CDF3(32313, 32737, 32748), PARA(1, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(23711, 32006, 32620), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(16041, 28992, 31635), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 9990, 23637, 29213), PARA(2, 1, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 5762, 16053, 22500), PARA(2, 1, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(27184, 32672, 32748), PARA(2, 2, 1) },
                    { CDF3(10613, 32252, 32738), PARA(3, 2, 2) },
                }, {
                    { CDF3(22470, 32091, 32716), PARA(3, 2, 2) },
                    { CDF3(  949, 30238, 32643), PARA(3, 1, 2) },
                }, {
                    { CDF3(17935, 30422, 32413), PARA(2, 2, 2) },
                    { CDF3(  674, 26736, 32008), PARA(3, 1, 2) },
                }, {
                    { CDF3(11011, 25612, 30643), PARA(3, 3, 2) },
                    { CDF3(  997, 19957, 28943), PARA(3, 3, 2) },
                }, {
                    { CDF3( 4754, 13518, 19616), PARA(3, 2, 2) },
                    { CDF3(   30, 10027, 18226), PARA(3, 2, 1) },
                }, {
                    { CDF3(29734, 32729, 32748), PARA(2, 2, 2) },
                    { CDF3(17868, 32552, 32748), PARA(2, 2, 2) },
                }, {
                    { CDF3(25168, 32565, 32739), PARA(3, 2, 1) },
                    { CDF3(  525, 31274, 32689), PARA(3, 2, 1) },
                }, {
                    { CDF3(19155, 30941, 32493), PARA(3, 2, 2) },
                    { CDF3( 1986, 27740, 32084), PARA(3, 2, 2) },
                }, {
                    { CDF3(10959, 25516, 30465), PARA(3, 2, 2) },
                    { CDF3(  233, 20155, 29122), PARA(3, 1, 1) },
                }, {
                    { CDF3( 4681, 14503, 21334), PARA(2, 2, 2) },
                    { CDF3(  483, 10679, 18885), PARA(3, 2, 2) },
                }, {
                    { CDF3(31907, 32752, 32756), PARA(2, 2, 2) },
                    { CDF3(31874, 32719, 32748), PARA(3, 2, 2) },
                }, {
                    { CDF3(26499, 32598, 32736), PARA(3, 3, 2) },
                    { CDF3( 4327, 31612, 32678), PARA(3, 3, 3) },
                }, {
                    { CDF3(20964, 31523, 32599), PARA(3, 2, 2) },
                    { CDF3( 1451, 28828, 32263), PARA(3, 3, 2) },
                }, {
                    { CDF3(12822, 27283, 31369), PARA(3, 2, 3) },
                    { CDF3(  336, 21868, 30060), PARA(3, 2, 2) },
                }, {
                    { CDF3( 6252, 17633, 24699), PARA(3, 3, 3) },
                    { CDF3(  465, 12979, 22414), PARA(3, 3, 3) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(27513, 32649, 32748), PARA(2, 1, 1) },
                    { CDF3(12533, 32080, 32727), PARA(2, 2, 2) },
                }, {
                    { CDF3(22267, 31858, 32685), PARA(3, 1, 2) },
                    { CDF3(  475, 29885, 32524), PARA(2, 3, 2) },
                }, {
                    { CDF3(17673, 30194, 32223), PARA(2, 2, 1) },
                    { CDF3( 1643, 25673, 31224), PARA(2, 2, 1) },
                }, {
                    { CDF3(10022, 24035, 29658), PARA(3, 2, 2) },
                    { CDF3(  276, 18877, 27751), PARA(2, 1, 1) },
                }, {
                    { CDF3( 4529, 13192, 18915), PARA(3, 2, 1) },
                    { CDF3(  285,  9212, 16975), PARA(3, 2, 1) },
                }, {
                    { CDF3(29967, 32707, 32748), PARA(2, 1, 1) },
                    { CDF3(15326, 32376, 32746), PARA(2, 3, 2) },
                }, {
                    { CDF3(24351, 32244, 32717), PARA(2, 2, 1) },
                    { CDF3( 1649, 31057, 32684), PARA(2, 2, 2) },
                }, {
                    { CDF3(17832, 30408, 32381), PARA(2, 1, 1) },
                    { CDF3( 1876, 26558, 31696), PARA(1, 1, 1) },
                }, {
                    { CDF3(10499, 24843, 30081), PARA(3, 2, 2) },
                    { CDF3( 1028, 19460, 28542), PARA(2, 2, 1) },
                }, {
                    { CDF3( 5050, 14590, 21227), PARA(3, 2, 2) },
                    { CDF3(   92, 10933, 19446), PARA(2, 1, 1) },
                }, {
                    { CDF3(31604, 32752, 32756), PARA(3, 2, 2) },
                    { CDF3(32163, 32722, 32748), PARA(3, 3, 2) },
                }, {
                    { CDF3(26537, 32585, 32739), PARA(3, 2, 2) },
                    { CDF3( 5518, 31656, 32695), PARA(3, 3, 2) },
                }, {
                    { CDF3(20484, 31396, 32601), PARA(3, 2, 2) },
                    { CDF3( 1028, 28479, 32227), PARA(3, 2, 3) },
                }, {
                    { CDF3(12807, 27291, 31420), PARA(3, 3, 3) },
                    { CDF3(  469, 22186, 30263), PARA(3, 2, 2) },
                }, {
                    { CDF3( 6722, 18261, 25292), PARA(3, 3, 2) },
                    { CDF3(   57, 13631, 22880), PARA(3, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            },
        }, .base_y_tok_lf = {
            {
                {
                    { CDF5( 3361, 19325, 24366, 31088, 31928), PARA(0, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1632, 15337, 24150, 28503, 30563), PARA(2, 2, 0) },
                    { CDF5(    4,  5295, 20829, 28126, 30850), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6632, 16063, 23298, 27040, 29721), PARA(2, 2, 3) },
                    { CDF5(    4, 11374, 19507, 24923, 28568), PARA(1, 2, 2) },
                }, {
                    { CDF5( 4909, 11090, 17838, 22385, 26279), PARA(2, 3, 2) },
                    { CDF5(   35,  6017, 15862, 22480, 26459), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3589,  9811, 14531, 19054, 22695), PARA(2, 2, 3) },
                    { CDF5(    4,  6364,  9855, 16927, 21591), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2743,  7444, 12418, 15058, 19040), PARA(2, 2, 2) },
                    { CDF5(    6,  2870,  8495, 12527, 16693), PARA(2, 3, 3) },
                }, {
                    { CDF5( 1596,  6378, 10210, 14940, 17169), PARA(3, 3, 3) },
                    { CDF5(    4,  1626,  3090,  7519,  9718), PARA(2, 3, 3) },
                }, {
                    { CDF5(  648,  4541,  7588, 11572, 14642), PARA(2, 1, 2) },
                    { CDF5(    5,  3893,  6075,  9405, 12116), PARA(2, 3, 3) },
                }, {
                    { CDF5( 1519,  3450,  5055,  6173,  7170), PARA(2, 1, 3) },
                    { CDF5(    5,  2567,  3706,  7533,  9113), PARA(3, 3, 2) },
                }, {
                    { CDF5(14288, 28805, 31683, 32583, 32700), PARA(3, 2, 3) },
                    { CDF5(   64, 24516, 31405, 32371, 32655), PARA(2, 1, 1) },
                }, {
                    { CDF5( 8353, 22447, 29049, 31579, 32315), PARA(3, 2, 3) },
                    { CDF5(    4, 16982, 27998, 31526, 32421), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7498, 18802, 25718, 29605, 31419), PARA(3, 2, 2) },
                    { CDF5(    4, 13992, 23750, 28392, 31093), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5931, 15139, 22182, 27418, 29974), PARA(3, 2, 3) },
                    { CDF5(    4, 12206, 21157, 26583, 29002), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4417, 12408, 19565, 24937, 27743), PARA(2, 2, 2) },
                    { CDF5(    6,  8793, 17130, 22092, 26855), PARA(2, 2, 1) },
                }, {
                    { CDF5( 3697, 10293, 16641, 21345, 25242), PARA(3, 2, 3) },
                    { CDF5(    4,  7551, 14182, 20667, 25647), PARA(2, 3, 3) },
                }, {
                    { CDF5( 3788, 10092, 15480, 20531, 23568), PARA(3, 2, 1) },
                    { CDF5(   30,  4783, 10714, 16396, 20863), PARA(2, 2, 2) },
                }, {
                    { CDF5(18808, 30564, 32414, 32708, 32732), PARA(3, 3, 3) },
                    { CDF5( 8341, 26149, 31856, 32628, 32726), PARA(2, 2, 3) },
                }, {
                    { CDF5(13189, 27414, 31625, 32526, 32712), PARA(3, 3, 2) },
                    { CDF5(   95, 21665, 30252, 32221, 32614), PARA(2, 2, 3) },
                }, {
                    { CDF5( 9837, 22542, 28890, 31327, 32298), PARA(3, 2, 3) },
                    { CDF5(    6, 16453, 26512, 30728, 32308), PARA(3, 2, 2) },
                }, {
                    { CDF5( 7017, 18407, 25212, 29652, 31622), PARA(3, 2, 3) },
                    { CDF5(   31, 11962, 22617, 28211, 31109), PARA(3, 2, 2) },
                }, {
                    { CDF5( 5446, 14294, 21338, 26300, 29677), PARA(3, 2, 3) },
                    { CDF5(  156,  8220, 17040, 23841, 28514), PARA(3, 2, 3) },
                }, {
                    { CDF5(24803, 31286, 32079, 32381, 32540), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(12821, 26214, 30050, 31373, 31972), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7896, 17264, 23904, 27850, 29752), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7045, 14770, 19995, 23659, 26108), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2310,  6418, 12150, 16868, 20631), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1672,  5533, 10030, 13735, 17567), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1219,  4524,  7028, 10416, 13388), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(29688, 32425, 32651, 32731, 32735), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(15856, 26584, 30786, 32053, 32570), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 8823, 17890, 24454, 28342, 30615), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7001, 15331, 21333, 25485, 28372), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3542, 10300, 15274, 19865, 23271), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(20460, 32339, 32513, 32662, 32732), PARA(2, 0, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(  283, 17174, 26580, 30375, 31638), PARA(3, 2, 2) },
                    { CDF5(    4,  5576, 21745, 28213, 30821), PARA(3, 2, 2) },
                }, {
                    { CDF5(11048, 22170, 26485, 29197, 30921), PARA(2, 2, 2) },
                    { CDF5(    4, 16199, 25093, 29139, 30504), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6377, 13511, 19779, 25102, 28132), PARA(2, 2, 2) },
                    { CDF5(    4,  7377, 18122, 23594, 27200), PARA(3, 2, 3) },
                }, {
                    { CDF5( 4500, 10287, 15895, 21180, 24672), PARA(2, 2, 2) },
                    { CDF5(   16,  5691, 12262, 17802, 21695), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2790,  7843, 12604, 16931, 20564), PARA(3, 3, 3) },
                    { CDF5(    4,  4821,  9847, 13980, 18278), PARA(3, 3, 1) },
                }, {
                    { CDF5( 1381,  7439, 10964, 14802, 18073), PARA(3, 2, 1) },
                    { CDF5( 1522,  2450,  6619, 10499, 14157), PARA(2, 3, 1) },
                }, {
                    { CDF5( 2025,  5643,  8935, 12150, 14843), PARA(3, 3, 2) },
                    { CDF5(  224,  2917,  6661, 10512, 13337), PARA(3, 3, 2) },
                }, {
                    { CDF5( 1368,  3825,  6654,  9038, 11091), PARA(3, 3, 2) },
                    { CDF5(   41,  2582,  5312,  7720, 10479), PARA(3, 3, 2) },
                }, {
                    { CDF5(20410, 31676, 32514, 32692, 32732), PARA(3, 1, 2) },
                    { CDF5(25631, 26346, 32305, 32649, 32732), PARA(2, 1, 1) },
                }, {
                    { CDF5( 9017, 26371, 30820, 32288, 32624), PARA(3, 2, 2) },
                    { CDF5(    4, 20642, 29893, 32138, 32626), PARA(2, 2, 2) },
                }, {
                    { CDF5(11957, 24371, 29434, 31605, 32329), PARA(3, 3, 2) },
                    { CDF5(    4, 19715, 28037, 30945, 32081), PARA(2, 2, 1) },
                }, {
                    { CDF5( 6587, 17392, 24549, 28765, 30910), PARA(3, 2, 2) },
                    { CDF5(    4, 13017, 22846, 28010, 30563), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4820, 13076, 20235, 25274, 28367), PARA(3, 3, 2) },
                    { CDF5(    4,  9517, 18022, 23590, 27505), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3839, 11042, 17152, 22327, 25816), PARA(3, 3, 3) },
                    { CDF5(    4,  7434, 14558, 20495, 24720), PARA(3, 3, 2) },
                }, {
                    { CDF5( 3178,  9048, 14018, 18246, 21456), PARA(3, 3, 3) },
                    { CDF5(   41,  4587,  9592, 14488, 18984), PARA(3, 2, 2) },
                }, {
                    { CDF5(24602, 32389, 32700, 32736, 32740), PARA(3, 2, 2) },
                    { CDF5( 7626, 30290, 32589, 32730, 32734), PARA(3, 2, 2) },
                }, {
                    { CDF5(17206, 30451, 32404, 32696, 32732), PARA(3, 3, 2) },
                    { CDF5(    4, 26159, 31880, 32631, 32732), PARA(3, 2, 2) },
                }, {
                    { CDF5(12799, 26717, 31223, 32384, 32678), PARA(3, 2, 2) },
                    { CDF5(    4, 21576, 29603, 32028, 32595), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7923, 20676, 27760, 30909, 32092), PARA(3, 2, 3) },
                    { CDF5(   10, 15320, 25351, 29888, 31811), PARA(3, 2, 3) },
                }, {
                    { CDF5( 4552, 13193, 20089, 24958, 28270), PARA(3, 2, 3) },
                    { CDF5(   29,  9104, 17079, 23044, 27203), PARA(3, 2, 3) },
                }, {
                    { CDF5(29032, 32327, 32595, 32682, 32720), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(16965, 29286, 31651, 32307, 32527), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9346, 21389, 27317, 29974, 31327), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6585, 15649, 21693, 25674, 28044), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3417, 10093, 16159, 21188, 24606), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2304,  7456, 12293, 16563, 20267), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1811,  5284,  8853, 12277, 15769), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(30975, 32679, 32738, 32742, 32746), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(20345, 30725, 32278, 32643, 32726), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(12243, 25011, 29788, 31583, 32260), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 8494, 19928, 26600, 29501, 31142), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4992, 13924, 20358, 24637, 27524), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(24594, 32389, 32641, 32718, 32732), PARA(1, 0, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2358, 19217, 26997, 30649, 31793), PARA(2, 2, 1) },
                    { CDF5(    4, 10990, 24500, 28869, 31218), PARA(2, 1, 2) },
                }, {
                    { CDF5(12447, 24328, 28566, 30469, 31468), PARA(2, 2, 1) },
                    { CDF5(    4, 18559, 25929, 29452, 30837), PARA(2, 2, 1) },
                }, {
                    { CDF5( 6059, 14350, 21101, 25538, 28284), PARA(2, 2, 2) },
                    { CDF5(    4,  8626, 17947, 23810, 27621), PARA(2, 2, 1) },
                }, {
                    { CDF5( 3725, 10288, 16087, 20666, 24016), PARA(3, 2, 2) },
                    { CDF5(    4,  6533, 12288, 17848, 22413), PARA(3, 1, 2) },
                }, {
                    { CDF5( 2171,  7502, 12172, 15887, 19156), PARA(2, 2, 2) },
                    { CDF5(    7,  5094,  9919, 14712, 18887), PARA(3, 3, 2) },
                }, {
                    { CDF5( 2182,  6455, 10199, 13836, 17142), PARA(3, 2, 2) },
                    { CDF5(    4,  4141,  8300, 12354, 15957), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1639,  5232,  8372, 11445, 14349), PARA(3, 2, 2) },
                    { CDF5(   10,  3077,  6545, 10446, 13509), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1084,  4304,  6721,  9558, 11647), PARA(3, 2, 2) },
                    { CDF5(  545,  1846,  4045,  6508,  8619), PARA(2, 3, 2) },
                }, {
                    { CDF5(24344, 31910, 32550, 32682, 32732), PARA(3, 0, 1) },
                    { CDF5(26511, 26812, 32257, 32605, 32732), PARA(2, 1, 1) },
                }, {
                    { CDF5(11758, 27192, 31302, 32386, 32693), PARA(3, 2, 1) },
                    { CDF5(    4, 22871, 30546, 32311, 32672), PARA(3, 2, 1) },
                }, {
                    { CDF5(14135, 26534, 30495, 32044, 32475), PARA(2, 2, 1) },
                    { CDF5(    4, 20045, 27213, 30377, 31787), PARA(2, 1, 2) },
                }, {
                    { CDF5( 7076, 18263, 25043, 28687, 30681), PARA(3, 2, 3) },
                    { CDF5(    4, 13464, 22336, 27466, 30144), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4633, 13655, 20720, 25269, 27732), PARA(3, 3, 2) },
                    { CDF5(    4,  8679, 16355, 22272, 26693), PARA(3, 3, 2) },
                }, {
                    { CDF5( 3748, 10999, 17182, 22075, 25415), PARA(3, 2, 2) },
                    { CDF5(    4,  7508, 14197, 19726, 24108), PARA(3, 3, 2) },
                }, {
                    { CDF5( 2184,  7460, 12244, 16404, 19473), PARA(3, 2, 2) },
                    { CDF5(   69,  5366, 10343, 14774, 18517), PARA(3, 2, 1) },
                }, {
                    { CDF5(25069, 32379, 32715, 32736, 32740), PARA(3, 3, 2) },
                    { CDF5( 5129, 30522, 32636, 32736, 32740), PARA(3, 2, 2) },
                }, {
                    { CDF5(19064, 30841, 32497, 32710, 32732), PARA(3, 2, 2) },
                    { CDF5(    4, 27337, 32042, 32655, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(15344, 28138, 31636, 32491, 32707), PARA(2, 2, 2) },
                    { CDF5(   10, 23734, 30387, 32192, 32638), PARA(2, 2, 2) },
                }, {
                    { CDF5( 8553, 21612, 28244, 31035, 32141), PARA(3, 3, 3) },
                    { CDF5(    4, 16669, 26367, 30466, 32062), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4707, 13756, 20729, 25449, 28537), PARA(3, 2, 2) },
                    { CDF5(    9,  9798, 18016, 23799, 27538), PARA(3, 2, 2) },
                }, {
                    { CDF5(30472, 32430, 32636, 32704, 32730), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(16740, 29432, 31724, 32306, 32530), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9770, 21395, 26819, 29645, 31040), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5883, 13836, 19460, 22882, 25424), PARA(2, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3255,  9742, 15113, 19977, 23209), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2318,  6734, 11462, 15492, 18969), PARA(3, 3, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1344,  4886,  8490, 11147, 13803), PARA(2, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(31970, 32735, 32740, 32744, 32748), PARA(2, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(21766, 31615, 32549, 32682, 32732), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(14071, 27537, 31162, 32180, 32564), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9394, 22451, 28320, 30624, 31619), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6357, 16098, 22083, 26080, 28701), PARA(3, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(22670, 31040, 32062, 32396, 32494), PARA(0, 0, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6204, 18887, 26106, 29994, 31527), PARA(2, 2, 1) },
                    { CDF5(    4, 13216, 24238, 29218, 31178), PARA(2, 2, 2) },
                }, {
                    { CDF5(10730, 22881, 27929, 30084, 31344), PARA(1, 2, 2) },
                    { CDF5(    4, 18763, 26180, 29027, 30353), PARA(1, 2, 1) },
                }, {
                    { CDF5( 4419, 14204, 19910, 24823, 27593), PARA(2, 1, 1) },
                    { CDF5(    4,  9746, 17528, 23820, 27251), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3252,  8648, 14582, 18530, 21957), PARA(1, 1, 1) },
                    { CDF5(    4,  6941, 13319, 18486, 23105), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2193,  8919, 13231, 16176, 19402), PARA(3, 2, 2) },
                    { CDF5(  957,  4227,  8679, 14052, 18540), PARA(2, 2, 2) },
                }, {
                    { CDF5( 1055,  5756,  9129, 12574, 14838), PARA(1, 2, 1) },
                    { CDF5(  822,  4183,  8160, 12989, 16983), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2072,  7295, 11937, 15990, 18808), PARA(3, 3, 2) },
                    { CDF5( 1296,  1658,  4422,  5572,  8265), PARA(1, 2, 1) },
                }, {
                    { CDF5( 1733,  4681,  7680, 10654, 12528), PARA(3, 2, 2) },
                    { CDF5(    4,  1678,  2994,  4855,  6537), PARA(3, 2, 2) },
                }, {
                    { CDF5(24889, 31894, 32576, 32692, 32732), PARA(2, 1, 1) },
                    { CDF5( 7489, 28023, 32440, 32702, 32732), PARA(2, 0, 0) },
                }, {
                    { CDF5(13420, 28082, 31481, 32420, 32693), PARA(2, 2, 0) },
                    { CDF5(    4, 24196, 30708, 32346, 32682), PARA(2, 1, 2) },
                }, {
                    { CDF5(14158, 26101, 30271, 31760, 32366), PARA(2, 1, 2) },
                    { CDF5(    4, 20337, 27469, 30511, 31808), PARA(2, 1, 2) },
                }, {
                    { CDF5( 6545, 17433, 24600, 28570, 30488), PARA(2, 3, 2) },
                    { CDF5(    4, 14301, 23067, 27600, 30048), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4611, 12681, 19425, 24119, 27368), PARA(3, 2, 2) },
                    { CDF5(    6,  8765, 16411, 22190, 26422), PARA(3, 3, 2) },
                }, {
                    { CDF5( 3293, 10520, 16126, 21429, 23703), PARA(2, 2, 2) },
                    { CDF5(   13,  7300, 14277, 19168, 23448), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2464,  7343, 11864, 15738, 18418), PARA(3, 3, 2) },
                    { CDF5(   85,  4192,  8349, 12391, 15795), PARA(2, 2, 2) },
                }, {
                    { CDF5(26166, 32502, 32728, 32736, 32740), PARA(2, 2, 2) },
                    { CDF5( 4561, 31126, 32673, 32736, 32740), PARA(3, 2, 1) },
                }, {
                    { CDF5(19676, 30981, 32490, 32712, 32732), PARA(3, 2, 2) },
                    { CDF5(    5, 27917, 32248, 32677, 32732), PARA(2, 2, 1) },
                }, {
                    { CDF5(15573, 28642, 31918, 32572, 32718), PARA(2, 2, 1) },
                    { CDF5(   33, 24002, 30459, 32142, 32635), PARA(3, 1, 2) },
                }, {
                    { CDF5( 8718, 22161, 28870, 31388, 32324), PARA(3, 2, 1) },
                    { CDF5(   37, 17061, 26380, 30433, 31990), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4574, 13326, 20007, 24664, 27510), PARA(3, 2, 2) },
                    { CDF5(   75,  9240, 17009, 22503, 26129), PARA(3, 1, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(15828, 27456, 29866, 30952, 31512), PARA(0, 0, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4322, 17878, 25258, 29337, 30946), PARA(1, 1, 1) },
                    { CDF5(    4, 11985, 23302, 27957, 30495), PARA(2, 1, 1) },
                }, {
                    { CDF5( 9877, 22124, 26984, 29481, 30923), PARA(2, 2, 1) },
                    { CDF5(    4, 18007, 23542, 27862, 29724), PARA(2, 1, 0) },
                }, {
                    { CDF5( 4896, 15934, 20448, 22985, 25552), PARA(2, 1, 1) },
                    { CDF5(  882,  5246, 14586, 20929, 25166), PARA(1, 1, 1) },
                }, {
                    { CDF5( 2897, 11697, 15855, 19987, 22265), PARA(2, 2, 1) },
                    { CDF5(    4,  5352,  8285, 14883, 19798), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2550,  7215, 11328, 15219, 17984), PARA(2, 2, 3) },
                    { CDF5(    4,  4270,  8893, 12038, 15001), PARA(2, 3, 3) },
                }, {
                    { CDF5( 1976,  5938, 10048, 13248, 15220), PARA(2, 2, 1) },
                    { CDF5(   74,  2872,  5881,  8719, 12203), PARA(2, 2, 3) },
                }, {
                    { CDF5( 1557,  5182,  7687, 10041, 12530), PARA(2, 3, 3) },
                    { CDF5(  302,  3173,  6064,  9146, 12139), PARA(2, 3, 1) },
                }, {
                    { CDF5( 1041,  2835,  4612,  6619,  7701), PARA(3, 2, 2) },
                    { CDF5(  284,  1622,  3979,  5622,  7317), PARA(3, 2, 2) },
                }, {
                    { CDF5(23459, 31826, 32523, 32706, 32732), PARA(1, 1, 0) },
                    { CDF5( 4370, 28739, 32302, 32698, 32732), PARA(1, 1, 2) },
                }, {
                    { CDF5(14211, 27544, 31308, 32252, 32647), PARA(2, 2, 2) },
                    { CDF5(    4, 24453, 30550, 32209, 32593), PARA(2, 2, 1) },
                }, {
                    { CDF5(13549, 26000, 29944, 31604, 32248), PARA(2, 2, 1) },
                    { CDF5(    4, 19875, 26915, 30003, 31480), PARA(2, 1, 1) },
                }, {
                    { CDF5( 6688, 18459, 24591, 28101, 29825), PARA(2, 2, 1) },
                    { CDF5(  956, 10175, 19300, 25085, 28308), PARA(2, 2, 1) },
                }, {
                    { CDF5( 4149, 12273, 18024, 22204, 25189), PARA(2, 2, 2) },
                    { CDF5(    4,  7907, 14615, 20513, 24277), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3084,  9362, 14515, 19060, 22086), PARA(2, 2, 2) },
                    { CDF5(  881,  5812, 11992, 16891, 21229), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2270,  6094,  9436, 13046, 15065), PARA(3, 3, 2) },
                    { CDF5(    4,  2628,  6124,  9042, 11413), PARA(2, 2, 1) },
                }, {
                    { CDF5(26213, 32584, 32715, 32736, 32740), PARA(1, 1, 1) },
                    { CDF5( 9595, 31175, 32663, 32736, 32740), PARA(3, 1, 1) },
                }, {
                    { CDF5(19100, 30551, 32351, 32675, 32732), PARA(3, 1, 2) },
                    { CDF5(   42, 27427, 31958, 32640, 32732), PARA(2, 2, 1) },
                }, {
                    { CDF5(14907, 27403, 31007, 32163, 32585), PARA(2, 2, 2) },
                    { CDF5(   74, 23383, 30040, 31948, 32492), PARA(2, 1, 1) },
                }, {
                    { CDF5( 8140, 21140, 27523, 30537, 31800), PARA(2, 2, 1) },
                    { CDF5(  601, 15748, 25003, 29331, 31277), PARA(2, 2, 1) },
                }, {
                    { CDF5( 3878, 11230, 17295, 21736, 24654), PARA(3, 2, 2) },
                    { CDF5(  267,  7839, 14608, 19822, 23499), PARA(3, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            },
        }, .dc_sign = {
            {
                { CDF1(17575), PARA(3, 2, 2) },
                { CDF1(14224), PARA(3, 2, 3) },
                { CDF1(19801), PARA(3, 3, 3) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }
        }, .br_y_tok_hf = {
            { CDF3(29897, 32392, 32630), PARA(1, 1, 2) },
            { CDF3(27484, 32113, 32486), PARA(2, 2, 3) },
            { CDF3(23979, 31279, 32028), PARA(2, 2, 3) },
            { CDF3(19126, 28997, 30760), PARA(2, 2, 3) },
            { CDF3(14329, 25240, 28412), PARA(2, 2, 2) },
            { CDF3(10861, 20773, 25861), PARA(3, 2, 2) },
            { CDF3( 7274, 15044, 21663), PARA(2, 2, 2) },
        }, .br_y_tok_lf = {
            { CDF3(13319, 21082, 26725), PARA(1, 0, 0) },
            { CDF3(15058, 23563, 27312), PARA(3, 2, 2) },
            { CDF3(12093, 21552, 24381), PARA(3, 3, 1) },
            { CDF3( 9847, 18914, 21611), PARA(3, 2, 1) },
            { CDF3( 6984, 14207, 17984), PARA(3, 2, 2) },
            { CDF3( 5580, 11627, 15411), PARA(3, 2, 2) },
            { CDF3( 3907,  8590, 10683), PARA(3, 1, 1) },
            { CDF3(19858, 26499, 28738), PARA(1, 1, 1) },
            { CDF3(19608, 28127, 30429), PARA(2, 2, 2) },
            { CDF3(17478, 27390, 29446), PARA(2, 2, 2) },
            { CDF3(14848, 25124, 27561), PARA(2, 2, 2) },
            { CDF3(11376, 21082, 24410), PARA(3, 2, 2) },
            { CDF3( 9179, 17862, 21918), PARA(3, 3, 2) },
            { CDF3( 6435, 13300, 17660), PARA(3, 2, 2) },
        }, .ph_dc_y_tok = {
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
        }, .bob_base_y_tok = {
            {
                { CDF2(17507, 24673), PARA(3, 3, 2) },
                { CDF2(19003, 25281), PARA(3, 3, 2) },
                { CDF2(18718, 27145), PARA(2, 2, 2) },
            }, {
                { CDF2(22679, 29259), PARA(2, 3, 2) },
                { CDF2(24245, 30291), PARA(2, 2, 2) },
                { CDF2(25590, 31051), PARA(2, 2, 2) },
            }, {
                { CDF2(26844, 31178), PARA(2, 1, 1) },
                { CDF2(28524, 31813), PARA(2, 2, 1) },
                { CDF2(29430, 32097), PARA(2, 2, 1) },
            },
        }, .br_y_tok_idtx = {
            {
                { CDF3(15586, 23809, 28480), PARA(1, 1, 1) },
                { CDF3(13137, 22338, 27776), PARA(1, 2, 1) },
                { CDF3(12960, 20989, 27007), PARA(2, 2, 1) },
                { CDF3(14487, 22004, 26872), PARA(2, 2, 1) },
                { CDF3( 8977, 19506, 25832), PARA(2, 2, 1) },
                { CDF3( 6689, 13456, 20960), PARA(2, 1, 0) },
                { CDF3( 3660,  8043, 13467), PARA(2, 2, 2) },
            }, {
                { CDF3(19250, 25820, 29038), PARA(1, 1, 1) },
                { CDF3(20479, 27597, 30639), PARA(1, 1, 1) },
                { CDF3(19284, 26800, 30037), PARA(1, 2, 1) },
                { CDF3(19120, 26676, 30033), PARA(1, 1, 1) },
                { CDF3(14799, 24819, 29256), PARA(1, 1, 1) },
                { CDF3(10041, 18099, 24102), PARA(1, 1, 1) },
                { CDF3( 6659, 13728, 19983), PARA(1, 1, 1) },
            }, {
                { CDF3(18981, 24347, 27397), PARA(1, 1, 0) },
                { CDF3(22083, 28198, 30532), PARA(1, 1, 0) },
                { CDF3(21589, 28346, 30716), PARA(1, 1, 0) },
                { CDF3(22576, 28726, 31113), PARA(1, 1, 0) },
                { CDF3(17332, 27607, 30702), PARA(1, 0, 0) },
                { CDF3(10788, 18280, 24206), PARA(1, 1, 0) },
                { CDF3( 7269, 15134, 21954), PARA(0, 0, 0) },
            },
        }, .base_y_tok_idtx = {
            {
                { CDF3(29171, 31341, 32069), PARA(2, 2, 3) },
                { CDF3(19097, 27499, 29866), PARA(3, 2, 2) },
                { CDF3(16660, 23539, 28386), PARA(2, 2, 2) },
                { CDF3(13020, 18986, 22564), PARA(2, 1, 2) },
                { CDF3( 6762, 13469, 18997), PARA(1, 1, 1) },
                { CDF3( 5230,  9452, 15176), PARA(1, 1, 0) },
                { CDF3( 3282,  5921,  7884), PARA(1, 1, 1) },
            }, {
                { CDF3(31506, 32472, 32667), PARA(3, 2, 2) },
                { CDF3(20403, 29740, 31743), PARA(2, 2, 3) },
                { CDF3(14938, 24923, 30084), PARA(2, 2, 2) },
                { CDF3(10891, 19070, 24198), PARA(1, 1, 2) },
                { CDF3( 4812, 12877, 20442), PARA(1, 1, 1) },
                { CDF3( 3269,  8035, 14577), PARA(1, 1, 1) },
                { CDF3( 2373,  5157,  8269), PARA(1, 1, 1) },
            }, {
                { CDF3(32371, 32695, 32745), PARA(3, 2, 2) },
                { CDF3(21598, 31049, 32391), PARA(2, 2, 2) },
                { CDF3(14515, 26494, 31233), PARA(1, 1, 1) },
                { CDF3(11239, 19165, 24574), PARA(1, 1, 1) },
                { CDF3( 4137, 12390, 21147), PARA(1, 1, 0) },
                { CDF3( 2658,  7002, 14001), PARA(1, 1, 1) },
                { CDF3( 2391,  5537,  8704), PARA(1, 2, 1) },
            },
        }, .sign_idtx = {
            {
                { CDF1(20565), PARA(2, 2, 2) },
                { CDF1(28478), PARA(1, 2, 2) },
                { CDF1( 8011), PARA(2, 3, 2) },
                { CDF1(31569), PARA(0, 1, 1) },
                { CDF1( 9937), PARA(1, 1, 1) },
                { CDF1(32166), PARA(3, 2, 3) },
                { CDF1( 4360), PARA(3, 1, 3) },
                { CDF1(32715), PARA(1, 0, 3) },
                { CDF1( 2253), PARA(1, 3, 3) },
            }, {
                { CDF1(21616), PARA(1, 2, 1) },
                { CDF1(29474), PARA(1, 2, 2) },
                { CDF1( 8169), PARA(1, 2, 2) },
                { CDF1(31873), PARA(0, 1, 1) },
                { CDF1( 6252), PARA(1, 1, 1) },
                { CDF1(32360), PARA(2, 3, 3) },
                { CDF1( 2458), PARA(2, 2, 2) },
                { CDF1(32719), PARA(0, 2, 0) },
                { CDF1(  682), PARA(0, 3, 3) },
            }, {
                { CDF1(22816), PARA(1, 1, 1) },
                { CDF1(30531), PARA(1, 2, 1) },
                { CDF1( 5700), PARA(1, 1, 1) },
                { CDF1(31507), PARA(0, 0, 0) },
                { CDF1( 1539), PARA(0, 0, 0) },
                { CDF1(32572), PARA(1, 2, 1) },
                { CDF1( 1015), PARA(1, 1, 0) },
                { CDF1(32694), PARA(1, 0, 2) },
                { CDF1(  412), PARA(1, 0, 0) },
            },
        }, .skip_v = {
            { CDF1(  777), PARA(3, 3, 3) },
            { CDF1( 6871), PARA(3, 2, 2) },
            { CDF1(15620), PARA(2, 2, 2) },
            { CDF1( 1146), PARA(1, 0, 2) },
            { CDF1(14000), PARA(1, 2, 2) },
            { CDF1(24576), PARA(0, 2, 2) },
            { CDF1( 4536), PARA(3, 3, 2) },
            { CDF1(13035), PARA(3, 2, 2) },
            { CDF1(21755), PARA(3, 2, 2) },
            { CDF1( 5906), PARA(1, 0, 2) },
            { CDF1(18536), PARA(1, 2, 2) },
            { CDF1(26466), PARA(0, 2, 2) },
        }, .eob_base_uv_tok_hf = {
            { CDF2(32086, 32691), PARA(3, 3, 3) },
            { CDF2(32538, 32743), PARA(3, 3, 3) },
            { CDF2(32512, 32730), PARA(3, 3, 3) },
        }, .base_uv_tok_hf = {
            { CDF3(26928, 32457, 32720), PARA(3, 2, 2) },
            { CDF3(16472, 30015, 32195), PARA(3, 2, 2) },
            { CDF3( 9599, 22905, 28625), PARA(3, 2, 2) },
            { CDF3( 4866, 13616, 20435), PARA(3, 2, 2) },
            { CDF3(27711, 32490, 32726), PARA(3, 2, 2) },
            { CDF3(16379, 30167, 32197), PARA(3, 2, 2) },
            { CDF3( 9085, 22146, 28034), PARA(2, 2, 1) },
            { CDF3( 3893, 11359, 17565), PARA(3, 2, 2) },
            { CDF3(30658, 32684, 32748), PARA(3, 3, 2) },
            { CDF3(22171, 31876, 32636), PARA(3, 3, 2) },
            { CDF3(10726, 23535, 29193), PARA(2, 3, 0) },
            { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
        }, .br_uv_tok_hf = {
            { CDF3(26645, 31153, 32251), PARA(3, 2, 3) },
            { CDF3(23320, 29627, 31652), PARA(3, 3, 2) },
            { CDF3(18265, 26040, 29663), PARA(3, 2, 2) },
            { CDF3(11140, 18504, 23213), PARA(2, 2, 1) },
        }, .eob_base_uv_tok_lf = {
            { CDF4(30964, 32463, 32673, 32733), PARA(3, 2, 2) },
            { CDF4(31731, 32623, 32730, 32740), PARA(2, 2, 1) },
            { CDF4(30879, 32453, 32716, 32740), PARA(2, 3, 1) },
        }, .base_uv_tok_lf = {
            { CDF5(14853, 28192, 31400, 32275, 32557), PARA(2, 2, 1) },
            { CDF5(10499, 24975, 30136, 31803, 32399), PARA(3, 2, 2) },
            { CDF5( 5543, 15727, 22759, 27080, 29613), PARA(3, 2, 2) },
            { CDF5( 2214,  6634, 11179, 15534, 19289), PARA(3, 3, 2) },
            { CDF5(15032, 28602, 31421, 32234, 32548), PARA(2, 2, 2) },
            { CDF5(10857, 24883, 29885, 31603, 32255), PARA(2, 2, 2) },
            { CDF5( 5068, 14275, 20979, 25484, 28338), PARA(2, 2, 2) },
            { CDF5( 1825,  5574,  9437, 13284, 16813), PARA(3, 3, 3) },
            { CDF5(28668, 32450, 32696, 32736, 32740), PARA(2, 3, 2) },
            { CDF5(17386, 30911, 32385, 32652, 32732), PARA(3, 3, 2) },
            { CDF5( 9471, 20994, 27290, 30512, 31784), PARA(2, 3, 2) },
            { CDF5( 7211, 13700, 19148, 23635, 26679), PARA(2, 2, 2) },
        }
    }, [3] = {
        .skip = {
            {
                {
                    { CDF1(21443), PARA(2, 3, 1) },
                    { CDF1( 4688), PARA(2, 2, 2) },
                    { CDF1( 4478), PARA(3, 3, 2) },
                    { CDF1( 7588), PARA(2, 2, 2) },
                    { CDF1( 9776), PARA(2, 2, 1) },
                    { CDF1(14682), PARA(2, 2, 1) },
                    { CDF1(  421), PARA(3, 3, 2) },
                    { CDF1( 2639), PARA(3, 2, 1) },
                    { CDF1( 5035), PARA(1, 3, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(27522), PARA(2, 2, 2) },
                    { CDF1( 5380), PARA(3, 2, 3) },
                    { CDF1( 5185), PARA(3, 3, 2) },
                    { CDF1(10193), PARA(2, 2, 2) },
                    { CDF1(13111), PARA(2, 2, 1) },
                    { CDF1(22246), PARA(1, 1, 1) },
                    { CDF1( 1317), PARA(2, 2, 2) },
                    { CDF1( 5966), PARA(3, 3, 2) },
                    { CDF1(10326), PARA(3, 2, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(30197), PARA(2, 1, 1) },
                    { CDF1( 8536), PARA(2, 2, 2) },
                    { CDF1( 7061), PARA(3, 2, 2) },
                    { CDF1(15977), PARA(2, 1, 1) },
                    { CDF1(17416), PARA(2, 1, 1) },
                    { CDF1(28033), PARA(2, 1, 1) },
                    { CDF1( 2336), PARA(2, 2, 2) },
                    { CDF1( 8267), PARA(3, 2, 1) },
                    { CDF1(13804), PARA(3, 2, 1) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(32558), PARA(0, 1, 1) },
                    { CDF1( 3796), PARA(2, 2, 2) },
                    { CDF1( 4485), PARA(3, 2, 1) },
                    { CDF1(16972), PARA(1, 1, 0) },
                    { CDF1(17777), PARA(1, 0, 0) },
                    { CDF1(29879), PARA(1, 0, 2) },
                    { CDF1( 3523), PARA(2, 2, 1) },
                    { CDF1(10339), PARA(2, 2, 0) },
                    { CDF1(17710), PARA(2, 1, 0) },
                    { CDF1(16384), PARA(2, 2, 2) },
                }, {
                    { CDF1(32683), PARA(3, 3, 3) },
                    { CDF1( 6378), PARA(1, 1, 0) },
                    { CDF1(13628), PARA(2, 2, 0) },
                    { CDF1(24546), PARA(3, 2, 1) },
                    { CDF1(26525), PARA(3, 3, 2) },
                    { CDF1(31671), PARA(3, 2, 2) },
                    { CDF1( 5036), PARA(1, 1, 1) },
                    { CDF1(11209), PARA(1, 1, 0) },
                    { CDF1(17036), PARA(2, 1, 0) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF1(32754), PARA(0, 2, 2) },
                    { CDF1(12951), PARA(3, 3, 3) },
                    { CDF1(15900), PARA(3, 3, 3) },
                    { CDF1(14312), PARA(2, 3, 1) },
                    { CDF1(17581), PARA(2, 3, 2) },
                    { CDF1(19079), PARA(2, 3, 3) },
                    { CDF1(  507), PARA(3, 3, 3) },
                    { CDF1( 3382), PARA(1, 2, 3) },
                    { CDF1( 7041), PARA(2, 3, 3) },
                    { CDF1(32482), PARA(3, 1, 1) },
                }, {
                    { CDF1(32755), PARA(0, 3, 3) },
                    { CDF1(11625), PARA(3, 3, 3) },
                    { CDF1(10365), PARA(3, 3, 3) },
                    { CDF1(11240), PARA(3, 3, 3) },
                    { CDF1(13860), PARA(3, 2, 2) },
                    { CDF1(18669), PARA(2, 2, 2) },
                    { CDF1(  620), PARA(3, 3, 3) },
                    { CDF1( 4574), PARA(3, 2, 1) },
                    { CDF1(11493), PARA(3, 1, 3) },
                    { CDF1(31754), PARA(3, 2, 2) },
                }, {
                    { CDF1(32749), PARA(3, 3, 3) },
                    { CDF1(13494), PARA(3, 3, 3) },
                    { CDF1(13995), PARA(3, 3, 2) },
                    { CDF1(14723), PARA(3, 3, 2) },
                    { CDF1(19850), PARA(2, 2, 2) },
                    { CDF1(24076), PARA(2, 2, 1) },
                    { CDF1(  816), PARA(3, 2, 2) },
                    { CDF1( 8011), PARA(2, 1, 1) },
                    { CDF1(18757), PARA(2, 0, 1) },
                    { CDF1(32020), PARA(2, 2, 3) },
                }, {
                    { CDF1(32697), PARA(1, 0, 0) },
                    { CDF1(12925), PARA(3, 3, 2) },
                    { CDF1(14605), PARA(3, 1, 2) },
                    { CDF1(15058), PARA(3, 2, 0) },
                    { CDF1(23741), PARA(2, 3, 3) },
                    { CDF1(25610), PARA(2, 1, 1) },
                    { CDF1( 1293), PARA(2, 1, 2) },
                    { CDF1(11938), PARA(2, 2, 1) },
                    { CDF1(22991), PARA(1, 1, 0) },
                    { CDF1(26438), PARA(0, 3, 2) },
                }, {
                    { CDF1(32644), PARA(1, 0, 0) },
                    { CDF1(16042), PARA(3, 1, 0) },
                    { CDF1(24056), PARA(2, 1, 0) },
                    { CDF1(24203), PARA(2, 1, 0) },
                    { CDF1(27963), PARA(2, 1, 2) },
                    { CDF1(29458), PARA(2, 1, 2) },
                    { CDF1( 2804), PARA(0, 1, 0) },
                    { CDF1(19130), PARA(1, 3, 3) },
                    { CDF1(26311), PARA(0, 0, 2) },
                    { CDF1(16384), PARA(2, 2, 2) },
                },
            },
        }, .eob_bin_16 = {
            { CDF4( 5029, 12046, 26017, 32453), PARA(1, 1, 1) },
            { CDF4( 3860,  5738,  8894, 18233), PARA(1, 1, 1) },
            { CDF4(29060, 30345, 32212, 32705), PARA(1, 2, 0) },
        }, .eob_bin_32 = {
            { CDF5( 7189, 11732, 21773, 29775, 32060), PARA(1, 1, 1) },
            { CDF5( 3833,  7634, 15540, 24684, 30675), PARA(1, 1, 1) },
            { CDF5(26250, 28453, 31497, 32596, 32732), PARA(1, 1, 0) },
        }, .eob_bin_64 = {
            { CDF6( 3765,  6333, 13340, 20831, 28830, 32289), PARA(1, 1, 1) },
            { CDF6( 5045,  7407, 13926, 20909, 27015, 31664), PARA(1, 1, 1) },
            { CDF6(24202, 26714, 30623, 32371, 32728, 32732), PARA(2, 1, 1) },
        }, .eob_bin_128 = {
            { CDF7( 4122,  6840, 13278, 20906, 28131, 31450, 32305), PARA(1, 1, 1) },
            { CDF7( 4575,  6063, 10938, 17191, 23126, 27885, 31584), PARA(1, 1, 1) },
            { CDF7(23490, 25861, 30005, 32096, 32701, 32720, 32724), PARA(2, 2, 1) },
        }, .eob_bin_256 = {
            { CDF7( 3574,  5683, 11604, 19611, 27344, 30852, 31552), PARA(1, 1, 1) },
            { CDF7( 7197,  7949, 12414, 18002, 23115, 27424, 30391), PARA(1, 1, 0) },
            { CDF7(23383, 25747, 29846, 31947, 32613, 32720, 32724), PARA(2, 1, 1) },
        }, .eob_bin_512 = {
            { CDF7( 3753,  5634, 10147, 17539, 26473, 32201, 32398), PARA(2, 1, 1) },
            { CDF7(11196, 12269, 16359, 22348, 27230, 30729, 31805), PARA(1, 1, 0) },
            { CDF7(22240, 24551, 29042, 31545, 32498, 32720, 32724), PARA(2, 1, 0) },
        }, .eob_bin_1024 = {
            { CDF7( 5838,  8921, 14454, 21162, 27888, 32275, 32424), PARA(1, 1, 1) },
            { CDF7(15377, 16920, 20643, 25175, 28586, 31294, 32008), PARA(1, 1, 0) },
            { CDF7(23067, 25626, 29608, 31655, 32465, 32687, 32716), PARA(2, 1, 0) },
        }, .eob_hi_bit = {
            CDF1(20364), PARA(2, 2, 3)
        }, .eob_base_y_tok_hf = {
            {
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(10923, 21845), PARA(2, 2, 2) },
                { CDF2(31358, 32747), PARA(2, 3, 3) },
            }, {
                { CDF2(32389, 32626), PARA(3, 2, 2) },
                { CDF2(32642, 32756), PARA(3, 3, 3) },
                { CDF2(32629, 32756), PARA(2, 3, 3) },
            }, {
                { CDF2(32686, 32756), PARA(3, 3, 3) },
                { CDF2(32726, 32756), PARA(3, 3, 3) },
                { CDF2(32724, 32756), PARA(2, 3, 2) },
            }, {
                { CDF2(32700, 32756), PARA(3, 3, 3) },
                { CDF2(32577, 32756), PARA(1, 3, 2) },
                { CDF2(32626, 32753), PARA(3, 0, 3) },
            }, {
                { CDF2(32708, 32756), PARA(3, 3, 3) },
                { CDF2(32603, 32749), PARA(3, 3, 1) },
                { CDF2(32644, 32756), PARA(1, 3, 0) },
            }
        }, .eob_base_y_tok_lf = {
            {
                { CDF4(30609, 32413, 32637, 32716), PARA(2, 1, 2) },
                { CDF4(30333, 32610, 32744, 32748), PARA(2, 2, 1) },
                { CDF4(31067, 32497, 32676, 32711), PARA(2, 2, 1) },
                { CDF4(32062, 32748, 32752, 32756), PARA(1, 0, 1) },
            }, {
                { CDF4(31289, 32570, 32714, 32740), PARA(2, 2, 1) },
                { CDF4(32248, 32709, 32744, 32748), PARA(3, 2, 2) },
                { CDF4(32234, 32719, 32744, 32748), PARA(3, 2, 2) },
                { CDF4(32449, 32740, 32744, 32748), PARA(2, 2, 3) },
            }, {
                { CDF4(31348, 32506, 32654, 32724), PARA(2, 1, 1) },
                { CDF4(32301, 32703, 32744, 32748), PARA(3, 3, 2) },
                { CDF4(32692, 32739, 32744, 32748), PARA(2, 1, 0) },
                { CDF4(20480, 26624, 28672, 30720), PARA(0, 2, 2) },
            }, {
                { CDF4(30132, 32214, 32554, 32667), PARA(2, 1, 0) },
                { CDF4(32297, 32711, 32744, 32748), PARA(3, 3, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            }, {
                { CDF4(28223, 31648, 32311, 32527), PARA(1, 0, 0) },
                { CDF4(32184, 32695, 32744, 32748), PARA(3, 3, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
                { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
            },
        }, .base_y_tok_hf = {
            {
                {
                    { CDF3(18405, 30002, 32555), PARA(1, 3, 2) },
                    { CDF3(14824, 31208, 31988), PARA(0, 2, 2) },
                }, {
                    { CDF3(15397, 31584, 32373), PARA(3, 2, 2) },
                    { CDF3( 1347, 29476, 32319), PARA(0, 3, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(31972, 32470, 32748), PARA(1, 2, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(22231, 32012, 32721), PARA(1, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 4681, 16384, 30427), PARA(0, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(26034, 32672, 32748), PARA(3, 3, 3) },
                    { CDF3(12576, 32175, 32745), PARA(3, 3, 2) },
                }, {
                    { CDF3(22551, 32372, 32748), PARA(3, 3, 3) },
                    { CDF3(   20, 30978, 32718), PARA(2, 3, 2) },
                }, {
                    { CDF3(17805, 31280, 32648), PARA(3, 3, 3) },
                    { CDF3( 1557, 28114, 32425), PARA(2, 2, 3) },
                }, {
                    { CDF3(13292, 28676, 32147), PARA(3, 3, 3) },
                    { CDF3(  555, 23489, 31233), PARA(2, 2, 2) },
                }, {
                    { CDF3(10339, 22768, 29435), PARA(1, 0, 2) },
                    { CDF3(  758, 15761, 26377), PARA(1, 0, 2) },
                }, {
                    { CDF3(29142, 32726, 32748), PARA(2, 3, 2) },
                    { CDF3(17698, 32623, 32748), PARA(1, 2, 2) },
                }, {
                    { CDF3(24984, 32622, 32748), PARA(3, 3, 3) },
                    { CDF3(  600, 31789, 32745), PARA(2, 3, 2) },
                }, {
                    { CDF3(18241, 32005, 32740), PARA(3, 2, 3) },
                    { CDF3( 3053, 28834, 32573), PARA(3, 3, 3) },
                }, {
                    { CDF3(11582, 29556, 32181), PARA(2, 3, 3) },
                    { CDF3( 5757, 25240, 31661), PARA(1, 1, 3) },
                }, {
                    { CDF3( 3072, 21504, 29184), PARA(0, 3, 2) },
                    { CDF3(  643, 12208, 26343), PARA(1, 0, 2) },
                }, {
                    { CDF3(29915, 32732, 32748), PARA(3, 2, 3) },
                    { CDF3(24589, 32741, 32748), PARA(2, 2, 2) },
                }, {
                    { CDF3(25072, 32653, 32747), PARA(2, 3, 2) },
                    { CDF3( 2766, 32408, 32743), PARA(3, 2, 3) },
                }, {
                    { CDF3(19064, 32047, 32688), PARA(3, 3, 2) },
                    { CDF3( 6208, 29694, 32582), PARA(3, 2, 2) },
                }, {
                    { CDF3(16118, 29137, 32325), PARA(3, 3, 2) },
                    { CDF3( 3624, 26555, 32028), PARA(2, 1, 1) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(32165, 32689, 32748), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(20616, 31528, 32613), PARA(3, 2, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(17095, 29686, 32489), PARA(2, 3, 3) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(13280, 23529, 32046), PARA(3, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 1725,  3449, 31043), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(27252, 32687, 32748), PARA(2, 2, 2) },
                    { CDF3(12250, 32394, 32747), PARA(2, 2, 2) },
                }, {
                    { CDF3(22953, 32345, 32732), PARA(3, 3, 3) },
                    { CDF3(  100, 31081, 32711), PARA(3, 2, 2) },
                }, {
                    { CDF3(18289, 31130, 32616), PARA(3, 3, 2) },
                    { CDF3( 1043, 27525, 32293), PARA(2, 3, 2) },
                }, {
                    { CDF3(12030, 27356, 31773), PARA(3, 2, 2) },
                    { CDF3( 1328, 21750, 30500), PARA(2, 3, 3) },
                }, {
                    { CDF3( 8454, 22057, 29080), PARA(3, 3, 2) },
                    { CDF3(  312, 16537, 27228), PARA(3, 2, 1) },
                }, {
                    { CDF3(29639, 32739, 32748), PARA(2, 2, 2) },
                    { CDF3(24459, 32557, 32748), PARA(3, 2, 3) },
                }, {
                    { CDF3(24256, 32629, 32748), PARA(3, 2, 2) },
                    { CDF3(  586, 31663, 32726), PARA(2, 1, 2) },
                }, {
                    { CDF3(18917, 31583, 32708), PARA(2, 2, 2) },
                    { CDF3( 1616, 28584, 32470), PARA(3, 2, 2) },
                }, {
                    { CDF3(13655, 29545, 32407), PARA(3, 2, 2) },
                    { CDF3( 1396, 23860, 31469), PARA(3, 3, 2) },
                }, {
                    { CDF3( 9270, 24668, 30796), PARA(3, 3, 1) },
                    { CDF3( 1688, 18438, 28979), PARA(3, 3, 1) },
                }, {
                    { CDF3(31096, 32751, 32755), PARA(2, 2, 2) },
                    { CDF3(28942, 32716, 32748), PARA(2, 1, 2) },
                }, {
                    { CDF3(25750, 32644, 32748), PARA(3, 2, 2) },
                    { CDF3(  465, 32242, 32741), PARA(3, 3, 2) },
                }, {
                    { CDF3(20669, 32346, 32741), PARA(3, 3, 2) },
                    { CDF3( 2885, 29990, 32664), PARA(3, 2, 2) },
                }, {
                    { CDF3(15748, 30594, 32632), PARA(3, 3, 2) },
                    { CDF3(  372, 26420, 32273), PARA(3, 3, 2) },
                }, {
                    { CDF3(10002, 25783, 31458), PARA(3, 1, 1) },
                    { CDF3(  869, 20294, 30019), PARA(3, 3, 0) },
                }, {
                    { CDF3(32513, 32752, 32756), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(24556, 32348, 32716), PARA(3, 3, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(19561, 30597, 32461), PARA(2, 2, 1) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3(11689, 27786, 31427), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(26428, 32701, 32748), PARA(2, 1, 2) },
                    { CDF3( 8484, 32368, 32747), PARA(2, 2, 2) },
                }, {
                    { CDF3(22687, 32407, 32740), PARA(3, 2, 2) },
                    { CDF3(  390, 30961, 32716), PARA(2, 1, 2) },
                }, {
                    { CDF3(18394, 31398, 32670), PARA(3, 2, 2) },
                    { CDF3(  853, 27383, 32300), PARA(3, 2, 2) },
                }, {
                    { CDF3(12738, 28040, 31842), PARA(3, 2, 2) },
                    { CDF3( 1044, 21941, 30518), PARA(3, 2, 2) },
                }, {
                    { CDF3( 6990, 19000, 26174), PARA(3, 2, 3) },
                    { CDF3(  118, 14015, 24791), PARA(3, 2, 2) },
                }, {
                    { CDF3(28826, 32741, 32748), PARA(1, 1, 1) },
                    { CDF3(19295, 32513, 32748), PARA(2, 1, 2) },
                }, {
                    { CDF3(24880, 32674, 32744), PARA(3, 2, 1) },
                    { CDF3( 2546, 31692, 32741), PARA(3, 1, 2) },
                }, {
                    { CDF3(19559, 31494, 32644), PARA(3, 2, 1) },
                    { CDF3( 1553, 28807, 32451), PARA(3, 1, 1) },
                }, {
                    { CDF3(12667, 27705, 31740), PARA(2, 1, 2) },
                    { CDF3(  706, 22624, 30721), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7658, 20890, 27914), PARA(3, 2, 2) },
                    { CDF3(  423, 16424, 25634), PARA(3, 3, 1) },
                }, {
                    { CDF3(31332, 32752, 32756), PARA(2, 2, 2) },
                    { CDF3(32634, 32730, 32748), PARA(3, 2, 2) },
                }, {
                    { CDF3(26024, 32656, 32746), PARA(3, 2, 2) },
                    { CDF3( 6440, 32017, 32721), PARA(3, 2, 3) },
                }, {
                    { CDF3(21950, 32128, 32733), PARA(3, 3, 2) },
                    { CDF3( 2501, 29939, 32539), PARA(3, 2, 2) },
                }, {
                    { CDF3(15537, 30098, 32412), PARA(3, 2, 2) },
                    { CDF3(  951, 25283, 31648), PARA(2, 2, 3) },
                }, {
                    { CDF3( 8361, 23816, 30093), PARA(3, 2, 1) },
                    { CDF3( 1474, 18475, 28692), PARA(3, 3, 1) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF3(27339, 32708, 32748), PARA(3, 1, 1) },
                    { CDF3(11572, 32394, 32748), PARA(2, 1, 3) },
                }, {
                    { CDF3(23878, 32548, 32744), PARA(2, 1, 2) },
                    { CDF3(  461, 31124, 32705), PARA(2, 2, 2) },
                }, {
                    { CDF3(19326, 31492, 32668), PARA(3, 2, 2) },
                    { CDF3(  664, 28301, 32374), PARA(3, 2, 2) },
                }, {
                    { CDF3(13120, 27541, 31646), PARA(3, 2, 1) },
                    { CDF3(  550, 22504, 30562), PARA(3, 2, 1) },
                }, {
                    { CDF3( 6365, 17893, 24908), PARA(2, 3, 2) },
                    { CDF3(  608, 12570, 22302), PARA(3, 3, 2) },
                }, {
                    { CDF3(29384, 32732, 32748), PARA(2, 1, 1) },
                    { CDF3(13817, 32574, 32748), PARA(2, 2, 2) },
                }, {
                    { CDF3(24520, 32525, 32747), PARA(3, 2, 1) },
                    { CDF3( 1775, 31839, 32739), PARA(2, 1, 1) },
                }, {
                    { CDF3(19335, 31747, 32688), PARA(2, 1, 1) },
                    { CDF3( 3566, 28880, 32362), PARA(2, 1, 1) },
                }, {
                    { CDF3(12397, 27427, 31587), PARA(2, 2, 1) },
                    { CDF3(  509, 22594, 30553), PARA(2, 2, 2) },
                }, {
                    { CDF3( 7148, 19219, 26315), PARA(3, 2, 2) },
                    { CDF3(  677, 13710, 23764), PARA(3, 2, 1) },
                }, {
                    { CDF3(31236, 32752, 32756), PARA(3, 1, 2) },
                    { CDF3(32618, 32731, 32748), PARA(3, 3, 2) },
                }, {
                    { CDF3(27068, 32675, 32748), PARA(3, 2, 2) },
                    { CDF3( 5945, 32111, 32744), PARA(3, 3, 2) },
                }, {
                    { CDF3(22852, 32207, 32731), PARA(3, 2, 2) },
                    { CDF3( 2177, 30282, 32570), PARA(3, 2, 2) },
                }, {
                    { CDF3(14481, 29134, 32134), PARA(2, 2, 2) },
                    { CDF3( 2589, 24920, 31424), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8171, 21620, 28271), PARA(3, 2, 2) },
                    { CDF3(  169, 16674, 26696), PARA(3, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                }, {
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                    { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                },
            },
        }, .base_y_tok_lf = {
            {
                {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(  100, 16721, 28276, 31260, 32398), PARA(2, 2, 1) },
                    { CDF5(    4,  6986, 23211, 29768, 31892), PARA(2, 2, 1) },
                }, {
                    { CDF5( 6124, 20746, 26659, 30297, 32090), PARA(3, 1, 2) },
                    { CDF5(    4, 20450, 26906, 29984, 32052), PARA(1, 3, 0) },
                }, {
                    { CDF5( 2483,  9881, 20654, 28573, 31617), PARA(2, 1, 0) },
                    { CDF5( 4478,  5170, 20007, 29247, 31101), PARA(2, 0, 0) },
                }, {
                    { CDF5( 4402, 12594, 21642, 24821, 29711), PARA(0, 0, 2) },
                    { CDF5(  119, 12229, 15790, 22676, 27425), PARA(1, 2, 3) },
                }, {
                    { CDF5( 5174, 12072, 22420, 24145, 25869), PARA(2, 2, 2) },
                    { CDF5(  728,  2913,  5825, 21117, 22574), PARA(3, 3, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(18225, 31062, 32659, 32736, 32740), PARA(1, 1, 1) },
                    { CDF5(  747, 25457, 32313, 32736, 32740), PARA(1, 3, 3) },
                }, {
                    { CDF5( 9428, 30477, 32339, 32668, 32696), PARA(2, 3, 3) },
                    { CDF5(    4, 21160, 31076, 32661, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(14256, 29803, 32043, 32616, 32732), PARA(3, 2, 2) },
                    { CDF5(   10, 23629, 31540, 32549, 32730), PARA(1, 1, 0) },
                }, {
                    { CDF5( 8535, 25300, 30787, 31549, 32463), PARA(3, 0, 2) },
                    { CDF5( 1351, 18749, 29052, 31248, 32599), PARA(3, 3, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 3855,  9638, 17348, 19275, 23130), PARA(0, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(20884, 32507, 32740, 32744, 32748), PARA(2, 3, 2) },
                    { CDF5(11439, 30717, 32718, 32736, 32740), PARA(3, 1, 3) },
                }, {
                    { CDF5(16651, 32234, 32676, 32736, 32740), PARA(2, 3, 2) },
                    { CDF5( 2783, 29097, 32503, 32736, 32740), PARA(3, 1, 2) },
                }, {
                    { CDF5(14119, 29823, 32164, 32617, 32692), PARA(2, 0, 0) },
                    { CDF5( 2682, 23298, 31008, 32517, 32684), PARA(3, 0, 3) },
                }, {
                    { CDF5(10503, 29407, 31508, 31928, 32348), PARA(1, 2, 2) },
                    { CDF5(  886, 19484, 30111, 30997, 31882), PARA(3, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(29595, 31985, 32553, 32665, 32732), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(16090, 27467, 31184, 32157, 32704), PARA(2, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11881, 22576, 26436, 31160, 32105), PARA(1, 2, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4886, 21845, 24001, 27882, 28169), PARA(0, 0, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(29540, 32735, 32740, 32744, 32748), PARA(2, 1, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(21479, 29463, 32511, 32736, 32740), PARA(3, 3, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(15056, 26273, 29816, 32178, 32473), PARA(1, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(10519, 30400, 31391, 32327, 32713), PARA(2, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(   86, 20785, 28528, 31103, 32087), PARA(2, 2, 2) },
                    { CDF5(    4,  6067, 24484, 29795, 31615), PARA(2, 2, 2) },
                }, {
                    { CDF5(10869, 20589, 26954, 30327, 31505), PARA(2, 2, 2) },
                    { CDF5(    4, 15477, 26105, 29564, 31257), PARA(2, 2, 1) },
                }, {
                    { CDF5( 4914, 15045, 23040, 27717, 30490), PARA(2, 2, 2) },
                    { CDF5(    4, 10307, 19393, 25816, 29383), PARA(2, 3, 2) },
                }, {
                    { CDF5( 2819, 10379, 17295, 23231, 27208), PARA(3, 2, 2) },
                    { CDF5( 2939,  6238, 14472, 21322, 25358), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2510,  8572, 13721, 19650, 24615), PARA(3, 3, 1) },
                    { CDF5(    4,  6558, 12858, 16531, 22847), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2098,  8373, 11493, 16534, 21082), PARA(2, 0, 2) },
                    { CDF5(  371,  3300,  8699, 14469, 19163), PARA(3, 2, 1) },
                }, {
                    { CDF5( 1409,  6107,  9513, 13859, 18674), PARA(1, 3, 2) },
                    { CDF5( 1882,  3210,  8081, 12842, 17048), PARA(3, 0, 2) },
                }, {
                    { CDF5(  780,  5461,  7802, 10923, 13263), PARA(2, 2, 2) },
                    { CDF5(  537,  4835,  8058, 10744, 13967), PARA(3, 3, 2) },
                }, {
                    { CDF5(21042, 31954, 32667, 32736, 32740), PARA(2, 3, 3) },
                    { CDF5(28136, 28288, 32626, 32720, 32732), PARA(0, 1, 0) },
                }, {
                    { CDF5( 7851, 28094, 31782, 32677, 32732), PARA(3, 2, 3) },
                    { CDF5(    4, 21935, 31329, 32631, 32732), PARA(2, 2, 1) },
                }, {
                    { CDF5(12762, 26468, 31109, 32414, 32693), PARA(3, 3, 2) },
                    { CDF5(    4, 21556, 29551, 32049, 32643), PARA(2, 2, 2) },
                }, {
                    { CDF5(10020, 22866, 29258, 31456, 32395), PARA(3, 3, 2) },
                    { CDF5(    4, 17576, 27446, 31017, 32403), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7348, 19414, 26844, 30566, 31941), PARA(3, 3, 2) },
                    { CDF5(    4, 12308, 22780, 28574, 31279), PARA(3, 2, 2) },
                }, {
                    { CDF5( 6457, 17740, 24197, 28585, 30902), PARA(3, 2, 3) },
                    { CDF5(  769, 11802, 20680, 26000, 30085), PARA(2, 3, 2) },
                }, {
                    { CDF5( 4625, 14072, 20960, 25388, 28438), PARA(1, 3, 2) },
                    { CDF5(  185,  8492, 16246, 20861, 25568), PARA(3, 3, 2) },
                }, {
                    { CDF5(24491, 32563, 32740, 32744, 32748), PARA(3, 3, 2) },
                    { CDF5(10193, 31065, 32692, 32736, 32740), PARA(3, 2, 2) },
                }, {
                    { CDF5(18023, 31654, 32683, 32736, 32740), PARA(3, 2, 3) },
                    { CDF5(    4, 28229, 32493, 32736, 32740), PARA(2, 2, 2) },
                }, {
                    { CDF5(15126, 29669, 32385, 32717, 32732), PARA(2, 2, 3) },
                    { CDF5(    4, 25310, 31745, 32662, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(11803, 26851, 31619, 32578, 32732), PARA(3, 3, 2) },
                    { CDF5(    4, 21347, 30308, 32362, 32732), PARA(3, 2, 2) },
                }, {
                    { CDF5( 8413, 22123, 28902, 31454, 32484), PARA(3, 3, 1) },
                    { CDF5(  533, 15815, 26833, 31091, 32338), PARA(2, 2, 1) },
                }, {
                    { CDF5(30851, 32572, 32702, 32736, 32740), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(15898, 29692, 32156, 32573, 32722), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 9275, 21031, 27592, 31095, 32259), PARA(3, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 7586, 16864, 22782, 27672, 30277), PARA(3, 1, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4779, 14336, 21504, 25259, 27307), PARA(1, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(32033, 32744, 32748, 32752, 32756), PARA(2, 2, 3) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(21905, 31682, 32689, 32736, 32740), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(16223, 28310, 31943, 32665, 32704), PARA(2, 2, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(10587, 25458, 29995, 32012, 32516), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(20744, 31573, 32432, 32575, 32732), PARA(1, 0, 0) },
                    { CDF5( 2048, 24576, 26624, 28672, 30720), PARA(0, 2, 2) },
                }, {
                    { CDF5( 1512, 20783, 28537, 31233, 32030), PARA(2, 2, 2) },
                    { CDF5(    4,  9686, 25465, 29825, 31669), PARA(2, 2, 2) },
                }, {
                    { CDF5(11418, 22879, 28443, 30589, 31691), PARA(2, 2, 2) },
                    { CDF5(    4, 18611, 26971, 30180, 31489), PARA(2, 2, 1) },
                }, {
                    { CDF5( 5931, 14893, 21314, 26301, 29130), PARA(2, 2, 2) },
                    { CDF5(    4, 10485, 20060, 26727, 29964), PARA(2, 2, 0) },
                }, {
                    { CDF5( 4511, 11376, 17124, 22328, 26530), PARA(3, 3, 2) },
                    { CDF5(  109,  4550, 13218, 19861, 24578), PARA(2, 1, 1) },
                }, {
                    { CDF5( 2402,  9192, 14384, 19305, 22990), PARA(3, 2, 2) },
                    { CDF5(    4,  5323, 10546, 15982, 20848), PARA(3, 2, 1) },
                }, {
                    { CDF5( 3030,  8069, 12594, 17208, 20711), PARA(2, 2, 3) },
                    { CDF5(    4,  4225,  9697, 14319, 18246), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2223,  6369, 10286, 13595, 18323), PARA(3, 1, 3) },
                    { CDF5(  175,  2961,  7374, 11755, 15610), PARA(2, 2, 3) },
                }, {
                    { CDF5( 1367,  6180,  9659, 13156, 15544), PARA(3, 3, 2) },
                    { CDF5(  505,  2440,  6344, 10284, 13648), PARA(3, 3, 0) },
                }, {
                    { CDF5(22323, 32120, 32586, 32723, 32732), PARA(2, 1, 1) },
                    { CDF5(28677, 28707, 32573, 32736, 32740), PARA(1, 1, 1) },
                }, {
                    { CDF5( 9067, 28461, 31803, 32646, 32732), PARA(3, 3, 2) },
                    { CDF5(    4, 23713, 31500, 32628, 32732), PARA(2, 1, 1) },
                }, {
                    { CDF5(14440, 27462, 31270, 32400, 32671), PARA(3, 2, 2) },
                    { CDF5(    4, 21690, 28829, 31630, 32453), PARA(2, 1, 2) },
                }, {
                    { CDF5( 8061, 20968, 27850, 30659, 31948), PARA(3, 3, 3) },
                    { CDF5(    4, 16746, 25908, 29977, 31832), PARA(2, 1, 2) },
                }, {
                    { CDF5( 5820, 16451, 23783, 28293, 30655), PARA(3, 3, 2) },
                    { CDF5(    4, 10996, 20608, 26697, 30042), PARA(2, 1, 2) },
                }, {
                    { CDF5( 4853, 14377, 20953, 25793, 29037), PARA(3, 2, 2) },
                    { CDF5(    4, 10112, 18364, 24708, 28619), PARA(3, 2, 2) },
                }, {
                    { CDF5( 3528, 10929, 17584, 23009, 26629), PARA(3, 2, 3) },
                    { CDF5(    5,  8177, 15921, 21527, 25499), PARA(3, 2, 2) },
                }, {
                    { CDF5(24757, 32619, 32740, 32744, 32748), PARA(2, 2, 1) },
                    { CDF5( 8837, 31099, 32688, 32736, 32740), PARA(3, 2, 3) },
                }, {
                    { CDF5(19775, 31747, 32667, 32736, 32740), PARA(3, 2, 2) },
                    { CDF5(    4, 28933, 32511, 32732, 32736), PARA(2, 2, 2) },
                }, {
                    { CDF5(17105, 29988, 32352, 32704, 32732), PARA(3, 2, 2) },
                    { CDF5(    5, 26112, 31741, 32633, 32732), PARA(2, 2, 2) },
                }, {
                    { CDF5(10631, 24891, 30498, 32167, 32638), PARA(3, 3, 3) },
                    { CDF5(    4, 20962, 29880, 32217, 32689), PARA(3, 2, 1) },
                }, {
                    { CDF5( 7259, 19563, 26854, 30459, 32035), PARA(3, 3, 2) },
                    { CDF5(  161, 13687, 24042, 29325, 31661), PARA(3, 2, 2) },
                }, {
                    { CDF5(31243, 32617, 32724, 32736, 32740), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(15771, 29814, 32176, 32618, 32719), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 8991, 20335, 27006, 30538, 31920), PARA(2, 2, 1) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11004, 16889, 22530, 26291, 28694), PARA(1, 1, 0) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 2048,  4096, 16384, 20480, 28672), PARA(0, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(32375, 32744, 32748, 32752, 32756), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(21853, 32148, 32719, 32736, 32740), PARA(3, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(14100, 28596, 31850, 32559, 32685), PARA(3, 0, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5(11320, 25619, 29193, 31576, 32172), PARA(3, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(17586, 29249, 30954, 31637, 31943), PARA(0, 0, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6607, 19220, 27249, 31067, 32015), PARA(2, 3, 2) },
                    { CDF5(    4, 12693, 25132, 30060, 31735), PARA(2, 2, 2) },
                }, {
                    { CDF5(11218, 23056, 28975, 31289, 32045), PARA(2, 1, 2) },
                    { CDF5(    4, 16611, 26400, 28905, 30652), PARA(2, 2, 1) },
                }, {
                    { CDF5( 4973, 15646, 22529, 27020, 30234), PARA(3, 2, 2) },
                    { CDF5(    4, 11786, 18820, 25595, 28661), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4994, 11005, 17116, 23193, 25485), PARA(2, 2, 2) },
                    { CDF5(   10,  5820, 14233, 19478, 24366), PARA(3, 2, 2) },
                }, {
                    { CDF5( 1327,  8818, 15358, 18969, 22525), PARA(1, 2, 2) },
                    { CDF5( 1517,  5910, 11125, 16349, 21591), PARA(2, 2, 2) },
                }, {
                    { CDF5(  123,  5065, 11340, 15150, 17222), PARA(2, 3, 1) },
                    { CDF5( 1786,  5857, 10807, 14291, 19911), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2928,  7753, 12931, 17083, 20510), PARA(3, 2, 2) },
                    { CDF5(  549,  2673,  5713,  7772, 12679), PARA(2, 2, 3) },
                }, {
                    { CDF5( 1125,  4606,  9305, 11931, 14884), PARA(2, 0, 3) },
                    { CDF5(   12,  3709,  6058,  8777, 11932), PARA(3, 0, 2) },
                }, {
                    { CDF5(19675, 31285, 32524, 32698, 32732), PARA(2, 0, 1) },
                    { CDF5(11455, 26740, 32279, 32717, 32732), PARA(2, 2, 3) },
                }, {
                    { CDF5(10345, 28211, 31805, 32644, 32732), PARA(2, 2, 3) },
                    { CDF5(    4, 23277, 31209, 32545, 32732), PARA(2, 1, 3) },
                }, {
                    { CDF5(13559, 26348, 31030, 32344, 32653), PARA(2, 1, 1) },
                    { CDF5(    4, 19849, 28463, 31321, 32304), PARA(3, 1, 3) },
                }, {
                    { CDF5( 7549, 20488, 27158, 30433, 31903), PARA(3, 2, 2) },
                    { CDF5(    4, 15187, 24493, 29279, 31267), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4919, 15070, 22336, 27218, 29792), PARA(3, 2, 2) },
                    { CDF5(  296,  9560, 18580, 24640, 28571), PARA(3, 2, 2) },
                }, {
                    { CDF5( 4449, 12778, 20939, 26844, 28917), PARA(2, 1, 2) },
                    { CDF5(    4,  8819, 16299, 21272, 25505), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2662,  8971, 15434, 20936, 24242), PARA(3, 2, 0) },
                    { CDF5(    5,  7370, 13045, 17765, 21686), PARA(3, 3, 2) },
                }, {
                    { CDF5(23376, 32614, 32740, 32744, 32748), PARA(2, 1, 2) },
                    { CDF5( 7252, 31056, 32698, 32736, 32740), PARA(3, 2, 3) },
                }, {
                    { CDF5(18958, 31560, 32655, 32736, 32740), PARA(3, 3, 2) },
                    { CDF5(    7, 28722, 32521, 32728, 32732), PARA(3, 2, 1) },
                }, {
                    { CDF5(15525, 29433, 32224, 32682, 32732), PARA(3, 3, 2) },
                    { CDF5(    5, 25379, 31608, 32598, 32732), PARA(2, 2, 1) },
                }, {
                    { CDF5(10133, 24671, 30659, 32294, 32704), PARA(3, 2, 2) },
                    { CDF5(  194, 19014, 28420, 31496, 32473), PARA(3, 2, 2) },
                }, {
                    { CDF5( 6037, 17899, 25577, 29484, 31446), PARA(3, 2, 2) },
                    { CDF5(  675, 12416, 22211, 28031, 30591), PARA(3, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            }, {
                {
                    { CDF5(20160, 28303, 31010, 31935, 32259), PARA(0, 3, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 6387, 21131, 28651, 31386, 32236), PARA(0, 2, 1) },
                    { CDF5(    4, 14343, 25805, 30386, 31978), PARA(2, 1, 2) },
                }, {
                    { CDF5(10794, 23651, 28414, 30514, 31623), PARA(1, 2, 1) },
                    { CDF5(    4, 18792, 26345, 29842, 31433), PARA(1, 2, 1) },
                }, {
                    { CDF5( 7250, 18857, 23745, 26494, 29185), PARA(1, 1, 1) },
                    { CDF5(   59,  5934, 16720, 25540, 28810), PARA(0, 2, 1) },
                }, {
                    { CDF5( 4853, 13443, 19345, 23384, 26041), PARA(2, 2, 2) },
                    { CDF5(    4,  7130, 12348, 18932, 24173), PARA(3, 2, 2) },
                }, {
                    { CDF5( 2667,  9653, 13863, 18817, 21760), PARA(2, 2, 1) },
                    { CDF5(    4,  5477, 10652, 16140, 19594), PARA(2, 2, 1) },
                }, {
                    { CDF5( 2595,  7918, 13026, 17820, 20007), PARA(3, 2, 0) },
                    { CDF5(  508,  3110,  7370, 10565, 14704), PARA(2, 2, 0) },
                }, {
                    { CDF5( 1961,  6366,  9476, 12294, 15249), PARA(3, 3, 2) },
                    { CDF5(  753,  2600,  6724, 10877, 14165), PARA(2, 3, 2) },
                }, {
                    { CDF5( 1420,  4356,  6620,  8937, 10997), PARA(3, 3, 2) },
                    { CDF5(  120,  1977,  4498,  6986,  9746), PARA(3, 2, 2) },
                }, {
                    { CDF5(20741, 31938, 32628, 32728, 32732), PARA(1, 0, 2) },
                    { CDF5( 9417, 28087, 32436, 32701, 32732), PARA(2, 2, 3) },
                }, {
                    { CDF5(12348, 28499, 31976, 32606, 32720), PARA(2, 2, 2) },
                    { CDF5(    4, 24379, 31121, 32398, 32684), PARA(2, 2, 2) },
                }, {
                    { CDF5(13275, 26774, 30839, 32177, 32535), PARA(2, 3, 1) },
                    { CDF5(    4, 21429, 28887, 31453, 32269), PARA(1, 2, 1) },
                }, {
                    { CDF5( 7379, 21206, 27561, 30526, 31713), PARA(2, 2, 1) },
                    { CDF5(  703, 12333, 22878, 28540, 30860), PARA(2, 2, 1) },
                }, {
                    { CDF5( 5216, 15396, 22184, 26885, 29262), PARA(3, 2, 2) },
                    { CDF5(   24,  9666, 18359, 24699, 28006), PARA(2, 2, 2) },
                }, {
                    { CDF5( 4332, 12591, 18916, 23721, 26816), PARA(2, 2, 3) },
                    { CDF5(  499,  7000, 14338, 19317, 23450), PARA(2, 2, 2) },
                }, {
                    { CDF5( 3594,  9556, 14336, 19090, 22322), PARA(3, 2, 2) },
                    { CDF5(   17,  3572,  9288, 13324, 15737), PARA(2, 2, 2) },
                }, {
                    { CDF5(24009, 32537, 32740, 32744, 32748), PARA(3, 2, 2) },
                    { CDF5(10094, 31466, 32706, 32736, 32740), PARA(2, 2, 2) },
                }, {
                    { CDF5(19318, 31691, 32676, 32736, 32740), PARA(3, 1, 2) },
                    { CDF5(  319, 28584, 32312, 32719, 32732), PARA(3, 2, 2) },
                }, {
                    { CDF5(15897, 29451, 32143, 32648, 32732), PARA(3, 2, 2) },
                    { CDF5(  219, 25102, 31471, 32488, 32732), PARA(3, 2, 2) },
                }, {
                    { CDF5(10046, 24716, 30457, 32055, 32572), PARA(2, 2, 2) },
                    { CDF5(  503, 18762, 28275, 31529, 32438), PARA(3, 2, 2) },
                }, {
                    { CDF5( 5398, 16028, 23301, 27427, 29942), PARA(3, 2, 1) },
                    { CDF5(  497, 11148, 20015, 25561, 28959), PARA(3, 2, 1) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                }, {
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                    { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
                },
            },
        }, .dc_sign = {
            {
                { CDF1(20108), PARA(2, 2, 1) },
                { CDF1(14675), PARA(2, 2, 2) },
                { CDF1(20547), PARA(3, 3, 3) },
            }, {
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }
        }, .br_y_tok_hf = {
            { CDF3(31501, 32621, 32738), PARA(0, 1, 2) },
            { CDF3(29651, 32500, 32698), PARA(2, 1, 1) },
            { CDF3(27204, 32153, 32586), PARA(1, 1, 0) },
            { CDF3(22529, 30751, 32001), PARA(1, 1, 1) },
            { CDF3(17048, 27341, 30583), PARA(2, 3, 2) },
            { CDF3(12558, 24036, 28617), PARA(2, 1, 1) },
            { CDF3( 9501, 18960, 24998), PARA(2, 0, 3) },
        }, .br_y_tok_lf = {
            { CDF3(13965, 20979, 26518), PARA(0, 0, 0) },
            { CDF3(17417, 26343, 29434), PARA(2, 1, 1) },
            { CDF3(14569, 24464, 27796), PARA(2, 1, 1) },
            { CDF3(12532, 22823, 25671), PARA(2, 0, 1) },
            { CDF3( 8586, 17291, 21825), PARA(2, 1, 1) },
            { CDF3( 6326, 13118, 17907), PARA(2, 1, 1) },
            { CDF3( 4106,  9173, 12623), PARA(2, 3, 2) },
            { CDF3(24175, 29267, 31202), PARA(1, 0, 2) },
            { CDF3(22491, 30103, 31663), PARA(2, 2, 1) },
            { CDF3(19961, 29271, 31158), PARA(2, 1, 1) },
            { CDF3(17023, 27102, 29910), PARA(2, 1, 1) },
            { CDF3(13897, 23531, 27451), PARA(2, 2, 1) },
            { CDF3(11233, 19762, 24691), PARA(2, 1, 0) },
            { CDF3( 7378, 14545, 19934), PARA(2, 1, 0) },
        }, .ph_dc_y_tok = {
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3(8192, 16384, 24576), PARA(2, 2, 2) },
        }, .bob_base_y_tok = {
            {
                { CDF2(20211, 31417), PARA(2, 1, 2) },
                { CDF2(22000, 30309), PARA(2, 1, 2) },
                { CDF2(24619, 32031), PARA(1, 1, 0) },
            }, {
                { CDF2(25412, 31853), PARA(1, 1, 0) },
                { CDF2(26802, 31283), PARA(1, 1, 0) },
                { CDF2(29204, 32091), PARA(1, 1, 0) },
            }, {
                { CDF2(30348, 32633), PARA(1, 1, 0) },
                { CDF2(31094, 32686), PARA(1, 3, 2) },
                { CDF2(31665, 32664), PARA(2, 1, 0) },
            },
        }, .br_y_tok_idtx = {
            {
                { CDF3(32317, 32467, 32618), PARA(0, 0, 0) },
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3(26624, 28672, 30720), PARA(0, 2, 2) },
                { CDF3(32099, 32322, 32545), PARA(0, 2, 2) },
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
            }, {
                { CDF3(31284, 32482, 32636), PARA(0, 0, 0) },
                { CDF3(31915, 32524, 32727), PARA(0, 0, 0) },
                { CDF3(32202, 32681, 32724), PARA(0, 0, 2) },
                { CDF3(32241, 32717, 32748), PARA(0, 0, 2) },
                { CDF3(30064, 32611, 32737), PARA(0, 0, 0) },
                { CDF3(29352, 32394, 32715), PARA(0, 0, 0) },
                { CDF3(21876, 31279, 32303), PARA(0, 0, 2) },
            }, {
                { CDF3(32083, 32670, 32719), PARA(0, 0, 2) },
                { CDF3(32154, 32631, 32700), PARA(0, 0, 2) },
                { CDF3(31950, 32686, 32727), PARA(0, 0, 2) },
                { CDF3(32416, 32734, 32748), PARA(0, 0, 2) },
                { CDF3(31835, 32703, 32746), PARA(0, 0, 0) },
                { CDF3(30941, 32582, 32737), PARA(0, 0, 2) },
                { CDF3(28688, 32549, 32724), PARA(0, 0, 2) },
            },
        }, .base_y_tok_idtx = {
            {
                { CDF3(31026, 32443, 32748), PARA(1, 2, 2) },
                { CDF3(22538, 31251, 32718), PARA(2, 1, 2) },
                { CDF3(22228, 26294, 32627), PARA(2, 2, 2) },
                { CDF3(20903, 23313, 25862), PARA(1, 0, 3) },
                { CDF3(11627, 16067, 32345), PARA(1, 2, 2) },
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
                { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
            }, {
                { CDF3(31817, 32581, 32735), PARA(1, 2, 2) },
                { CDF3(19499, 31019, 32650), PARA(2, 2, 2) },
                { CDF3(13910, 24210, 32424), PARA(1, 1, 1) },
                { CDF3(12714, 20186, 29593), PARA(0, 0, 0) },
                { CDF3( 4822, 12648, 29509), PARA(1, 1, 0) },
                { CDF3( 2380,  7451, 16774), PARA(3, 2, 2) },
                { CDF3( 3072, 10791, 15675), PARA(0, 2, 2) },
            }, {
                { CDF3(32485, 32734, 32748), PARA(3, 2, 2) },
                { CDF3(19059, 32009, 32725), PARA(2, 2, 2) },
                { CDF3( 9309, 28748, 32484), PARA(1, 1, 0) },
                { CDF3( 5722, 17292, 29536), PARA(0, 0, 0) },
                { CDF3( 2186,  8637, 26136), PARA(0, 1, 0) },
                { CDF3( 1951,  5879, 15659), PARA(1, 1, 3) },
                { CDF3( 2166,  5695, 11591), PARA(1, 0, 1) },
            },
        }, .sign_idtx = {
            {
                { CDF1(18478), PARA(1, 1, 1) },
                { CDF1(30410), PARA(1, 2, 1) },
                { CDF1( 3274), PARA(2, 3, 1) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(32138), PARA(2, 2, 2) },
                { CDF1(  697), PARA(0, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }, {
                { CDF1(24519), PARA(1, 1, 0) },
                { CDF1(32572), PARA(1, 2, 1) },
                { CDF1(  653), PARA(2, 0, 3) },
                { CDF1(32404), PARA(0, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
                { CDF1(32753), PARA(3, 1, 3) },
                { CDF1(   78), PARA(3, 0, 1) },
                { CDF1(32612), PARA(0, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            }, {
                { CDF1(27765), PARA(0, 0, 0) },
                { CDF1(32723), PARA(3, 2, 3) },
                { CDF1(  368), PARA(1, 1, 1) },
                { CDF1(32138), PARA(0, 2, 2) },
                { CDF1( 2521), PARA(0, 2, 2) },
                { CDF1(32764), PARA(1, 0, 2) },
                { CDF1(   22), PARA(0, 2, 3) },
                { CDF1(32577), PARA(0, 2, 2) },
                { CDF1(16384), PARA(2, 2, 2) },
            },
        }, .skip_v = {
            { CDF1(  606), PARA(3, 3, 2) },
            { CDF1( 6309), PARA(2, 2, 2) },
            { CDF1(13697), PARA(2, 2, 1) },
            { CDF1(  801), PARA(2, 0, 2) },
            { CDF1(10893), PARA(1, 2, 2) },
            { CDF1(19895), PARA(0, 2, 2) },
            { CDF1( 6221), PARA(3, 2, 1) },
            { CDF1(13720), PARA(3, 2, 2) },
            { CDF1(20139), PARA(3, 2, 2) },
            { CDF1( 7333), PARA(0, 0, 2) },
            { CDF1(20045), PARA(1, 2, 2) },
            { CDF1(24485), PARA(0, 2, 2) },
        }, .eob_base_uv_tok_hf = {
            { CDF2(31987, 32697), PARA(3, 3, 3) },
            { CDF2(32662, 32756), PARA(3, 3, 2) },
            { CDF2(32487, 32698), PARA(0, 0, 2) },
        }, .base_uv_tok_hf = {
            { CDF3(26130, 32392, 32726), PARA(3, 2, 2) },
            { CDF3(13730, 29626, 32253), PARA(3, 2, 2) },
            { CDF3( 9442, 23537, 29252), PARA(2, 1, 1) },
            { CDF3( 4255, 13986, 21188), PARA(1, 0, 2) },
            { CDF3(24285, 32033, 32659), PARA(2, 2, 2) },
            { CDF3(11954, 28100, 31763), PARA(3, 2, 2) },
            { CDF3( 7399, 19439, 26435), PARA(2, 1, 2) },
            { CDF3( 4096, 12081, 19339), PARA(3, 2, 0) },
            { CDF3(30583, 31894, 32331), PARA(3, 3, 2) },
            { CDF3(18905, 31508, 32138), PARA(1, 2, 2) },
            { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
            { CDF3( 8192, 16384, 24576), PARA(2, 2, 2) },
        }, .br_uv_tok_hf = {
            { CDF3(26977, 31598, 32364), PARA(0, 2, 2) },
            { CDF3(24721, 30575, 32124), PARA(3, 3, 3) },
            { CDF3(18803, 26659, 30610), PARA(3, 3, 2) },
            { CDF3(11757, 20385, 25284), PARA(2, 1, 2) },
        }, .eob_base_uv_tok_lf = {
            { CDF4(31345, 32511, 32676, 32725), PARA(3, 2, 1) },
            { CDF4(31940, 32413, 32531, 32650), PARA(0, 2, 2) },
            { CDF4( 6554, 13107, 19661, 26214), PARA(2, 2, 2) },
        }, .base_uv_tok_lf = {
            { CDF5( 7986, 24484, 30470, 32123, 32478), PARA(2, 0, 0) },
            { CDF5( 6385, 22268, 29781, 31884, 32479), PARA(2, 1, 1) },
            { CDF5( 4563, 14337, 22377, 27527, 30631), PARA(3, 2, 2) },
            { CDF5( 1768,  5903, 10730, 16633, 21440), PARA(3, 3, 2) },
            { CDF5( 7554, 22427, 29258, 31475, 32386), PARA(2, 1, 2) },
            { CDF5( 6209, 20694, 28786, 31444, 32330), PARA(3, 3, 2) },
            { CDF5( 4185, 12361, 19887, 25739, 29491), PARA(3, 3, 3) },
            { CDF5( 1583,  5456,  9702, 15370, 20474), PARA(3, 3, 2) },
            { CDF5(30183, 32316, 32574, 32639, 32703), PARA(3, 3, 2) },
            { CDF5(15147, 31729, 32521, 32669, 32719), PARA(1, 0, 2) },
            { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
            { CDF5( 5461, 10923, 16384, 21845, 27307), PARA(2, 2, 2) },
        }
    }
};

#define update_cdf_1d(n1d, type, name, op) op(n1d, type, name)
#define update_cdf_2d(n1d, n2d, type, name, op) \
    for (int j = 0; j < (n1d); j++) update_cdf_1d(n2d, type, name[j], op)
#define update_cdf_3d(n1d, n2d, n3d, type, name, op) \
    for (int k = 0; k < (n1d); k++) update_cdf_2d(n2d, n3d, type, name[k], op)
#define update_cdf_4d(n1d, n2d, n3d, n4d, type, name, op) \
    for (int l = 0; l < (n1d); l++) update_cdf_3d(n2d, n3d, n4d, type, name[l], op)

#define update_mv_cdfs(type, op) \
    update_cdf_1d(1, type, shell_set, op); \
    update_cdf_2d(7, (9 + j) >> 1, type, shell_lower, op); \
    update_cdf_2d(7, imin(10 + j, 14) >> 1, type, shell_upper, op); \
    update_cdf_1d(1, type, shell_tip, op); \
    update_cdf_2d(2, 1, type, shell_offset_low, op); \
    update_cdf_1d(1, type, shell_offset_cl2, op); \
    update_cdf_2d(16, 1, type, shell_offset_hi, op); \
    update_cdf_2d(2, 1, type, col_component, op); \
    update_cdf_2d(4, 1, type, col_index, op)

#define update_cdfs(op, between_kf_nonkf_condition) \
    update_cdf_2d(2, 1, m, rst_switchable, op); \
    update_cdf_1d(1, m, rst_ns_wiener, op); \
    update_cdf_1d(1, m, rst_pc_wiener, op); \
    update_cdf_2d(2, 1, m, wiener_ns_len, op); \
    update_cdf_1d(1, m, wiener_ns_sym, op); \
    update_cdf_1d(3, m, wiener_ns_cf, op); \
    update_cdf_3d(2, 64, 1, m, part_split, op); \
    update_cdf_2d(8, 1, m, part_square, op); \
    update_cdf_3d(2, 44, 1, m, part_dir, op); \
    update_cdf_3d(2, 28, 1, m, part_ext, op); \
    update_cdf_3d(2, 28, 1, m, part_4way, op); \
    update_cdf_2d(3, 1, m, intrabc, op); \
    update_cdf_1d(1, m, gdf, op); \
    update_cdf_2d(4, 1, m, cdef_idx0, op); \
    update_cdf_2d(6, 1 + j, m, cdef_idx, op); \
    update_cdf_3d(3, 2, 1, m, ccso, op); \
    update_cdf_2d(6, 1, m, skip_txfm, op); \
    update_cdf_2d(2, 1, m, dpcm, op); \
    update_cdf_2d(2, 1, m, dpcm_dir, op); \
    update_cdf_1d(3, m, intra_y_set, op); \
    update_cdf_2d(3, 7, m, intra_y_idx0, op); \
    update_cdf_2d(3, 5, m, intra_y_idx1, op); \
    update_cdf_3d(4, 6, 1, m, fsc, op); \
    update_cdf_2d(3, 3, m, mrl_index, op); \
    update_cdf_2d(3, 1, m, multi_mrl, op); \
    update_cdf_1d(1, m, pal_y, op); \
    update_cdf_1d(6, m, pal_sz, op); \
    update_cdf_2d(3, 1, m, dip, op); \
    update_cdf_1d(5, m, dip_mode, op); \
    update_cdf_2d(3, 1, m, cfl, op); \
    update_cdf_2d(2, 7, m, intra_uv_mode, op); \
    update_cdf_1d(1, m, mhccp, op); \
    update_cdf_2d(4, 2, m, mhccp_filter_dir, op); \
    update_cdf_1d(1, m, cfl_type, op); \
    update_cdf_1d(7, m, cfl_sign, op); \
    update_cdf_2d(6, 7, m, cfl_alpha, op); \
    update_cdf_2d(4, 2, m, pal_idx_identity, op); \
    update_cdf_3d(7, 5, k + 1, m, pal_idx, op); \
    update_cdf_1d(1, m, intrabc_mode, op); \
    update_cdf_1d(1, m, intrabc_precision, op); \
    update_cdf_2d(3, 1, m, morph_pred, op); \
    update_cdf_3d(4, 2, 1, m, txsz_lossless, op); \
    update_cdf_3d(3, 9, 1, m, tx_split, op); \
    update_cdf_3d(3, 2, 1, m, tx_part_1d, op); \
    update_cdf_1d(1, m, txtp_lossless, op); \
    update_cdf_2d(2, 1, m, txtp_long32_dct, op); \
    update_cdf_2d(3, 3, m, txtp_intra_short_1d, op); \
    update_cdf_3d(3, 3, 3, m, txtp_inter_short_1d, op); \
    update_cdf_2d(3, 6, m, txtp_ext, op); \
    update_cdf_2d(3, 1, m, txtp_ext_reduced, op); \
    update_cdf_3d(3, 3, 1, m, txtp_inter_tx_set, op); \
    update_cdf_3d(2, 3, 7, m, txtp_inter_set0, op); \
    update_cdf_2d(3, 7, m, txtp_inter_set1, op); \
    update_cdf_2d(3, 3, m, txtp_inter_set2, op); \
    update_cdf_3d(3, 4, 1, m, txtp_inter_dct_idtx, op); \
    update_cdf_3d(3, 3, 3, m, txtp_inter_dct_idtx_iddct, op); \
    update_cdf_3d(2, 5, 3, m, stx, op); \
    update_cdf_1d(3, m, stx_set_adst, op); \
    update_cdf_1d(6, m, stx_set, op); \
    update_cdf_1d(6, m, cctx, op); \
\
    update_cdf_3d(3, 14, 6, tx2d, tx_part_2d, op); \
\
    update_cdf_4d(2, N_TX_SIZES, 10, 1, coef, skip, op); \
    update_cdf_2d(3, 4, coef, eob_bin_16, op); \
    update_cdf_2d(3, 5, coef, eob_bin_32, op); \
    update_cdf_2d(3, 6, coef, eob_bin_64, op); \
    update_cdf_2d(3, 7, coef, eob_bin_128, op); \
    update_cdf_2d(3, 7, coef, eob_bin_256, op); \
    update_cdf_2d(3, 7, coef, eob_bin_512, op); \
    update_cdf_2d(3, 7, coef, eob_bin_1024, op); \
    update_cdf_1d(1, coef, eob_hi_bit, op); \
    update_cdf_3d(5, 3, 2, coef, eob_base_y_tok_hf, op); \
    update_cdf_4d(5, 20, 2, 3, coef, base_y_tok_hf, op); \
    update_cdf_2d(7, 3, coef, br_y_tok_hf, op); \
    update_cdf_3d(5, 4, 4, coef, eob_base_y_tok_lf, op); \
    update_cdf_4d(5, 33, 2, 5, coef, base_y_tok_lf, op); \
    update_cdf_2d(14, 3, coef, br_y_tok_lf, op); \
    update_cdf_2d(5, 3, coef, ph_dc_y_tok, op); \
    update_cdf_3d(2, 3, 1, coef, dc_sign, op); \
    update_cdf_3d(3, 3, 2, coef, bob_base_y_tok, op); \
    update_cdf_3d(3, 7, 3, coef, br_y_tok_idtx, op); \
    update_cdf_3d(3, 7, 3, coef, base_y_tok_idtx, op); \
    update_cdf_3d(3, 9, 1, coef, sign_idtx, op); \
    update_cdf_2d(12, 1, coef, skip_v, op); \
    update_cdf_2d(3, 2, coef, eob_base_uv_tok_hf, op); \
    update_cdf_2d(12, 3, coef, base_uv_tok_hf, op); \
    update_cdf_2d(4, 3, coef, br_uv_tok_hf, op); \
    update_cdf_2d(3, 4, coef, eob_base_uv_tok_lf, op); \
    update_cdf_2d(12, 5, coef, base_uv_tok_lf, op); \
\
    update_cdf_2d(3, 1, m, seg_id_ext, op); \
    update_cdf_3d(2, 3, 7, m, seg_id, op); \
    update_cdf_1d(7, m, delta_q, op); \
 \
    update_mv_cdfs(dmv, op); \
 \
    between_kf_nonkf_condition; \
 \
    update_cdf_2d(4, 1, m, region_type, op); \
    update_cdf_2d(3, 1, m, skip_mode, op); \
    update_cdf_2d(3, 1, m, skip_mode_drl_idx, op); \
    update_cdf_2d(4, 1, m, intra, op); \
    update_cdf_2d(3, 1, m, tip, op); \
    update_cdf_2d(5, 1, m, comp, op); \
    update_cdf_3d(3, 6, 1, m, single_ref, op); \
    update_cdf_3d(3, 2, 1, m, comp0_ref, op); \
    update_cdf_4d(3, 2, 6, 1, m, comp1_ref, op); \
    update_cdf_1d(1, m, tip_mode, op); \
    update_cdf_2d(5, 1, m, warp, op); \
    update_cdf_1d(1, m, warp_newmv, op); \
    update_cdf_2d(5, 2, m, inter_mode, op); \
    update_cdf_3d(9, 3, 1, m, amvd, op); \
    update_cdf_2d(2, 1, m, bawp, op); \
    update_cdf_2d(3, 1, m, bawp_explicit, op); \
    update_cdf_1d(1, m, bawp_explicit_scale, op); \
    update_cdf_2d(3, 1, m, warp_extend, op); \
    update_cdf_2d(4, 1, m, warp_causal, op); \
    update_cdf_2d(4, 1, m, interintra, op); \
    update_cdf_2d(4, 3, m, interintra_mode, op); \
    update_cdf_1d(1, m, interintra_wedge, op); \
    update_cdf_1d(3, m, wedge_quad, op); \
    update_cdf_2d(4, 4, m, wedge_angle, op); \
    update_cdf_1d(3, m, wedge_dist, op); \
    update_cdf_1d(2, m, wedge_dist2, op); \
    update_cdf_2d(3, 1, m, tip_drl_idx, op); \
    update_cdf_1d(2, m, jmvd_amvd_scale_mode, op); \
    update_cdf_1d(4, m, jmvd_scale_mode, op); \
    update_cdf_3d(3, 5, 1, m, drl_idx, op); \
    update_cdf_2d(3, 1, m, mvprec_def, op); \
    update_cdf_3d(2, 3, 2, m, mvprec_rem, op); \
    update_cdf_2d(3, 1, m, warp_ref_idx, op); \
    update_cdf_1d(3, m, amvd_joint, op); \
    update_cdf_2d(2, 7, m, amvd_index, op); \
    update_cdf_1d(1, m, warpmv_with_mvd, op); \
    update_cdf_2d(22, 1, m, warp_delta_prec, op); \
    update_cdf_3d(2, 2, 7, m, warp_delta_param, op); \
    update_cdf_1d(1, m, warp_delta_sign, op); \
    update_cdf_2d(3, 1, m, warp_interintra, op); \
    update_cdf_2d(5, 3, m, comp_mode_sameref, op); \
    update_cdf_2d(2, 1, m, comp_mode_joint, op); \
    update_cdf_2d(5, 4, m, comp_mode, op); \
    update_cdf_2d(2, 1, m, opfl, op); \
    update_cdf_2d(7, 1, m, refine_mv, op); \
    update_cdf_2d(12, 1, m, comp_type_masked, op); \
    update_cdf_1d(1, m, comp_type_weighted, op); \
    update_cdf_2d(4, 1, m, cwp_idx, op); \
    update_cdf_2d(8, 2, m, filter, op); \
\
    update_cdf_2d(3, 1, m, seg_pred, op); \
\
    update_mv_cdfs(mv, op)

typedef union {
    uint16_t cdf;
    struct {
#if ENDIANNESS_BIG
        uint8_t para;
        uint8_t count;
#else
        uint8_t count;
        uint8_t para;
#endif
    };
} ATTR_ALIAS CdfParaCount;

void dav2d_cdf_reset_count(const Dav2dFrameHeader *const hdr,
                           CdfContext *const dst)
{
#define reset_count(n1d, type, name) \
    do { \
        CdfParaCount *const pc = (CdfParaCount*)&dst->type.name[n1d]; \
        pc->count = (pc->count * 3) >> 2; \
    } while (0)

    update_cdfs(reset_count, if (IS_KEY_OR_INTRA(hdr)) return);
#undef reset_count
}

void dav2d_cdf_shift(CdfContext *const dst, const CdfContext *const src,
                     const int n_tiles_log2)
{
#define shift_store(n1d, type, name) \
    do { \
        for (int n = 0; n < n1d; n++) { \
            dst->type.name[n] = src->type.name[n] >> n_tiles_log2; \
        } \
        CdfParaCount *const dst_pc = (CdfParaCount*)&dst->type.name[n1d]; \
        const CdfParaCount *const src_pc = (const CdfParaCount*)&src->type.name[n1d]; \
        dst_pc->count = src_pc->count >> n_tiles_log2; \
        dst_pc->para  = src_pc->para; \
    } while (0)

    update_cdfs(shift_store,);
#undef shift_store
}

void dav2d_cdf_shift_accumulate(CdfContext *const dst, const CdfContext *const src,
                                const int n_tiles_log2)
{
#define shift_accumulate(n1d, type, name) \
    do { \
        for (int n = 0; n < n1d; n++) { \
            dst->type.name[n] += src->type.name[n] >> n_tiles_log2; \
        } \
        dst->type.name[n1d] += (src->type.name[n1d] & 0xff) >> n_tiles_log2; \
        /* ignore para beyond first tile */ \
    } while (0)

    update_cdfs(shift_accumulate,);
#undef shift_accumulate
}

// GCC 15.1 and 15.2 have a known bug in their vectorizer that causes the
// pri_sec_average loop to miscompile, so disable vectorization for these
// versions. See https://code.videolan.org/videolan/dav2d/-/work_items/56.
// This is fixed in GCC 15.3.
#if defined(__GNUC__)
#if __GNUC__ == 15 && __GNUC_MINOR__ < 3
__attribute__((optimize("no-tree-loop-vectorize")))
#endif
#endif
void dav2d_cdf_pri_sec_average(CdfContext *const dst,
                               const CdfThreadContext *const src1,
                               const CdfThreadContext *const src2)
{
#define pri_sec_average(n1d, type, name) \
    do { \
        for (int n = 0; n <= n1d; n++) { \
            /* for n == n1d this averages count without modifying para */ \
            dst->type.name[n] = (src1##type->name[n] * 7 + \
                                 src2##type->name[n] * 1 + 4) >> 3; \
        } \
    } while (0)

    const CdfModeContext *src1m, *src2m;
    const CdfMvContext *src1mv, *src1dmv, *src2mv, *src2dmv;
    const CdfCoefContext *src1coef, *src2coef;
    const CdfTxPart2dContext *src1tx2d, *src2tx2d;

#define assign_src(num) \
    if (src##num->ref) { \
        src##num##m = &src##num->data.cdf->m; \
        src##num##tx2d = &src##num->data.cdf->tx2d; \
        src##num##mv = &src##num->data.cdf->mv; \
        src##num##dmv = &src##num->data.cdf->dmv; \
        src##num##coef = &src##num->data.cdf->coef; \
    } else { \
        src##num##m = &default_cdf.m; \
        src##num##tx2d = &default_tx_part_2d_cdf[src##num->data.rtxp]; \
        src##num##mv = src##num##dmv = &default_cdf.mv; \
        src##num##coef = &default_coef_cdf[src##num->data.qcat]; \
    }
    assign_src(1);
    assign_src(2);
#undef assign_src
    update_cdfs(pri_sec_average,);
#undef pri_sec_average
}

/*
 * CDF threading wrappers.
 */
void dav2d_cdf_thread_init_static(CdfThreadContext *const cdf, const unsigned qidx,
                                  const unsigned reduced_tx_part_set)
{
    cdf->ref = NULL;
    cdf->data.qcat = (qidx > 90) + (qidx > 140) + (qidx > 190);
    cdf->data.rtxp = reduced_tx_part_set;
}

void dav2d_cdf_thread_copy(CdfContext *const dst, const CdfThreadContext *const src) {
    if (src->ref) {
        memcpy(dst, src->data.cdf, sizeof(*dst));
    } else {
        dst->coef = default_coef_cdf[src->data.qcat];
        dst->m = default_cdf.m;
        dst->tx2d = default_tx_part_2d_cdf[src->data.rtxp];
        dst->mv = default_cdf.mv;
        dst->dmv = default_cdf.mv;
    }
}

int dav2d_cdf_thread_alloc(Dav2dContext *const c, CdfThreadContext *const cdf,
                           const int have_frame_mt)
{
    cdf->ref = dav2d_ref_create_using_pool(c->cdf_pool,
                                           sizeof(CdfContext) + sizeof(atomic_uint));
    if (!cdf->ref) return DAV2D_ERR(ENOMEM);
    cdf->data.cdf = cdf->ref->data;
    if (have_frame_mt) {
        cdf->progress = (atomic_uint *) &cdf->data.cdf[1];
        atomic_init(cdf->progress, 0);
    }
    return 0;
}

void dav2d_cdf_thread_ref(CdfThreadContext *const dst,
                          CdfThreadContext *const src)
{
    *dst = *src;
    if (src->ref)
        dav2d_ref_inc(src->ref);
}

void dav2d_cdf_thread_unref(CdfThreadContext *const cdf) {
    memset(&cdf->data, 0, sizeof(*cdf) - offsetof(CdfThreadContext, data));
    dav2d_ref_dec(&cdf->ref);
}
