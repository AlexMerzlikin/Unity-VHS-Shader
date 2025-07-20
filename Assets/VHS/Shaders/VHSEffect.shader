Shader "Custom/VHSEffect"
{
    Properties
    {
        _MainTex ("Render Texture", 2D) = "white" {}
        _ScanlineIntensity ("Scanline Intensity", Range(0,4)) = 0.5
        _NoiseIntensity ("Noise Intensity", Range(0,2)) = 0.2
        _ColorBleed ("Color Bleed", Range(0,10)) = 0.02
        _Distortion ("Distortion", Range(0,10)) = 0.05
        _WobbleFrequency ("Wobble Frequency", Range(0,110)) = 40
        _WobbleSpeed ("Wobble Speed", Range(0,20)) = 1
        _TimeParam ("Time", Float) = 0
        _ScanlineCount ("Scanline Count", Float) = 300.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _ScanlineIntensity;
            float _NoiseIntensity;
            float _ColorBleed;
            float _Distortion;
            float _WobbleFrequency;
            float _WobbleSpeed;
            float _TimeParam;
            float _ScanlineCount;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                fixed4 col = tex2D(_MainTex, uv);

                // 1. Scanlines
                float scanline = sin(uv.y * _ScanlineCount * 3.14159);
                float scanlineMask = lerp(1.0, 0.7, (scanline * 0.5 + 0.5) * _ScanlineIntensity);
                col.rgb *= scanlineMask;

                // 2. Basic Color Grading (slight desaturation and blue tint)
                float gray = dot(col.rgb, float3(0.3, 0.59, 0.11));
                col.rgb = lerp(col.rgb, float3(gray, gray, gray), 0.15); // Slight desaturation
                col.rgb = lerp(col.rgb, float3(0.9, 0.95, 1.1), 0.08); // Subtle blue tint

                // 3. Color Bleed/Chromatic Aberration
                float brightness = dot(col.rgb, float3(0.3, 0.59, 0.11));
                float blendAmount = _ColorBleed * smoothstep(0.05, 0.2, brightness);
                float2 offset = float2(_ColorBleed / _ScreenParams.x, 0);
                float r = tex2D(_MainTex, uv + offset).r;
                float g = col.g;
                float b = tex2D(_MainTex, uv - offset).b;
                float3 aberrated = float3(r, g, b);
                col.rgb = lerp(col.rgb, aberrated, blendAmount);

                // 4. Noise/Static
                float noise = (rand(uv * _TimeParam * 0.5 + _TimeParam) - 0.5) * _NoiseIntensity;
                col.rgb += noise;

                // 5. Distortion/Wobble
                float wobble = sin(uv.y * _WobbleFrequency + _TimeParam * _WobbleSpeed) * _Distortion * 0.02;
                float2 distortedUV = uv + float2(wobble, 0);
                col.rgb = lerp(col.rgb, tex2D(_MainTex, distortedUV).rgb, _Distortion);

                return col;
            }
            ENDCG
        }
    }
}
