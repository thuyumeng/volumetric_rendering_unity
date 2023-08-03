Shader "Custom/RaymarchImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxDistance ("Max Distance", Range(0, 100)) = 10
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

            float _MaxDistance;
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float sdf(float3 p)
            {
                // Signed Distance Function for a sphere
                return length(p) - 0.5;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                // Raymarch

                // set a virtual camera at (0, 0, -5) looking at the screen
                float3 rayOrigin = float3(0, 0, -5);
                // calculate the pixel position in the virtual world space
                float2 pixelPos = i.uv * 2 - 1;
                // apply the aspect ratio
                pixelPos.x *= _ScreenParams.x / _ScreenParams.y;
                float3 virtualPos = float3(pixelPos, 0);
                // calculate the ray direction
                float3 rayDirection = normalize(virtualPos - rayOrigin);

                float t = 0;
                float maxT = _MaxDistance;
                float3 p = rayOrigin;

                float4 back_ground = _Background;
                
                // calculate the absorption effect of the volumetric fog
                float absorption_T = 1.0;
                float sigma_a = _Sigma_a;

                float march_step = 0.01;
                for (int i = 0; i < 100; i++)
                {
                    // first step use the sdf to accelerate the raymarch
                    if (t < 0.001)
                    {
                        float dist = sdf(p);
                        t += dist;
                    }
                    else
                    {
                        t += march_step;
                    }

                    p = rayOrigin + rayDirection * t;
                    float dist = sdf(p);
                    if (dist < 0.001)
                    {
                        // calculate the absorption effect of the volumetric fog
                        absorption_T *= exp(-sigma_a * march_step);
                    }
                    if (t > maxT)
                    {
                        break;
                    }
                }

                // calculate the final color
                float4 color = back_ground * absorption_T;
                return fixed4(color.rgb, 1.0);
            }
            ENDCG
        }
    }
    //FallBack "Diffuse"
}