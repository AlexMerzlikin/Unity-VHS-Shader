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
        _StreakIntensity ("Streak Intensity", Range(0,2)) = 0.7
        _StreakWidth ("Streak Width", Range(0,0.2)) = 0.02
        _StreakSpeed ("Streak Speed", Range(0,2)) = 0.2
        _StreakColor ("Streak Color", Color) = (1,0.95,0.7,1)
        _StreakDistortion ("Streak Distortion", Range(0,0.2)) = 0.04
        _StreakCount ("Streak Count", Range(1,8)) = 4
        _StreakFullWidthChance ("Full Width Chance", Range(0,1)) = 0.08
        _DashStreakIntensity ("Dash Streak Intensity", Range(0,2)) = 1.0
        _DashStreakWidth ("Dash Streak Width", Range(0,0.05)) = 0.008
        _DashStreakCount ("Dash Streak Count", Range(1,8)) = 1
        _DashCount ("Dash Count", Range(2,12)) = 7
        _EnableStreaks ("Enable Streaks", Float) = 1
        _EnableDashes ("Enable Dashes", Float) = 1
        _DashStreakWidthMin ("Dash Streak Width Min", Range(0,0.05)) = 0.004
        _DashStreakWidthMax ("Dash Streak Width Max", Range(0,0.05)) = 0.018
        _WobbleIntensity ("Wobble Intensity", Range(0,5)) = 1
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
            float _StreakIntensity;
            float _StreakWidth;
            float _StreakSpeed;
            float4 _StreakColor;
            float _StreakDistortion;
            float _StreakCount;
            float _StreakFullWidthChance;
            float _DashStreakIntensity;
            float _DashStreakWidth;
            float _DashStreakCount;
            float _DashCount;
            float _EnableStreaks;
            float _EnableDashes;
            float _DashStreakWidthMin;
            float _DashStreakWidthMax;
            float _WobbleIntensity;

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
                // 5. Distortion/Wobble
                float base = sin(uv.y * _WobbleFrequency + _TimeParam * _WobbleSpeed);
                float spike = sign(sin(uv.y * (_WobbleFrequency * 3.7) + _TimeParam * (_WobbleSpeed * 2.2)));
                float highFreq = abs(sin(uv.y * (_WobbleFrequency * 7.1) + _TimeParam * (_WobbleSpeed * 4.3))) * 2.0 - 1.0;
                float noise = (rand(float2(uv.y * 40.0, _TimeParam * 4.0)) * 2.0 - 1.0);
                float jump = step(0.5, frac(sin(uv.y * 100.0 + _TimeParam * 20.0) * 43758.5453)) * 2.0 - 1.0;
                float abrupt = base * 0.2 + spike * 0.4 + highFreq * 0.2 + noise * 0.15 + jump * 0.25;
                abrupt *= _WobbleIntensity;
                float wobble = abrupt * _Distortion * 0.02;
                float2 uvWobble = uv + float2(wobble, 0);
                fixed4 col = tex2D(_MainTex, uvWobble);

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
                noise = (rand(uv * _TimeParam * 0.5 + _TimeParam) - 0.5) * _NoiseIntensity;
                col.rgb += noise;

                // 6. Improved Horizontal Glitch Streaks (multiple, short, rare full-width)
                if (_EnableStreaks > 0.5)
                {
                    float3 streakColorSum = float3(0, 0, 0);
                    float streakShapeSum = 0.0;
                    int streaks = (int)_StreakCount;
                    for (int s = 0; s < 8; s++)
                    {
                        if (s >= streaks) break;
                        float streakSeed = floor(_TimeParam * 60.0) + s * 13.37;
                        float yPos = frac(rand(float2(streakSeed, streakSeed * 1.37))) * 0.8 + 0.1;
                        float xStart = rand(float2(streakSeed, 0.123)) * 0.8;
                        float xLen = lerp(0.08, 0.5, rand(float2(streakSeed, 0.456)));
                        float fullWidth = step(1.0 - _StreakFullWidthChance, rand(float2(streakSeed, 0.789)));
                        xStart = lerp(xStart, 0.0, fullWidth);
                        xLen = lerp(xLen, 1.0, fullWidth);
                        float inX = step(xStart, uv.x) * step(uv.x, xStart + xLen);
                        float streakCore = step(abs(uv.y - yPos), _StreakWidth * 0.3);
                        float streakEdge = smoothstep(_StreakWidth, 0.0, abs(uv.y - yPos));
                        float streakShape = max(streakCore, streakEdge * 0.7) * inX;
                        float flicker = lerp(0.7, 1.0, rand(float2(_TimeParam * 10.0, streakSeed))) * (0.7 + 0.3 * sin(
                            _TimeParam * 360.0 + streakSeed * 10.0));
                        float streak = streakShape * flicker * _StreakIntensity;
                        float3 thisStreakColor = _StreakColor.rgb * streak;
                        streakColorSum += thisStreakColor;
                        streakShapeSum = max(streakShapeSum, streakShape);
                    }
                    float streakDistort = streakShapeSum * _StreakDistortion * (rand(float2(uv.y, _TimeParam)) - 0.5);
                    float2 uvStreaked = uv + float2(streakDistort, 0);
                    col.rgb = lerp(col.rgb, tex2D(_MainTex, uvStreaked).rgb, streakShapeSum * 0.5);
                    col.rgb += streakColorSum;
                }

                // 7. Segmented/Dashed Horizontal Streak (VHS dropout)
                if (_EnableDashes > 0.5)
                {
                    for (int dStreak = 0; dStreak < 4; dStreak++)
                    {
                        if (dStreak >= (int)_DashStreakCount) break;
                        float dashSeed = floor(_TimeParam * 60.0) + 100.0 + dStreak * 17.17;
                        float dashY = frac(rand(float2(dashSeed, dashSeed * 1.37))) * 0.8 + 0.1;
                        float dashWidth = lerp(_DashStreakWidthMin, _DashStreakWidthMax, rand(float2(dashSeed, 0.555)));
                        float dashCore = step(abs(uv.y - dashY), dashWidth * 0.5);
                        float dashEdge = smoothstep(dashWidth, 0.0, abs(uv.y - dashY));
                        float dashShape = max(dashCore, dashEdge * 0.7);
                        for (int seg = 0; seg < 12; seg++)
                        {
                            if (seg >= (int)_DashCount) break;
                            float segSeed = dashSeed + seg * 23.23;
                            float xStart = rand(float2(segSeed, 0.321));
                            float xLen = lerp(0.02, 0.18, rand(float2(segSeed, 0.654)));
                            float inDash = step(xStart, uv.x) * step(uv.x, xStart + xLen);
                            if (inDash > 0.0)
                            {
                                int subDashCount = 4 + (int)(rand(float2(segSeed, 0.999)) * 3); // 4-6 sub-dashes
                                for (int sub = 0; sub < 8; sub++)
                                {
                                    if (sub >= subDashCount) break;
                                    float subSeed = segSeed + sub * 7.77;
                                    float subStart = xStart + rand(float2(subSeed, 0.111)) * (xLen - 0.01);
                                    float subLen = lerp(0.005, 0.04, rand(float2(subSeed, 0.222)));
                                    float inSubDash = step(subStart, uv.x) * step(uv.x, subStart + subLen);
                                    float3 subColor = lerp(float3(1, 1, 0.95), float3(0.8, 0.9, 1.1), rand(float2(subSeed, 0.888)));
                                    subColor = lerp(subColor, float3(1, 0.98, 0.8), rand(float2(subSeed, 0.444)) * 0.5);
                                    float subBrightness = lerp(0.7, 1.2, rand(float2(subSeed, 0.333)));
                                    float subFlicker = 0.8 + 0.2 * rand(float2(_TimeParam * 100.0, subSeed));
                                    float subFinal = dashShape * inSubDash * subFlicker * _DashStreakIntensity * subBrightness;
                                    col.rgb += subColor * subFinal;
                                }
                            }
                        }
                    }
                }

                return col;
            }
            ENDCG
        }
    }
}