//
// Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of NVIDIA CORPORATION nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#include <optix.h>

#include "optixNDRangeSearch.h"
#include "random.h"
#include "helpers.h"

extern "C" {
__constant__ Params params;
}

extern "C" __device__ void intersect_sphere()
{
    // This is called when a ray-bbox intersection is found, but we still can't
    // be sure that the point is within the sphere. It's possible that the
    // point is within the bbox but no within the sphere, and it's also
    // possible that the point is just outside of the bbox and just intersects
    // with the bbox. Note that it's wasteful to do a ray-sphere intersection
    // test and use the intersected Ts to decide whethere a point is inside the
    // sphere or not
    // (https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection).

    unsigned int primIdx = optixGetPrimitiveIndex();
    const float3 center = params.points[1][primIdx];

    const float3  ray_orig = optixGetWorldRayOrigin();

    float3 O = ray_orig - center;

    if (dot(O, O) < params.radius * params.radius) {
      //unsigned int id = optixGetPayload_1();
      //optixSetPayload_1( id+1 );

      unsigned int id = optixGetPayload_1();
      if (id < params.knn) {
        unsigned int rayIdx = optixGetPayload_0();
        unsigned int primIdx = optixGetPrimitiveIndex();
        params.frame_buffer[rayIdx * params.knn + id] = primIdx;
        if (id + 1 == params.knn)
          optixReportIntersection( 0, 0 );
        else optixSetPayload_1( id+1 );
      }
    }
}

extern "C" __global__ void __intersection__sphere()
{
  // The IS program will be called if the ray origin is within a primitive's
  // bbox (even if the actual intersections are beyond the tmin and tmax).

  bool isApprox = false;

  if (isApprox) {
    unsigned int id = optixGetPayload_1();
    if (id < params.knn) {
      unsigned int rayIdx = optixGetPayload_0();
      unsigned int primIdx = optixGetPrimitiveIndex();
      params.frame_buffer[rayIdx * params.knn + id] = primIdx;
      if (id + 1 == params.knn)
        optixReportIntersection( 0, 0 );
      else optixSetPayload_1( id+1 );
    }
  } else {
    intersect_sphere();
  }
}

extern "C" __global__ void __anyhit__terminateRay()
{
  optixTerminateRay();
}
