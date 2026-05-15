# Copyright © 2018, VideoLAN and dav2d authors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Leave subdir if tests are disabled
if not get_option('enable_tests')
    subdir_done()
endif

# add a test setup for sanitizer builds to increase timeouts
add_test_setup('sanitizer',
               timeout_multiplier: 3)

# include aom test vectors
if not get_option('enable_tools')
    subdir_done()
endif

dav2d_test_args = ['-q', '--threads', '1', '--filmgrain=1']

tests = [
    'avm-v15.0.0-bus.352x288.l10.deltaq1.obu',
    'avm-v15.0.0-bus.352x288.l1.partial_lossless.obu',
    'avm-v15.0.0-bus.352x288.l5.seg1.obu',
    'avm-v15.0.0-bus.64x64.l1.sdp0.obu',
    'avm-v15.0.0-bus.64x64.l1.sdp1.obu',
    'avm-v15.0.0-bus.64x64.l5.lossless.obu',
    'avm-v15.0.0-bus.64x64.l5.obu',
    'avm-v15.0.0-bus.64x64.l5.opfl0-refinemv0.obu',
    'avm-v15.0.0-hm.64x64.l5.filmgrain.obu',
]

fs = import('fs')

foreach test : tests
    test(test, dav2d, suite: ['media'],
         args: dav2d_test_args + ['-i', files(test), '--verify', fs.read(files(test + '.md5')).strip()])
endforeach
