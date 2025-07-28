Shader "Custom/StylizedWindShaderWithPoleAnchor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindDirection ("Wind Direction", Vector) = (1,0,0,0)
        _WindSpeed ("Wind Speed", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.1
        _WaveMode ("Wave Mode (0=xz,1=y,2=xyz)", Float) = 0

        [Header(Pole Anchoring)]
        _PolePosition ("Pole Position (0=Left, 1=Right, 2=Top, 3=Bottom)", Float) = 0
        _AnchorZone ("Anchor Zone Width", Range(0, 0.5)) = 0.05
        _AnchorFalloff ("Anchor Falloff (how gradual)", Range(0.01, 0.5)) = 0.1

        [Header(Hover Effect)]
        _ShowHoverArea ("Show Hover Area", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float hoverEffect : TEXCOORD2;
                float anchorWeight : TEXCOORD3; // Debug: show anchor influence
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _WindDirection;
                float _WindSpeed;
                float _WindStrength;
                float _WaveMode;
                float _PolePosition;
                float _AnchorZone;
                float _AnchorFalloff;
                float _ShowHoverArea;
            CBUFFER_END

            float4 _HoverPosition;
            float _HoverStrength;
            float _HoverRadius;

            sampler2D _MainTex;

            // Calculate how much a vertex should be anchored (0 = fully anchored, 1 = fully free)
            float CalculateAnchorWeight(float4 positionOS, float2 uv)
            {
                float distanceFromPole = 0;
                
                if (_PolePosition < 0.5) // Left pole
                {
                    // Use UV coordinates for more reliable anchoring
                    distanceFromPole = uv.x; // 0 at left edge, 1 at right edge
                }
                else if (_PolePosition < 1.5) // Right pole  
                {
                    distanceFromPole = 1.0 - uv.x; // 1 at left edge, 0 at right edge
                }
                else if (_PolePosition < 2.5) // Top pole
                {
                    distanceFromPole = 1.0 - uv.y; // 1 at bottom, 0 at top
                }
                else // Bottom pole
                {
                    distanceFromPole = uv.y; // 0 at bottom, 1 at top
                }
                
                // Create smooth transition from anchor zone
                float anchorInfluence = smoothstep(_AnchorZone, _AnchorZone + _AnchorFalloff, distanceFromPole);
                return anchorInfluence; // 0 = anchored, 1 = free to move
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 windDir = float3(0, 0, 0);
                float3 hoverDir = float3(0, 0, 0);
                float hoverEffect = 0;

                // Calculate anchor weight (how free this vertex is to move)
                float anchorWeight = CalculateAnchorWeight(IN.positionOS, IN.uv);

                // ==== WIND EFFECTS ====
                float wave = 0;
                if (_WaveMode < 0.5) // XZ plane wave
                {
                    wave = sin(dot(worldPos.xz, _WindDirection.xz) * 0.2 + _Time.y * _WindSpeed);
                    windDir = float3(_WindDirection.x * wave, 0, _WindDirection.z * wave);
                }
                else if (_WaveMode < 1.5) // Y-based wave
                {
                    wave = sin(worldPos.y * 5 + _Time.y * _WindSpeed);
                    windDir = float3(wave, 0, 0);
                }
                else // XYZ combined wave
                {
                    wave = sin((worldPos.x + worldPos.y + worldPos.z) * 0.4 + _Time.y * _WindSpeed);
                    windDir = float3(0.3, 0, 1) * wave;
                }

                // Apply wind with anchor weight
                float3 windOffset = windDir * _WindStrength * anchorWeight;

                // ==== HOVER EFFECTS ====
                float dist = distance(worldPos, _HoverPosition.xyz);
                if (_HoverPosition.x < 9000 && dist < _HoverRadius)
                {
                    hoverEffect = saturate(1.0 - dist / _HoverRadius);
                    float3 dir = normalize(worldPos - _HoverPosition.xyz);

                    // Multiple hover effects
                    hoverDir += dir * hoverEffect * 0.5;
                    hoverDir += float3(0, 1, 0) * hoverEffect * 0.3;
                    hoverDir += float3(sin(hoverEffect * 3.14159), 0, cos(hoverEffect * 3.14159)) * hoverEffect * 0.2;
                }

                // Apply hover with anchor weight
                float3 hoverOffset = hoverDir * _HoverStrength * anchorWeight;

                // ==== FINAL POSITION ====
                float3 finalPos = IN.positionOS.xyz + windOffset + hoverOffset;

                OUT.positionHCS = TransformObjectToHClip(finalPos);
                OUT.uv = IN.uv;
                OUT.worldPos = worldPos;
                OUT.hoverEffect = hoverEffect;
                OUT.anchorWeight = anchorWeight; // For debugging
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 baseColor = tex2D(_MainTex, IN.uv);

                // Show hover area
                if (_ShowHoverArea > 0.5 && IN.hoverEffect > 0.01)
                {
                    baseColor = lerp(baseColor, half4(0, 1, 0, 1), IN.hoverEffect * 0.3);
                }
                return baseColor;
            }

            ENDHLSL
        }
    }
}