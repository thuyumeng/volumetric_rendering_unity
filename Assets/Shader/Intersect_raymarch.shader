Shader "RayMarching/IntersectSphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Background ("Background", Color) = (0.529, 0.808, 0.922, 1.0)
        _Sigma_a ("Sigma_a", Range(0, 8)) = 5
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            float4 _Background;
            float _Sigma_a;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // the function to intersect the sphere with the ray and return t0 and t1 which are the distances from the ray origin to the intersection points
            // if there is no intersection return -1 else return 1
            float intersectSphere(float3 rayOrigin, float3 rayDirection, float3 sphereCenter, float sphereRadius, out float t0, out float t1)
            {
                float3 L = sphereCenter - rayOrigin;
                float tca = dot(L, rayDirection);
                float d2 = dot(L, L) - tca * tca;
                if (d2 > sphereRadius * sphereRadius) return -1.0;
                float thc = sqrt(sphereRadius * sphereRadius - d2);
                t0 = tca - thc;
                t1 = tca + thc;
                return 1.0;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                // set a virtual camera at (0, 0, -5) looking at the screen
                float3 rayOrigin = float3(0, 0, -5);
                // calculate the pixel position in the virtual world space
                float2 pixelPos = i.uv * 2 - 1;
                // apply the aspect ratio
                pixelPos.x *= _ScreenParams.x / _ScreenParams.y;
                float3 virtualPos = float3(pixelPos, 0);
                // calculate the ray direction
                float3 rayDirection = normalize(virtualPos - rayOrigin);
                // set the sphere center and radius
                float3 sphereCenter = float3(0, 0, 0);
                float sphereRadius = 0.3;

                float4 back_ground = _Background;
                float sigma_a = _Sigma_a;
                // calculate the intersection points
                float t0, t1;
                float intersect = intersectSphere(rayOrigin, rayDirection, sphereCenter, sphereRadius, t0, t1);
                if (intersect == -1.0) return back_ground;
                float absorption_T = exp(-sigma_a * (t1 - t0));
                return back_ground * absorption_T;
            }
            ENDCG
        }
    }
}
