Shader "RayMarching/IntersectSphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Background ("Background", Color) = (0.529, 0.808, 0.922, 1.0)
        _DirectLightColor ("Direct Light Color", Color) = (1.0, 0.412, 0.706, 1.0)
        _DirectLightDirection ("Direct Light Direction", Vector) = (1.0, 0.0, 0.0)
        _Sigma_a ("Sigma_a", Range(0, 8)) = 5  // the absorption coefficient
        _Sigma_s ("Sigma_s", Range(0, 8)) = 5  // the scattering coefficient
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
            float4 _DirectLightColor;
            float3 _DirectLightDirection;
            float _Sigma_a;
            float _Sigma_s;

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

                // calculate the intersection points
                float t0, t1;
                float intersect = intersectSphere(rayOrigin, rayDirection, sphereCenter, sphereRadius, t0, t1);
                if (intersect == -1.0) return _Background;

                // raymarching from back to front
                float absorption_T = 1.0;
                float step = 0.01;

                float cur_march_length = 0.0;
                float max_march_length = t1 - t0;
                
                // the radiosity at the current position
                float4 cur_radiosity = _Background;
                float sigma_a = _Sigma_a;
                float sigma_s = _Sigma_s;
                float sigma_t = sigma_a + sigma_s;

                // the phase function
                float ph = 1.0 / (4.0 * 3.1415926);
                
                float3 light_direction = normalize(_DirectLightDirection);

                while (cur_march_length <= max_march_length)
                {
                    // calculate the current position
                    float3 cur_pos = rayOrigin + rayDirection * (t0 + cur_march_length);
                    // calculate the radiosity at the current position because of the attenuation of absorption and outscattering
                    cur_radiosity *= exp(-sigma_t * step);
                    // calculate the radiosity at the current position because of the in-scattering of the light

                    // calcuate the intersection points that the ray from the current position to the light source intersects with the sphere
                    float t0_light, t1_light;
                    float intersect_light = intersectSphere(cur_pos, -1.0 * light_direction, sphereCenter, sphereRadius, t0_light, t1_light);
                    
                    if (intersect_light == -1.0)
                    {
                        cur_march_length += step;
                        continue;
                    }

                    float travel_distance = t0_light;
                    if (travel_distance < 0.0)
                    {
                        travel_distance = t1_light;
                    }
                    cur_radiosity += _DirectLightColor * exp(-sigma_t * travel_distance) * ph;

                    cur_march_length += step;
                }
                
                return fixed4(cur_radiosity.rgb, 1.0);
            }
            ENDCG
        }
    }
}
