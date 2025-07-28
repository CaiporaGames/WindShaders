Shader "Custom/UltimateWindShaderShowcase"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)

        [Header(Wind Settings)]
        _WindDirection ("Wind Direction", Vector) = (1,0,0,0)
        _WindSpeed ("Wind Speed", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.1
        _WaveMode ("Wave Mode (0=xz,1=y,2=xyz)", Float) = 0

        [Header(Pole Anchoring)]
        _PolePosition ("Pole Position (0=Left, 1=Right, 2=Top, 3=Bottom)", Float) = 0
        _AnchorZone ("Anchor Zone Width", Range(0, 0.5)) = 0.05
        _AnchorFalloff ("Anchor Falloff", Range(0.01, 0.5)) = 0.1

        [Header(Effect Toggles)]
        [Toggle] _EnableFabricStretch ("1. Enable Fabric Stretch", Float) = 1
        [Toggle] _EnableNoiseVariation ("2. Enable Noise Variation", Float) = 1
        [Toggle] _EnableRimLighting ("3. Enable Rim Lighting", Float) = 1
        [Toggle] _EnableWindColorShift ("4. Enable Wind Color Shift", Float) = 1
        [Toggle] _EnableHoverGlow ("5. Enable Hover Emissive Glow", Float) = 1

        [Header(1. Fabric Stretch)]
        _StretchAmount ("Stretch Intensity", Range(0, 2)) = 0.3
        _StretchDirection ("Stretch Direction", Vector) = (1,0,0,0)

        [Header(2. Noise Variation)]
        _NoiseScale ("Noise Scale", Float) = 10
        _NoiseSpeed ("Noise Animation Speed", Float) = 1
        _NoiseIntensity ("Noise Intensity", Range(0, 1)) = 0.2

        [Header(3. Rim Lighting)]
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(0.1, 8)) = 2
        _RimIntensity ("Rim Intensity", Range(0, 3)) = 1

        [Header(4. Wind Color Shift)]
        _WindColorTint ("Wind Color Tint", Color) = (0.8,0.9,1,1)
        _WindColorIntensity ("Wind Color Strength", Range(0, 2)) = 0.5
        _WindAlphaEffect ("Wind Alpha Effect", Range(0, 1)) = 0.2

        [Header(5. Hover Emissive Glow)]
        _HoverGlowColor ("Hover Glow Color", Color) = (1,0.8,0.3,1)
        _HoverGlowIntensity ("Hover Glow Intensity", Range(0, 5)) = 2
        _HoverGlowSize ("Hover Glow Size Multiplier", Range(0.5, 3)) = 1.5

        [Header(Debug)]
        _ShowHoverArea ("Show Hover Debug", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ENABLEFABRICSTRETCH_ON
            #pragma shader_feature _ENABLENOISEVARIATION_ON
            #pragma shader_feature _ENABLERIMLIGHTING_ON
            #pragma shader_feature _ENABLEWINDCOLORSHIFT_ON
            #pragma shader_feature _ENABLEHOVERGLOW_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float hoverEffect : TEXCOORD4;
                float windStrength : TEXCOORD5;
                float anchorWeight : TEXCOORD6;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float4 _WindDirection;
                float _WindSpeed;
                float _WindStrength;
                float _WaveMode;
                float _PolePosition;
                float _AnchorZone;
                float _AnchorFalloff;
                float _StretchAmount;
                float4 _StretchDirection;
                float _NoiseScale;
                float _NoiseSpeed;
                float _NoiseIntensity;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
                float4 _WindColorTint;
                float _WindColorIntensity;
                float _WindAlphaEffect;
                float4 _HoverGlowColor;
                float _HoverGlowIntensity;
                float _HoverGlowSize;
                float _ShowHoverArea;
            CBUFFER_END

            float4 _HoverPosition;
            float _HoverStrength;
            float _HoverRadius;
            sampler2D _MainTex;

            float noise(float3 p) {
                return frac(sin(dot(p ,float3(12.9898,78.233, 45.164))) * 43758.5453);
            }

            float smoothNoise(float3 p) {
                float3 i = floor(p);
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                return lerp(
                    lerp(lerp(noise(i), noise(i + float3(1,0,0)), f.x),
                         lerp(noise(i + float3(0,1,0)), noise(i + float3(1,1,0)), f.x), f.y),
                    lerp(lerp(noise(i + float3(0,0,1)), noise(i + float3(1,0,1)), f.x),
                         lerp(noise(i + float3(0,1,1)), noise(i + float3(1,1,1)), f.x), f.y), f.z);
            }

            float CalculateAnchorWeight(float4 positionOS, float2 uv)
            {
                float distanceFromPole = 0;
                if (_PolePosition < 0.5) distanceFromPole = uv.x;
                else if (_PolePosition < 1.5) distanceFromPole = 1.0 - uv.x;
                else if (_PolePosition < 2.5) distanceFromPole = 1.0 - uv.y;
                else distanceFromPole = uv.y;
                return smoothstep(_AnchorZone, _AnchorZone + _AnchorFalloff, distanceFromPole);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 windOffset = float3(0, 0, 0);
                float3 hoverOffset = float3(0, 0, 0);
                float hoverEffect = 0;
                float anchorWeight = CalculateAnchorWeight(IN.positionOS, IN.uv);

                float wave = 0;
                if (_WaveMode < 0.5) wave = sin(dot(worldPos.xz, _WindDirection.xz) * 0.2 + _Time.y * _WindSpeed);
                else if (_WaveMode < 1.5) wave = sin(worldPos.y * 5 + _Time.y * _WindSpeed);
                else wave = sin((worldPos.x + worldPos.y + worldPos.z) * 0.4 + _Time.y * _WindSpeed);

                windOffset = float3(_WindDirection.x, 0, _WindDirection.z) * wave * _WindStrength * anchorWeight;

                #ifdef _ENABLEFABRICSTRETCH_ON
                float stretchWave = sin(_Time.y * _WindSpeed * 0.5 + worldPos.x * 0.1);
                windOffset += _StretchDirection.xyz * stretchWave * _StretchAmount * anchorWeight * 0.1;
                #endif

                #ifdef _ENABLENOISEVARIATION_ON
                float3 noisePos = worldPos * _NoiseScale + _Time.y * _NoiseSpeed;
                float noiseValue = smoothNoise(noisePos) * 2.0 - 1.0;
                float3 noiseOffset = float3(noiseValue * 0.08, noiseValue * 0.01, noiseValue * 0.04) * _NoiseIntensity * _WindStrength * anchorWeight;
                windOffset += noiseOffset;
                #endif

                float dist = distance(worldPos, _HoverPosition.xyz);
                if (_HoverPosition.x < 9000 && dist < _HoverRadius)
                {
                    hoverEffect = saturate(1.0 - dist / _HoverRadius);
                    float3 hoverDir = normalize(worldPos - _HoverPosition.xyz);
                    hoverOffset += hoverDir * hoverEffect * 0.5;
                    hoverOffset += float3(0, 1, 0) * hoverEffect * 0.3;
                    hoverOffset += float3(sin(hoverEffect * 3.14159), 0, cos(hoverEffect * 3.14159)) * hoverEffect * 0.2;
                    hoverOffset *= _HoverStrength * anchorWeight;
                }

                float3 finalPos = IN.positionOS.xyz + windOffset + hoverOffset;
                OUT.positionHCS = TransformObjectToHClip(finalPos);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.worldPos = TransformObjectToWorld(finalPos);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDir = normalize(_WorldSpaceCameraPos - OUT.worldPos);
                OUT.hoverEffect = hoverEffect;
                OUT.windStrength = abs(wave);
                OUT.anchorWeight = anchorWeight;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 baseColor = tex2D(_MainTex, IN.uv) * _Color;
                half3 finalColor = baseColor.rgb;
                half finalAlpha = baseColor.a;

                #ifdef _ENABLERIMLIGHTING_ON
                float rim = 1.0 - saturate(dot(normalize(IN.worldNormal), IN.viewDir));
                rim = pow(rim, _RimPower);
                finalColor += _RimColor.rgb * rim * _RimIntensity;
                #endif

                #ifdef _ENABLEWINDCOLORSHIFT_ON
                float windInfluence = IN.windStrength * IN.anchorWeight;
                finalColor = lerp(finalColor, finalColor * _WindColorTint.rgb, windInfluence * _WindColorIntensity);
                finalAlpha = lerp(finalAlpha, finalAlpha * (1.0 + windInfluence * _WindAlphaEffect), windInfluence);
                #endif

                #ifdef _ENABLEHOVERGLOW_ON
                if (IN.hoverEffect > 0.01)
                {
                    float glowRadius = IN.hoverEffect * _HoverGlowSize;
                    finalColor += _HoverGlowColor.rgb * glowRadius * _HoverGlowIntensity;
                }
                #endif

                if (_ShowHoverArea > 0.5 && IN.hoverEffect > 0.01)
                {
                    finalColor = lerp(finalColor, float3(1, 0, 0), 0.3);
                }

                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
    }
}