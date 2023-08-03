Shader "Custom/RaymarchImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxDistance ("Max Distance", Range(0, 100)) = 10
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
                return length(p) - 0.3;
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
                for (int i = 0; i < 100; i++)
                {
                    float dist = sdf(p);
                    t += dist;
                    p = rayOrigin + rayDirection * t;
                    if (dist < 0.001 || t > maxT)
                    {
                        break;
                    }
                }

                if (t > maxT){
                    return float4(0, 0, 0, 1);
                }
                else{
                    return float4(1, 1, 1, 1);
                }
            }
            ENDCG
        }
    }
    //FallBack "Diffuse"
}